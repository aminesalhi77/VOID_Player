#include "models/TrackModel.h"
#include <QUrl>

TrackModel::TrackModel(Library* library, QObject* parent)
    : QAbstractListModel(parent), m_library(library)
{
    connect(m_library, &Library::tracksChanged,
            this, &TrackModel::onTracksChanged);
}

int TrackModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_tracks.size();
}

QVariant TrackModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_tracks.size()) return {};

    const Track& t = m_tracks.at(index.row());

    switch (role) {
    case FilePathRole:    return t.filePath;
    case TitleRole:       return t.title;
    case ArtistRole:      return t.artist;
    case AlbumRole:       return t.album;
    case GenreRole:       return t.genre;
    case YearRole:        return t.year;
    case TrackNumberRole: return t.trackNumber;
    case DurationMsRole:  return t.durationMs;
    case DurationTextRole: {
        const int s = t.durationMs / 1000;
        return QString("%1:%2")
            .arg(s / 60)
            .arg(s % 60, 2, 10, QChar('0'));
    }
    case CoverPathRole: return t.coverPath;
    case CoverUrlRole:  return t.coverPath.isEmpty()
                            ? QString()
                            : QUrl::fromLocalFile(t.coverPath).toString();
    case FileUrlRole:   return t.fileUrl().toString();
    default: return {};
    }
}

QHash<int, QByteArray> TrackModel::roleNames() const {
    return {
        { FilePathRole,     "filePath" },
        { TitleRole,        "title" },
        { ArtistRole,       "artist" },
        { AlbumRole,        "album" },
        { GenreRole,        "genre" },
        { YearRole,         "year" },
        { TrackNumberRole,  "trackNumber" },
        { DurationMsRole,   "durationMs" },
        { DurationTextRole, "durationText" },
        { CoverPathRole,    "coverPath" },
        { CoverUrlRole,     "coverUrl" },
        { FileUrlRole,      "fileUrl" },
    };
}

void TrackModel::onTracksChanged() {
    beginResetModel();
    m_tracks = m_library->tracks();
    endResetModel();
}