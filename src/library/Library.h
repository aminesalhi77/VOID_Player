#pragma once

#include <QObject>
#include <QList>
#include <QString>
#include <QVariantList>
#include <QSet>
#include "library/Track.h"
#include "library/LibraryDb.h"

class Library : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(int scanCurrent READ scanCurrent NOTIFY scanProgressChanged)
    Q_PROPERTY(int scanTotal READ scanTotal NOTIFY scanProgressChanged)
    Q_PROPERTY(int trackCount READ trackCount NOTIFY tracksChanged)

public:
    explicit Library(QObject* parent = nullptr);

    Q_INVOKABLE void scanFolder(const QString& folderPath);
    Q_INVOKABLE QList<Track> tracks() const { return m_tracks; }
    Q_INVOKABLE void clear();
    Q_INVOKABLE int count() const { return m_tracks.size(); }
    Q_INVOKABLE void pickFolderAndScan();
    Q_INVOKABLE void scanDefaultMusicFolder();
    Q_INVOKABLE void loadFromDb();

    // Custom lyrics (from QML)
    Q_INVOKABLE bool    saveCustomLyrics(const QString& filePath,
                                        const QString& content,
                                        bool isSynced);
    Q_INVOKABLE QString loadCustomLyrics(const QString& filePath) const;
    Q_INVOKABLE bool    customLyricsSynced(const QString& filePath) const;
    Q_INVOKABLE bool    hasCustomLyrics(const QString& filePath) const;

    // Artist image cache (QML)
    Q_INVOKABLE bool    saveArtistImage(const QString& artist, const QString& url);
    Q_INVOKABLE QString loadArtistImage(const QString& artist) const;

    // Direct DB access (for C++ fetchers)
    LibraryDb& db() { return m_db; }
    Q_INVOKABLE bool    removeCustomLyrics(const QString& filePath);

    // Auto-fetched lyrics cache
    Q_INVOKABLE bool    saveCachedLyrics(const QString& filePath,
                                        const QString& content,
                                        bool isSynced,
                                        const QString& source);
    Q_INVOKABLE QString loadCachedLyrics(const QString& filePath);
    Q_INVOKABLE bool    cachedLyricsSynced(const QString& filePath) const;
    Q_INVOKABLE QString cachedLyricsSource(const QString& filePath) const;
    Q_INVOKABLE bool    hasCachedLyrics(const QString& filePath) const;

    bool scanning() const { return m_scanning; }
    int scanCurrent() const { return m_scanCurrent; }
    int scanTotal() const { return m_scanTotal; }
    int trackCount() const { return m_tracks.size(); }


    // ===== Playlists (QML-exposed) =====
    // These are DECLARATIONS only — implementations in Library.cpp
    Q_INVOKABLE QVariantList listPlaylists() const;
    Q_INVOKABLE int  createPlaylist(const QString& name, const QString& icon, const QString& color);
    Q_INVOKABLE bool renamePlaylist(int id, const QString& name);
    Q_INVOKABLE bool updatePlaylistIcon(int id, const QString& icon, const QString& color);
    Q_INVOKABLE bool deletePlaylist(int id);
    Q_INVOKABLE QVariantList playlistTracks(int playlistId) const;
    Q_INVOKABLE bool addTrackToPlaylist(int playlistId, const QString& filePath);
    Q_INVOKABLE bool removeTrackFromPlaylist(int playlistId, const QString& filePath);
    Q_INVOKABLE QVariantList playlistsForTrack(const QString& filePath) const;

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
    LibraryDb m_db;
    bool m_scanning = false;
    int m_scanCurrent = 0;
    int m_scanTotal = 0;
};