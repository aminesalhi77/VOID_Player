#include "player/ArtistImageFetcher.h"
#include "library/LibraryDb.h"

#include <QUrl>
#include <QUrlQuery>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

ArtistImageFetcher::ArtistImageFetcher(QObject* parent)
    : QObject(parent)
    , m_net(new QNetworkAccessManager(this))
{
}

void ArtistImageFetcher::setDb(LibraryDb* db) {
    m_db = db;
}

void ArtistImageFetcher::preloadFromDb() {
    if (!m_db) return;
    m_cache = m_db->loadAllArtistImages();
    qDebug() << "VOID: preloaded" << m_cache.size() << "artist images from DB";
}

void ArtistImageFetcher::setStatus(const QString& s) {
    if (m_status == s) return;
    m_status = s;
    emit statusChanged();
}

QString ArtistImageFetcher::cacheKey(const QString& artist) const {
    return artist.toLower().trimmed();
}

QString ArtistImageFetcher::get(const QString& artistName) {
    if (artistName.isEmpty() ||
        artistName.toLower() == "unknown artist" ||
        artistName.toLower() == "various artists") {
        return "";
    }

    const QString key = cacheKey(artistName);

    if (m_cache.contains(key)) {
        return m_cache.value(key);
    }
    if (m_pending.contains(key)) {
        return "";
    }

    m_pending.insert(key, true);

    QUrl url("https://api.deezer.com/search/artist");
    QUrlQuery q;
    q.addQueryItem("q", artistName);
    q.addQueryItem("limit", "1");
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader,
                  "VOID/1.0 (https://github.com/aminesalhi77/VOID_Player)");

    QNetworkReply* reply = m_net->get(req);

    connect(reply, &QNetworkReply::finished, this, [this, reply, artistName, key]() {
        reply->deleteLater();
        m_pending.remove(key);

        QString imageUrl;

        if (reply->error() == QNetworkReply::NoError) {
            const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
            const QJsonArray data = obj.value("data").toArray();
            if (!data.isEmpty()) {
                const QJsonObject artist = data.first().toObject();
                imageUrl = artist.value("picture_xl").toString();
                if (imageUrl.isEmpty()) imageUrl = artist.value("picture_big").toString();
                if (imageUrl.isEmpty()) imageUrl = artist.value("picture_medium").toString();
            }
        } else {
            qDebug() << "VOID: artist image fetch failed:" << reply->errorString();
        }

        // Cache in memory + DB (even if empty, so we don't re-fetch)
        m_cache.insert(key, imageUrl);
        if (m_db) {
            m_db->saveArtistImage(key, imageUrl);
        }

        qDebug() << "VOID: artist image for" << artistName << "→"
                 << (imageUrl.isEmpty() ? "(none)" : "found (cached)");

        emit imageReady(artistName, imageUrl);
    });

    return "";
}
