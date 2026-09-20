#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QHash>
#include <QString>

class ArtistImageFetcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit ArtistImageFetcher(QObject* parent = nullptr);

    QString status() const { return m_status; }

    // Q_INVOKABLE — call from QML. Returns cached URL instantly if known,
    // otherwise starts an async fetch and emits imageReady() later.
    Q_INVOKABLE QString get(const QString& artistName);

signals:
    void imageReady(const QString& artistName, const QString& imageUrl);
    void statusChanged();

private:
    void setStatus(const QString& s);
    QString cacheKey(const QString& artist) const;

    QNetworkAccessManager* m_net;
    QHash<QString, QString> m_cache;    // artist → image URL ("" if not found)
    QHash<QString, bool> m_pending;     // artist → is fetch in progress
    QString m_status;
};

