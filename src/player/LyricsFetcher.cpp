#include "player/LyricsFetcher.h"
#include "library/LibraryDb.h"

#include <QUrl>
#include <QUrlQuery>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <algorithm>

LyricsFetcher::LyricsFetcher(QObject* parent)
    : QObject(parent)
    , m_net(new QNetworkAccessManager(this))
    , m_timeoutTimer(new QTimer(this))
{
    m_timeoutTimer->setSingleShot(true);
    m_timeoutTimer->setInterval(8000);   // 8s timeout per request

    connect(m_timeoutTimer, &QTimer::timeout, this, [this]() {
        if (m_currentReply) {
            qDebug() << "VOID: lyrics request timed out";
            m_currentReply->abort();
        }
    });
}

void LyricsFetcher::setStatus(const QString& s) {
    if (m_status == s) return;
    m_status = s;

    // Auto-save to DB cache when a fetch succeeds
    if (s == "found" && m_db && !m_currentFilePath.isEmpty()
        && m_source != "custom" && m_source != "cache") {
        qDebug() << "VOID: saving lyrics for" << m_currentFilePath
                 << "source:" << m_source;

        QString text;
        for (int i = 0; i < m_lines.size(); i++) {
            const QVariantMap lm = m_lines[i].toMap();
            const QString line = lm.value("text").toString();
            if (m_synced && lm.value("timeMs").toInt() > 0) {
                const qint64 ms = lm.value("timeMs").toLongLong();
                const int totalSec = ms / 1000;
                const int min = totalSec / 60;
                const double sec = ms / 1000.0 - min * 60;
                text += QString("[%1:%2] %3\n")
                    .arg(min, 2, 10, QChar('0'))
                    .arg(sec, 5, 'f', 2, QChar('0'))
                    .arg(line);
            } else {
                text += line + "\n";
            }
        }

        bool ok = m_db->saveCachedLyrics(m_currentFilePath, text, m_synced, m_source);
        qDebug() << "VOID: cached lyrics" << (ok ? "OK" : "FAIL")
                 << m_source << m_lines.size() << "lines";
    }

    emit statusChanged();
}

void LyricsFetcher::setSource(const QString& s) {
    if (m_source == s) return;
    m_source = s;
    emit sourceChanged();
}

QString LyricsFetcher::cleanTitle(const QString& raw) {
    QString out = raw;

    // Strip anything inside () [] {} — "Official Audio", "Lyric Video", etc.
    out.replace(QRegularExpression(R"(\s*[\(\[\{][^\)\]\}]*[\)\]\}]\s*)"), " ");

    // Strip leftover keywords
    static const QStringList junk = {
        "official audio", "official video", "official music video",
        "lyric video", "lyrics video", "official visualizer", "visualizer",
        "audio", "lyrics", "mv", "hd", "4k", "explicit", "clean"
    };
    for (const QString& j : junk) {
        out.replace(QRegularExpression("\\b" + QRegularExpression::escape(j)
                    + "\\b", QRegularExpression::CaseInsensitiveOption), " ");
    }

    return out.trimmed().simplified();
}

QString LyricsFetcher::cleanArtist(const QString& raw) {
    QString out = raw;
    // Strip "feat." / "ft." tags — LRCLIB matches better without
    out.replace(QRegularExpression(R"(\s+(feat\.?|ft\.?|featuring)\s+[^,]+)",
                QRegularExpression::CaseInsensitiveOption), "");
    return out.trimmed().simplified();
}

void LyricsFetcher::clear() {
    m_lines.clear();
    m_currentLine = -1;
    m_synced = false;
    m_source = "";
    emit linesChanged();
    emit currentLineChanged();
    emit syncedChanged();
    emit sourceChanged();
    setStatus("idle");
}

