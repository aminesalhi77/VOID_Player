#pragma once

#include <QString>
#include <QList>
#include <QSqlDatabase>
#include "library/Track.h"

class LibraryDb {
public:
    LibraryDb();
    ~LibraryDb();

    bool open(const QString& dbPath);
    void close();

    QList<Track> loadAll() const;
    bool upsert(const Track& track);
    bool remove(const QString& path);
    bool exists(const QString& path) const;
    int  count() const;
    void clear();

private:
    bool createSchema();
    QSqlDatabase m_db;
    QString      m_connectionName;
};
