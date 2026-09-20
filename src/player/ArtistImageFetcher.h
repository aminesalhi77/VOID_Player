#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QHash>
#include <QString>

class LibraryDb;

class ArtistImageFetcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit ArtistImageFetcher(QObject* parent = nullptr);

    void setDb(LibraryDb* db);
    void preloadFromDb();

    QString status() const { return m_status; }

    Q_INVOKABLE QString get(const QString& artistName);

signals:
    void imageReady(const QString& artistName, const QString& imageUrl);
    void statusChanged();

private:
    void setStatus(const QString& s);
    QString cacheKey(const QString& artist) const;

    QNetworkAccessManager* m_net;
    LibraryDb* m_db = nullptr;
    QHash<QString, QString> m_cache;
    QHash<QString, bool> m_pending;
    QString m_status;
};