void LyricsFetcher::fetch(const QString& artist, const QString& title,
                          const QString& album, int durationSec) {
    if (title.isEmpty()) {
        clear();
        setStatus("notfound");
        return;
    }

    // Cache key based on cleaned metadata
    const QString ca = cleanArtist(artist);
    const QString ct = cleanTitle(title);
    const QString key = ca + "|" + ct;

    // Reset internal state (but preserve m_currentFilePath — caller set it)

    if (key == m_lastQueryKey && m_status == "found") {
        return;   // Already loaded
    }
    m_lastQueryKey = key;

    clear();
    setStatus("loading");

    m_queryArtist = ca;
    m_queryTitle  = ct;
    m_queryAlbum  = album;
    m_queryDuration = durationSec;

    qDebug() << "VOID: fetching lyrics for" << ca << "-" << ct;

    // If artist is unknown/empty, /api/get won't work — go straight to search
    const QString lowerArtist = ca.toLower().trimmed();
    const bool artistKnown = !ca.isEmpty()
                             && lowerArtist != "unknown artist"
                             && lowerArtist != "unknown"
                             && lowerArtist != "various artists";

    if (artistKnown) {
        tryLrclibGet();
    } else {
        qDebug() << "VOID: artist unknown — skipping /api/get, using search";
        tryLrclibSearch();
    }
}

// ============================================================
//  Step 1 — LRCLIB exact match
// ============================================================
void LyricsFetcher::tryLrclibGet() {
    QUrl url("https://lrclib.net/api/get");
    QUrlQuery q;
    q.addQueryItem("artist_name", m_queryArtist);
    q.addQueryItem("track_name",  m_queryTitle);
    if (!m_queryAlbum.isEmpty() && m_queryAlbum != "Unknown Album")
        q.addQueryItem("album_name", m_queryAlbum);
    if (m_queryDuration > 0)
        q.addQueryItem("duration", QString::number(m_queryDuration));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader,
                  "VOID/1.0 (https://github.com/aminesalhi77/VOID_Player)");

    if (m_currentReply) m_currentReply->deleteLater();
    m_currentReply = m_net->get(req);
    m_timeoutTimer->start();

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        m_timeoutTimer->stop();
        auto* reply = m_currentReply;
        m_currentReply = nullptr;
        if (!reply) return;
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qDebug() << "VOID: LRCLIB get miss — trying search";
            tryLrclibSearch();
            return;
        }

        const QByteArray data = reply->readAll();
        const QJsonObject obj = QJsonDocument::fromJson(data).object();

        const QString synced = obj.value("syncedLyrics").toString();
        if (!synced.isEmpty()) {
            parseLRC(synced);
            m_synced = true;
            emit syncedChanged();
            setSource("lrclib");
            setStatus("found");
            qDebug() << "VOID: LRCLIB returned synced lyrics";
            return;
        }

        const QString plain = obj.value("plainLyrics").toString();
        if (!plain.isEmpty()) {
            parsePlain(plain);
            m_synced = false;
            emit syncedChanged();
            setSource("lrclib");
            setStatus("found");
            qDebug() << "VOID: LRCLIB returned plain lyrics";
            return;
        }

        qDebug() << "VOID: LRCLIB get returned empty — trying search";
        tryLrclibSearch();
    });
}

// ============================================================
//  Step 2 — LRCLIB fuzzy search
// ============================================================
void LyricsFetcher::tryLrclibSearch() {
    // Try MULTIPLE query variants to catch more matches
    tryLrclibSearchWithQuery(m_queryArtist, m_queryTitle);
}

