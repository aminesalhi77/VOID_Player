#include "metadata/TagReader.h"

#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QCryptographicHash>

#include <taglib/fileref.h>
#include <taglib/tag.h>
#include <taglib/tpropertymap.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>
#include <taglib/flacfile.h>
#include <taglib/vorbisfile.h>
#include <taglib/mp4file.h>

#include <QDebug>

namespace {
    const QStringList kSupportedExts = {
        "mp3", "flac", "ogg", "oga", "opus", "m4a", "mp4", "aac", "wav"
    };
}

bool TagReader::isSupported(const QString& filePath) {
    const QString ext = QFileInfo(filePath).suffix().toLower();
    return kSupportedExts.contains(ext);
}

Track TagReader::read(const QString& filePath) {
    Track t;
    t.filePath = filePath;

    TagLib::FileRef ref(filePath.toUtf8().constData(), true);
    if (ref.isNull() || !ref.tag()) {
        // Even if tags are missing, keep the file (title = filename)
        t.title = QFileInfo(filePath).completeBaseName();
        return t;
    }

    TagLib::Tag* tag = ref.tag();

    auto toQt = [](const TagLib::String& s) {
        return QString::fromStdString(s.to8Bit(true));
    };

    t.title  = toQt(tag->title()).trimmed();
    t.artist = toQt(tag->artist()).trimmed();
    t.album  = toQt(tag->album()).trimmed();
    t.genre  = toQt(tag->genre()).trimmed();
    t.year   = tag->year();
    t.trackNumber = tag->track();

    if (t.title.isEmpty())  t.title  = QFileInfo(filePath).completeBaseName();
    if (t.artist.isEmpty()) t.artist = "Unknown Artist";
    if (t.album.isEmpty())  t.album  = "Unknown Album";

    if (ref.audioProperties()) {
        t.durationMs = ref.audioProperties()->lengthInMilliseconds();
    }

    // --- Album art extraction ---
    // Try MP3 (ID3v2 APIC frame)
    if (auto* mpeg = dynamic_cast<TagLib::MPEG::File*>(ref.file())) {
        if (mpeg->ID3v2Tag()) {
            auto frames = mpeg->ID3v2Tag()->frameList("APIC");
            if (!frames.isEmpty()) {
                auto* apic = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame*>(frames.front());
                if (apic && !apic->picture().isEmpty()) {
                    const auto data = QByteArray(apic->picture().data(), apic->picture().size());
                    t.coverPath = saveCoverArt(filePath, data, QString::fromStdString(apic->mimeType().to8Bit(true)));
                }
            }
        }
    }
    // Try FLAC (picture block)
    else if (auto* flac = dynamic_cast<TagLib::FLAC::File*>(ref.file())) {
        const auto& pics = flac->pictureList();
        if (!pics.isEmpty() && !pics.front()->data().isEmpty()) {
            const auto& pic = pics.front();
            const auto data = QByteArray(pic->data().data(), pic->data().size());
            t.coverPath = saveCoverArt(filePath, data, QString::fromStdString(pic->mimeType().to8Bit(true)));
        }
    }

    return t;
}

QString TagReader::saveCoverArt(const QString& filePath, const QByteArray& data, const QString& mime) {
    if (data.isEmpty()) return {};

    // Cache dir: ~/.cache/void/covers/
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                             + "/covers";
    QDir().mkpath(cacheDir);

    // Hash the audio file path -> unique cover filename
    const QByteArray hash = QCryptographicHash::hash(filePath.toUtf8(), QCryptographicHash::Md5).toHex();

    // Guess extension from mime
    QString ext = "jpg";
    if (mime.contains("png")) ext = "png";
    else if (mime.contains("webp")) ext = "webp";

    const QString outPath = cacheDir + "/" + QString::fromLatin1(hash) + "." + ext;

    // Skip if already cached
    if (QFileInfo::exists(outPath)) return outPath;

    QFile f(outPath);
    if (f.open(QIODevice::WriteOnly)) {
        f.write(data);
        f.close();
        return outPath;
    }
    return {};
}