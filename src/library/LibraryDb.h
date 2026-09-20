#pragma once

#include <QString>
#include <QList>
#include <QSqlDatabase>
#include "library/Track.h"

class LibraryDb {
public:
    LibraryDb();
    ~LibraryDb();

    bool open(const QString& dbPath);
    void close();

    QList<Track> loadAll() const;
    bool upsert(const Track& track);
    bool remove(const QString& path);
    bool exists(const QString& path) const;
    int  count() const;
    void clear();

    // Custom lyrics storage
    bool saveLyrics(const QString& filePath, const QString& content, bool isSynced);
    QString loadLyrics(const QString& filePath, bool* isSynced = nullptr) const;
    bool hasLyrics(const QString& filePath) const;
    bool removeLyrics(const QString& filePath);
    int  lyricsCount() const;
    // Auto-fetched lyrics cache
    bool    saveCachedLyrics(const QString& filePath, const QString& content,
                             bool isSynced, const QString& source);
    QString loadCachedLyrics(const QString& filePath, bool* isSynced,
                             QString* source) const;
    bool    hasCachedLyrics(const QString& filePath) const;

private:
    bool createSchema();
    QSqlDatabase m_db;
    QString      m_connectionName;
};