void LyricsFetcher::tryLrclibSearchWithQuery(const QString& artist, const QString& title) {
    QUrl url("https://lrclib.net/api/search");
    QUrlQuery q;

    // Only include artist in query if it's a real one
    const QString lowerArtist = artist.toLower().trimmed();
    const bool artistKnown = !artist.isEmpty()
                             && lowerArtist != "unknown artist"
                             && lowerArtist != "unknown";

    if (artistKnown) {
        q.addQueryItem("q", artist + " " + title);
        qDebug() << "VOID: search query:" << (artist + " " + title);
    } else {
        q.addQueryItem("q", title);
        qDebug() << "VOID: search query (title only):" << title;
    }
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader,
                  "VOID/1.0 (https://github.com/aminesalhi77/VOID_Player)");

    if (m_currentReply) m_currentReply->deleteLater();
    m_currentReply = m_net->get(req);
    m_timeoutTimer->start();

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        m_timeoutTimer->stop();
        auto* reply = m_currentReply;
        m_currentReply = nullptr;
        if (!reply) return;
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            tryLyricsOvh();
            return;
        }

        const QJsonArray arr = QJsonDocument::fromJson(reply->readAll()).array();
        if (arr.isEmpty()) {
            tryLyricsOvh();
            return;
        }

        const QJsonObject best = pickBestResult(arr);
        if (best.isEmpty()) {
            tryLyricsOvh();
            return;
        }

        const QString synced = best.value("syncedLyrics").toString();
        if (!synced.isEmpty()) {
            parseLRC(synced);
            m_synced = true;
            emit syncedChanged();
            setSource("lrclib-search");
            setStatus("found");
            qDebug() << "VOID: LRCLIB search returned synced lyrics";
            return;
        }

        const QString plain = best.value("plainLyrics").toString();
        if (!plain.isEmpty()) {
            parsePlain(plain);
            m_synced = false;
            emit syncedChanged();
            setSource("lrclib-search");
            setStatus("found");
            qDebug() << "VOID: LRCLIB search returned plain lyrics";
            return;
        }

        tryLyricsOvh();
    });
}

QJsonObject LyricsFetcher::pickBestResult(const QJsonArray& results) const {
    // Score each result by:
    //   - synced lyrics bonus (+50)
    //   - title similarity (0-30)
    //   - artist similarity (0-30)
    //   - duration match within 10s (+20)
    // Pick highest score.

    const QString wantedTitle  = m_queryTitle.toLower().simplified();
    const QString wantedArtist = m_queryArtist.toLower().simplified();

    QJsonObject best;
    int bestScore = -1;

    for (const QJsonValue& v : results) {
        const QJsonObject o = v.toObject();

        const QString t = o.value("trackName").toString().toLower().simplified();
        const QString a = o.value("artistName").toString().toLower().simplified();
        const int dur = static_cast<int>(o.value("duration").toDouble());

        int score = 0;

        // Synced lyrics bonus
        if (!o.value("syncedLyrics").toString().isEmpty()) score += 50;

        // Title similarity — word overlap
        if (t == wantedTitle) score += 30;
        else if (t.contains(wantedTitle) || wantedTitle.contains(t)) score += 20;
        else {
            const QStringList tw = wantedTitle.split(' ', Qt::SkipEmptyParts);
            int hits = 0;
            for (const QString& w : tw) if (t.contains(w)) hits++;
            if (!tw.isEmpty()) score += (hits * 30) / tw.size() / 2;
        }

        // Artist similarity — only score if we have a real artist
        const bool artistKnown = !wantedArtist.isEmpty()
                                 && wantedArtist != "unknown artist"
                                 && wantedArtist != "unknown";
        if (artistKnown) {
            if (a == wantedArtist) score += 30;
            else if (a.contains(wantedArtist) || wantedArtist.contains(a)) score += 20;
        } else {
            // No artist in metadata — give every candidate a neutral bump
            // so title similarity becomes the deciding factor
            score += 10;
        }

        // Duration match within 10 seconds
        if (m_queryDuration > 0 && dur > 0) {
            const int diff = qAbs(dur - m_queryDuration);
            if (diff <= 5) score += 20;
            else if (diff <= 10) score += 10;
            else if (diff > 30) score -= 20;   // likely a different song
        }

        if (score > bestScore) {
            bestScore = score;
            best = o;
        }
    }

    qDebug() << "VOID: best search match score:" << bestScore
             << "title:" << best.value("trackName").toString();
    return best;
}



// ============================================================
//  Step 3 — lyrics.ovh (last resort)
// ============================================================
void LyricsFetcher::tryLyricsOvh() {
    QUrl url("https://api.lyrics.ovh/v1/"
             + QUrl::toPercentEncoding(m_queryArtist) + "/"
             + QUrl::toPercentEncoding(m_queryTitle));

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, "VOID/1.0");

    if (m_currentReply) m_currentReply->deleteLater();
    m_currentReply = m_net->get(req);
    m_timeoutTimer->start();

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        m_timeoutTimer->stop();
        auto* reply = m_currentReply;
        m_currentReply = nullptr;
        if (!reply) return;
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            setStatus("notfound");
            return;
        }

        const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        const QString text = obj.value("lyrics").toString();
        if (text.isEmpty()) {
            setStatus("notfound");
            return;
        }

        parsePlain(text);
        m_synced = false;
        emit syncedChanged();
        setSource("lyrics.ovh");
        setStatus("found");
        qDebug() << "VOID: lyrics.ovh returned" << m_lines.size() << "lines";
    });
}

