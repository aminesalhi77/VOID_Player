#pragma once

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <QList>
#include "library/Track.h"
#include "player/AudioAnalyzer.h"

class Playback : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString title READ title NOTIFY trackChanged)
    Q_PROPERTY(QString artist READ artist NOTIFY trackChanged)
    Q_PROPERTY(QString album READ album NOTIFY trackChanged)
    Q_PROPERTY(QString coverUrl READ coverUrl NOTIFY trackChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY trackChanged)
    Q_PROPERTY(AudioAnalyzer* analyzer READ analyzer CONSTANT)

public:
    explicit Playback(QObject* parent = nullptr);

    bool playing() const { return m_playing; }
    qint64 position() const { return m_player->position(); }
    qint64 duration() const { return m_player->duration(); }
    int volume() const { return m_volume; }
    QString title() const { return m_current.title; }
    QString artist() const { return m_current.artist; }
    QString album() const { return m_current.album; }
    QString coverUrl() const;
    int currentIndex() const { return m_currentIndex; }
    AudioAnalyzer* analyzer() const { return m_analyzer; }

    Q_INVOKABLE void setQueue(const QList<Track>& tracks, int startIndex);
    Q_INVOKABLE void playPause();
    Q_INVOKABLE void playIndex(int index);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void seek(qint64 ms);
    Q_INVOKABLE void skipForward10();
    Q_INVOKABLE void skipBackward10();

public slots:
    void setVolume(int v);

signals:
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void trackChanged();

private:
    QMediaPlayer* m_player;
    QAudioOutput* m_audio;
    QList<Track> m_queue;
    Track m_current;
    int m_currentIndex = -1;
    bool m_playing = false;
    int m_volume = 70;
    AudioAnalyzer* m_analyzer = nullptr;
};
