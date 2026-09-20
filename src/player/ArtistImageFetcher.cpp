#include "player/ArtistImageFetcher.h"

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

    // Already fetched?
    if (m_cache.contains(key)) {
        return m_cache.value(key);
    }

    // Already fetching?
    if (m_pending.contains(key)) {
        return "";
    }

    m_pending.insert(key, true);

    // Deezer search API — no auth required
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

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "VOID: artist image fetch failed:" << reply->errorString();
            m_cache.insert(key, "");
            return;
        }

        const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        const QJsonArray data = obj.value("data").toArray();

        QString imageUrl;
        if (!data.isEmpty()) {
            const QJsonObject artist = data.first().toObject();
            imageUrl = artist.value("picture_xl").toString();
            if (imageUrl.isEmpty()) imageUrl = artist.value("picture_big").toString();
            if (imageUrl.isEmpty()) imageUrl = artist.value("picture_medium").toString();
        }

        m_cache.insert(key, imageUrl);
        qDebug() << "VOID: artist image for" << artistName << "→"
                 << (imageUrl.isEmpty() ? "(none)" : "found");

        emit imageReady(artistName, imageUrl);
    });

    return "";
}