// ============================================================
//  Parsers
// ============================================================
void LyricsFetcher::parseLRC(const QString& lrc) {
    QVariantList result;
    static const QRegularExpression re(R"(^\[(\d+):(\d+(?:\.\d+)?)\](.*)$)");

    const QStringList raw = lrc.split('\n');
    for (const QString& rawLine : raw) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty()) continue;

        const auto m = re.match(line);
        if (!m.hasMatch()) continue;

        const int minutes = m.captured(1).toInt();
        const double seconds = m.captured(2).toDouble();
        const QString text = m.captured(3).trimmed();
        if (text.isEmpty()) continue;

        QVariantMap entry;
        entry["timeMs"] = minutes * 60000 + static_cast<int>(seconds * 1000.0);
        entry["text"] = text;
        result.append(entry);
    }

    std::sort(result.begin(), result.end(),
        [](const QVariant& a, const QVariant& b) {
            return a.toMap().value("timeMs").toInt()
                 < b.toMap().value("timeMs").toInt();
        });

    m_lines = result;
    m_currentLine = -1;
    emit linesChanged();
    emit currentLineChanged();
}

void LyricsFetcher::parsePlain(const QString& text) {
    QVariantList lines;
    const QStringList raw = text.split('\n');
    for (const QString& line : raw) {
        const QString t = line.trimmed();
        if (t.isEmpty()) continue;
        QVariantMap m;
        m["timeMs"] = 0;
        m["text"] = t;
        lines.append(m);
    }
    m_lines = lines;
    m_currentLine = -1;
    emit linesChanged();
    emit currentLineChanged();
}

void LyricsFetcher::loadCustomText(const QString& content, bool isSynced) {
    if (content.isEmpty()) {
        clear();
        setStatus("notfound");
        return;
    }
    if (isSynced) {
        parseLRC(content);
        m_synced = true;
        emit syncedChanged();
    } else {
        parsePlain(content);
        m_synced = false;
        emit syncedChanged();
    }
    setSource("custom");
    setStatus("found");
}

void LyricsFetcher::setPosition(qint64 ms) {
    if (m_lines.isEmpty() || !m_synced) return;

    int idx = -1;
    for (int i = 0; i < m_lines.size(); i++) {
        const int t = m_lines[i].toMap().value("timeMs").toInt();
        if (t <= ms) idx = i;
        else break;
    }

    if (idx != m_currentLine) {
        m_currentLine = idx;
        emit currentLineChanged();
    }
}

void LyricsFetcher::fetchForFile(const QString& filePath, const QString& artist,
                                 const QString& title, const QString& album,
                                 int durationSec) {
    // ALWAYS reset state for the new track
    clear();
    m_currentFilePath = filePath;

    // 1. Check DB cache first
    if (m_db && !filePath.isEmpty()) {
        bool isSynced = false;
        QString src;
        QString cached = m_db->loadCachedLyrics(filePath, &isSynced, &src);
        if (!cached.isEmpty()) {
            qDebug() << "VOID: using CACHED lyrics from" << src
                     << "for" << filePath;
            loadCustomText(cached, isSynced);
            setSource("cache");
            return;
        }
    }

    // 2. Not cached → fetch from network
    qDebug() << "VOID: no cache for" << filePath << "— fetching";
    fetch(artist, title, album, durationSec);
}

void LyricsFetcher::forceFetch(const QString& filePath, const QString& artist,
                               const QString& title, const QString& album,
                               int durationSec) {
    // Delete the cache entry so fetch() doesn't serve stale lyrics
    if (m_db && !filePath.isEmpty()) {
        m_db->removeCachedLyrics(filePath);
    }

    // Clear and fetch fresh from the network
    clear();
    m_currentFilePath = filePath;
    qDebug() << "VOID: force-refreshing lyrics for" << filePath;
    fetch(artist, title, album, durationSec);
}
