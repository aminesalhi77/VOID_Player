#include "library/Library.h"
#include "metadata/TagReader.h"

#include <QDirIterator>
#include <QFileInfo>
#include <QDebug>
#include <QFileDialog>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QUrl>
#include <QDir>
#include <QSqlDatabase>
#include <QSqlError>

Library::Library(QObject* parent) : QObject(parent) {
    // Open (or create) the SQLite library database
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    const QString dbPath = dataDir + "/library.db";
    if (m_db.open(dbPath)) {
        qDebug() << "VOID: DB opened at" << dbPath;
    } else {
        qWarning() << "VOID: failed to open DB — persistence disabled";
    }
}

void Library::clear() {
    m_tracks.clear();
    m_seenPaths.clear();
    m_db.clear();
    emit tracksChanged();
}

void Library::loadFromDb() {
    if (m_db.count() == 0) {
        qDebug() << "VOID: DB is empty, nothing to load";
        return;
    }
    m_tracks = m_db.loadAll();
    for (const Track& t : m_tracks) {
        m_seenPaths.insert(t.filePath);
    }
    emit tracksChanged();
    qDebug() << "VOID: loaded" << m_tracks.size() << "tracks from DB";
}

void Library::scanFolder(const QString& folderPath) {
    QString cleanPath = folderPath;
    if (cleanPath.startsWith("file://")) {
        cleanPath = QUrl(cleanPath).toLocalFile();
    }
    while (cleanPath.endsWith('/') && cleanPath.length() > 1) {
        cleanPath.chop(1);
    }

    qDebug() << "VOID: scanFolder called with:" << cleanPath;

    if (!QDir(cleanPath).exists()) {
        qWarning() << "VOID: folder does NOT exist:" << cleanPath;
        emit errorMessage("Folder not found: " + cleanPath);
        return;
    }

    m_scanning = true;
    m_scanCurrent = 0;
    m_scanTotal = 0;
    emit scanningChanged();
    emit scanStarted();
    QCoreApplication::processEvents();

    QStringList files;
    QDirIterator it(cleanPath, QDir::Files | QDir::NoDotAndDotDot,
                    QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString path = it.next();
        if (TagReader::isSupported(path)) files.append(path);
    }

    qDebug() << "VOID: found" << files.size() << "audio files";

    m_scanTotal = files.size();
    emit scanProgressChanged();
    emit scanProgress(0, m_scanTotal);
    QCoreApplication::processEvents();

    int added = 0;
    int skipped = 0;

    for (const QString& path : files) {
        // ← Skip if already in library
        if (m_seenPaths.contains(path)) {
            ++skipped;
        } else {
            Track t = TagReader::read(path);
            if (t.isValid()) {
                m_tracks.append(t);
                m_seenPaths.insert(path);
                m_db.upsert(t);      // persist to SQLite
                ++added;
            }
        }

        ++m_scanCurrent;
        if (m_scanCurrent % 5 == 0 || m_scanCurrent == m_scanTotal) {
            emit scanProgressChanged();
            emit scanProgress(m_scanCurrent, m_scanTotal);
            QCoreApplication::processEvents();
        }
    }

    // Prune tracks whose files no longer exist
    QList<Track> keep;
    int pruned = 0;
    for (const Track& t : m_tracks) {
        if (QFileInfo::exists(t.filePath)) {
            keep.append(t);
        } else {
            m_db.remove(t.filePath);
            m_seenPaths.remove(t.filePath);
            ++pruned;
        }
    }
    m_tracks = keep;

    m_scanning = false;
    emit scanningChanged();
    emit tracksChanged();
    emit scanFinished(m_scanTotal);
    qDebug() << "VOID: scan done —" << added << "added,"
             << skipped << "skipped,"
             << pruned << "pruned";
}

void Library::pickFolderAndScan() {
    const QString startDir = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    qDebug() << "VOID: opening folder picker at:" << startDir;

    const QString dir = QFileDialog::getExistingDirectory(
        nullptr,
        tr("Choose your music folder"),
        startDir,
        QFileDialog::ShowDirsOnly
            | QFileDialog::DontResolveSymlinks
            | QFileDialog::DontUseNativeDialog      // ← ADD THIS
    );

    qDebug() << "VOID: picker returned:" << dir;

    if (dir.isEmpty()) {
        emit errorMessage("No folder chosen.");
        return;
    }
    scanFolder(dir);
}

void Library::scanDefaultMusicFolder() {
    const QString musicDir = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    qDebug() << "VOID: default music folder is:" << musicDir;

    if (musicDir.isEmpty()) {
        emit errorMessage("No Music folder found in your home directory.");
        return;
    }
    if (!QDir(musicDir).exists()) {
        emit errorMessage("Music folder doesn't exist: " + musicDir);
        return;
    }
    scanFolder(musicDir);
}

// ---- Custom lyrics ----

bool Library::saveCustomLyrics(const QString& filePath, const QString& content, bool isSynced) {
    return m_db.saveLyrics(filePath, content, isSynced);
}

QString Library::loadCustomLyrics(const QString& filePath) const {
    return m_db.loadLyrics(filePath, nullptr);
}

bool Library::customLyricsSynced(const QString& filePath) const {
    bool synced = false;
    m_db.loadLyrics(filePath, &synced);
    return synced;
}

bool Library::hasCustomLyrics(const QString& filePath) const {
    return m_db.hasLyrics(filePath);
}

bool Library::removeCustomLyrics(const QString& filePath) {
    return m_db.removeLyrics(filePath);
}

// ---- Auto-fetched lyrics cache ----

bool Library::saveCachedLyrics(const QString& filePath, const QString& content,
                              bool isSynced, const QString& source) {
    bool ok = m_db.saveCachedLyrics(filePath, content, isSynced, source);
    qDebug() << "VOID: saveCachedLyrics" << (ok ? "OK" : "FAILED")
             << "path:" << filePath << "synced:" << isSynced << "source:" << source;
    return ok;
}

QString Library::loadCachedLyrics(const QString& filePath) {
    return m_db.loadCachedLyrics(filePath, nullptr, nullptr);
}

bool Library::cachedLyricsSynced(const QString& filePath) const {
    bool synced = false;
    m_db.loadCachedLyrics(filePath, &synced, nullptr);
    return synced;
}

QString Library::cachedLyricsSource(const QString& filePath) const {
    QString source;
    m_db.loadCachedLyrics(filePath, nullptr, &source);
    return source;
}

bool Library::hasCachedLyrics(const QString& filePath) const {
    return m_db.hasCachedLyrics(filePath);
}
