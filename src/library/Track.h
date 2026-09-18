#pragma once

#include <QString>
#include <QUrl>

struct Track {
    QString filePath;
    QString title;
    QString artist;
    QString album;
    QString genre;
    int     year       = 0;
    int     trackNumber = 0;
    int     durationMs  = 0;   // milliseconds
    QString coverPath;         // cached album art file path (may be empty)

    QUrl fileUrl() const { return QUrl::fromLocalFile(filePath); }

    bool isValid() const { return !filePath.isEmpty(); }
};