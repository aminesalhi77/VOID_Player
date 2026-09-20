#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>
#include <QRegularExpression>
#include <QTimer>
#include <QJsonObject>
#include <QJsonArray>

class LyricsFetcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList lines READ lines NOTIFY linesChanged)
    Q_PROPERTY(int currentLine READ currentLine NOTIFY currentLineChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool synced READ synced NOTIFY syncedChanged)
    Q_PROPERTY(QString source READ source NOTIFY sourceChanged)

public:
    explicit LyricsFetcher(QObject* parent = nullptr);

    QVariantList lines() const { return m_lines; }
    int currentLine() const { return m_currentLine; }
    QString status() const { return m_status; }
    bool synced() const { return m_synced; }
    QString source() const { return m_source; }

public slots:
    void fetch(const QString& artist, const QString& title,
               const QString& album, int durationSec);
    void clear();
    void setPosition(qint64 ms);
    void loadCustomText(const QString& content, bool isSynced);

signals:
    void linesChanged();
    void currentLineChanged();
    void statusChanged();
    void syncedChanged();
    void sourceChanged();

private:
    void setStatus(const QString& s);
    void setSource(const QString& s);

    void tryLrclibGet();
    void tryLrclibSearch();
    void tryLyricsOvh();
    void tryLrclibSearchWithQuery(const QString& artist, const QString& title);
    QJsonObject pickBestResult(const QJsonArray& results) const;

    void parseLRC(const QString& lrc);
    void parsePlain(const QString& text);

    static QString cleanTitle(const QString& raw);
    static QString cleanArtist(const QString& raw);

    QNetworkAccessManager* m_net;
    QNetworkReply* m_currentReply = nullptr;
    QTimer* m_timeoutTimer = nullptr;

    QVariantList m_lines;
    int m_currentLine = -1;
    QString m_status = "idle";
    bool m_synced = false;
    QString m_source = "";

    // Current query state
    QString m_queryArtist;
    QString m_queryTitle;
    QString m_queryAlbum;
    int m_queryDuration = 0;
    QString m_lastQueryKey;
};
