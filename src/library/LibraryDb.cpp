#include "library/LibraryDb.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QVariant>
#include <QDateTime>

LibraryDb::LibraryDb()
    : m_connectionName("void_library")
{
}

LibraryDb::~LibraryDb() {
    close();
}

bool LibraryDb::open(const QString& dbPath) {
    if (QSqlDatabase::contains(m_connectionName)) {
        m_db = QSqlDatabase::database(m_connectionName);
    } else {
        m_db = QSqlDatabase::addDatabase("QSQLITE", m_connectionName);
        m_db.setDatabaseName(dbPath);
    }

    if (!m_db.open()) {
        qWarning() << "VOID: failed to open DB:" << m_db.lastError().text();
        return false;
    }

    return createSchema();
}

void LibraryDb::close() {
    if (m_db.isOpen()) m_db.close();
}

bool LibraryDb::createSchema() {
    QSqlQuery q(m_db);
    bool ok = q.exec(
        "CREATE TABLE IF NOT EXISTS tracks ("
        "  path         TEXT PRIMARY KEY,"
        "  title        TEXT,"
        "  artist       TEXT,"
        "  album        TEXT,"
        "  genre        TEXT,"
        "  year         INTEGER,"
        "  track_number INTEGER,"
        "  duration_ms  INTEGER,"
        "  cover_path   TEXT"
        ")"
    );
    if (!ok) return false;

    if (!ok) return false;

    if (!q.exec(
        "CREATE TABLE IF NOT EXISTS lyrics_cache ("
        "  file_path  TEXT PRIMARY KEY,"
        "  content    TEXT NOT NULL,"
        "  is_synced  INTEGER DEFAULT 0,"
        "  source     TEXT,"
        "  cached_at  INTEGER"
        ")"
    )) return false;

    return q.exec(
        "CREATE TABLE IF NOT EXISTS custom_lyrics ("
        "  file_path  TEXT PRIMARY KEY,"
        "  content    TEXT NOT NULL,"
        "  is_synced  INTEGER DEFAULT 0,"
        "  added_at   INTEGER"
        ")"
    );
}

QList<Track> LibraryDb::loadAll() const {
    QList<Track> tracks;
    QSqlQuery q(m_db);
    if (!q.exec("SELECT path, title, artist, album, genre, year, "
                "track_number, duration_ms, cover_path FROM tracks")) {
        return tracks;
    }
    while (q.next()) {
        Track t;
        t.filePath    = q.value(0).toString();
        t.title       = q.value(1).toString();
        t.artist      = q.value(2).toString();
        t.album       = q.value(3).toString();
        t.genre       = q.value(4).toString();
        t.year        = q.value(5).toInt();
        t.trackNumber = q.value(6).toInt();
        t.durationMs  = q.value(7).toInt();
        t.coverPath   = q.value(8).toString();
        tracks.append(t);
    }
    return tracks;
}

bool LibraryDb::upsert(const Track& t) {
    QSqlQuery q(m_db);
    q.prepare(
        "INSERT OR REPLACE INTO tracks "
        "(path, title, artist, album, genre, year, track_number, duration_ms, cover_path) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
    );
    q.addBindValue(t.filePath);
    q.addBindValue(t.title);
    q.addBindValue(t.artist);
    q.addBindValue(t.album);
    q.addBindValue(t.genre);
    q.addBindValue(t.year);
    q.addBindValue(t.trackNumber);
    q.addBindValue(t.durationMs);
    q.addBindValue(t.coverPath);
    return q.exec();
}

bool LibraryDb::remove(const QString& path) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM tracks WHERE path = ?");
    q.addBindValue(path);
    return q.exec();
}

bool LibraryDb::exists(const QString& path) const {
    QSqlQuery q(m_db);
    q.prepare("SELECT 1 FROM tracks WHERE path = ? LIMIT 1");
    q.addBindValue(path);
    return q.exec() && q.next();
}

int LibraryDb::count() const {
    QSqlQuery q(m_db);
    if (!q.exec("SELECT COUNT(*) FROM tracks") || !q.next()) return 0;
    return q.value(0).toInt();
}

void LibraryDb::clear() {
    QSqlQuery q(m_db);
    q.exec("DELETE FROM tracks");
}

// ============================================================
//  Custom lyrics storage
// ============================================================

bool LibraryDb::saveLyrics(const QString& filePath, const QString& content, bool isSynced) {
    QSqlQuery q(m_db);
    q.prepare(
        "INSERT OR REPLACE INTO custom_lyrics "
        "(file_path, content, is_synced, added_at) "
        "VALUES (?, ?, ?, ?)"
    );
    q.addBindValue(filePath);
    q.addBindValue(content);
    q.addBindValue(isSynced ? 1 : 0);
    q.addBindValue(QDateTime::currentSecsSinceEpoch());
    return q.exec();
}

QString LibraryDb::loadLyrics(const QString& filePath, bool* isSynced) const {
    QSqlQuery q(m_db);
    q.prepare("SELECT content, is_synced FROM custom_lyrics WHERE file_path = ? LIMIT 1");
    q.addBindValue(filePath);
    if (!q.exec() || !q.next()) {
        if (isSynced) *isSynced = false;
        return {};
    }
    if (isSynced) *isSynced = (q.value(1).toInt() != 0);
    return q.value(0).toString();
}

bool LibraryDb::hasLyrics(const QString& filePath) const {
    QSqlQuery q(m_db);
    q.prepare("SELECT 1 FROM custom_lyrics WHERE file_path = ? LIMIT 1");
    q.addBindValue(filePath);
    return q.exec() && q.next();
}

bool LibraryDb::removeLyrics(const QString& filePath) {
    QSqlQuery q(m_db);
    q.prepare("DELETE FROM custom_lyrics WHERE file_path = ?");
    q.addBindValue(filePath);
    return q.exec();
}

int LibraryDb::lyricsCount() const {
    QSqlQuery q(m_db);
    if (!q.exec("SELECT COUNT(*) FROM custom_lyrics") || !q.next()) return 0;
    return q.value(0).toInt();
}

// ---- Auto-fetched lyrics cache ----

bool LibraryDb::saveCachedLyrics(const QString& filePath, const QString& content,
                                 bool isSynced, const QString& source) {
    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO lyrics_cache "
              "(file_path, content, is_synced, source, cached_at) VALUES (?, ?, ?, ?, ?)");
    q.addBindValue(filePath);
    q.addBindValue(content);
    q.addBindValue(isSynced ? 1 : 0);
    q.addBindValue(source);
    q.addBindValue(QDateTime::currentSecsSinceEpoch());
    return q.exec();
}

QString LibraryDb::loadCachedLyrics(const QString& filePath, bool* isSynced,
                                    QString* source) const {
    QSqlQuery q(m_db);
    q.prepare("SELECT content, is_synced, source FROM lyrics_cache WHERE file_path = ? LIMIT 1");
    q.addBindValue(filePath);
    if (!q.exec() || !q.next()) {
        if (isSynced) *isSynced = false;
        if (source) *source = "";
        return {};
    }
    if (isSynced) *isSynced = (q.value(1).toInt() != 0);
    if (source) *source = q.value(2).toString();
    return q.value(0).toString();
}

bool LibraryDb::hasCachedLyrics(const QString& filePath) const {
    QSqlQuery q(m_db);
    q.prepare("SELECT 1 FROM lyrics_cache WHERE file_path = ? LIMIT 1");
    q.addBindValue(filePath);
    return q.exec() && q.next();
}
