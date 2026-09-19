#pragma once

#include <QObject>
#include <QList>
#include <QString>
#include <QSet>
#include "library/Track.h"
#include "library/LibraryDb.h"

class Library : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(int scanCurrent READ scanCurrent NOTIFY scanProgressChanged)
    Q_PROPERTY(int scanTotal READ scanTotal NOTIFY scanProgressChanged)

public:
    explicit Library(QObject* parent = nullptr);

    Q_INVOKABLE void scanFolder(const QString& folderPath);
    Q_INVOKABLE QList<Track> tracks() const { return m_tracks; }
    Q_INVOKABLE void clear();
    Q_INVOKABLE int count() const { return m_tracks.size(); }
    Q_INVOKABLE void pickFolderAndScan();
    Q_INVOKABLE void scanDefaultMusicFolder();
    Q_INVOKABLE void loadFromDb();

    bool scanning() const { return m_scanning; }
    int scanCurrent() const { return m_scanCurrent; }
    int scanTotal() const { return m_scanTotal; }

signals:
    void scanStarted();
    void scanProgress(int current, int total);
    void scanFinished(int total);
    void tracksChanged();
    void errorMessage(const QString& message);
    void scanningChanged();
    void scanProgressChanged();

private:
    QList<Track> m_tracks;
    QSet<QString> m_seenPaths;
    LibraryDb m_db;    // ← NEW — prevents duplicates
    bool m_scanning = false;
    int m_scanCurrent = 0;
    int m_scanTotal = 0;
};