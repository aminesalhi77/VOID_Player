#pragma once

#include <QAbstractListModel>
#include "library/Library.h"

class TrackModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        FilePathRole = Qt::UserRole + 1,
        TitleRole,
        ArtistRole,
        AlbumRole,
        GenreRole,
        YearRole,
        DurationMsRole,
        DurationTextRole,
        CoverPathRole,
        CoverUrlRole,
        FileUrlRole,
        TrackNumberRole,
    };

    explicit TrackModel(Library* library, QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

private slots:
    void onTracksChanged();

private:
    Library* m_library;
    QList<Track> m_tracks;
};