#pragma once

#include <QString>
#include <QHash>
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
    bool    removeCachedLyrics(const QString& filePath);

    // Artist image cache
    bool    saveArtistImage(const QString& artistName, const QString& imageUrl);
    QString loadArtistImage(const QString& artistName) const;
    QHash<QString, QString> loadAllArtistImages() const;

    // ===== User playlists =====
    struct Playlist {
        int     id = -1;
        QString name;
        QString icon;
        QString color;
    };

    QList<Playlist> listPlaylists() const;
    int     createPlaylist(const QString& name, const QString& icon, const QString& color);
    bool    renamePlaylist(int id, const QString& name);
    bool    updatePlaylistIcon(int id, const QString& icon, const QString& color);
    bool    deletePlaylist(int id);

    QList<QString> playlistTrackPaths(int playlistId) const;
    bool    addTrackToPlaylist(int playlistId, const QString& filePath);
    bool    removeTrackFromPlaylist(int playlistId, const QString& filePath);
    QList<int> playlistsForTrack(const QString& filePath) const;

private:
    bool createSchema();
    QSqlDatabase m_db;
    QString      m_connectionName;
};
