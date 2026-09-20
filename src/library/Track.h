#pragma once

#include <QString>
#include <QUrl>
#include <QObject>

class Track {
    Q_GADGET

    Q_PROPERTY(QString filePath      MEMBER filePath)
    Q_PROPERTY(QString title         MEMBER title)
    Q_PROPERTY(QString artist        MEMBER artist)
    Q_PROPERTY(QString album         MEMBER album)
    Q_PROPERTY(QString genre         MEMBER genre)
    Q_PROPERTY(int     year          MEMBER year)
    Q_PROPERTY(int     trackNumber   MEMBER trackNumber)
    Q_PROPERTY(int     durationMs    MEMBER durationMs)
    Q_PROPERTY(QString coverPath     MEMBER coverPath)

public:
    QString filePath;
    QString title;
    QString artist;
    QString album;
    QString genre;
    int     year         = 0;
    int     trackNumber  = 0;
    int     durationMs   = 0;
    QString coverPath;

    QUrl fileUrl() const { return QUrl::fromLocalFile(filePath); }

    bool isValid() const { return !filePath.isEmpty(); }
};

Q_DECLARE_METATYPE(Track)
