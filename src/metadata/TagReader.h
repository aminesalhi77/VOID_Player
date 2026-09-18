#pragma once

#include <QString>
#include "library/Track.h"

class TagReader {
public:
    // Read metadata from an audio file. Returns invalid track if unsupported.
    static Track read(const QString& filePath);

    // True if file extension is supported
    static bool isSupported(const QString& filePath);

private:
    static QString saveCoverArt(const QString& filePath, const QByteArray& data, const QString& mime);
};