#include "player/Playback.h"
#include <QDebug>
#include <QAudioBufferOutput>

Playback::Playback(QObject* parent)
    : QObject(parent)
    , m_player(new QMediaPlayer(this))
    , m_audio(new QAudioOutput(this))
{
    m_player->setAudioOutput(m_audio);
    m_audio->setVolume(m_volume / 100.0);

    m_analyzer = new AudioAnalyzer(this);
    auto* bufOut = new QAudioBufferOutput(this);
    m_player->setAudioBufferOutput(bufOut);
    connect(bufOut, &QAudioBufferOutput::audioBufferReceived,
            m_analyzer, &AudioAnalyzer::processBuffer);

    connect(m_player, &QMediaPlayer::playingChanged, this, [this]() {
        const bool isPlaying = (m_player->playbackState() == QMediaPlayer::PlayingState);
        if (isPlaying != m_playing) {
            m_playing = isPlaying;
            emit playingChanged();
        }
    });

    connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64) {
        emit positionChanged();
    });

    connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64) {
        emit durationChanged();
    });

    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus s) {
        if (s == QMediaPlayer::EndOfMedia) next();
    });
}

QString Playback::coverUrl() const {
    if (m_current.coverPath.isEmpty()) return {};
    return QUrl::fromLocalFile(m_current.coverPath).toString();
}

void Playback::setQueue(const QList<Track>& tracks, int startIndex) {
    m_queue = tracks;
    playIndex(startIndex);
}

void Playback::playIndex(int index) {
    if (index < 0 || index >= m_queue.size()) return;
    m_currentIndex = index;
    m_current = m_queue.at(index);
    emit trackChanged();

    m_player->setSource(QUrl::fromLocalFile(m_current.filePath));
    m_player->play();
}

void Playback::playPause() {
    if (m_currentIndex < 0 && !m_queue.isEmpty()) {
        playIndex(0);
        return;
    }
    if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        m_player->pause();
    } else {
        m_player->play();
    }
}

void Playback::next() {
    if (m_queue.isEmpty()) return;
    playIndex((m_currentIndex + 1) % m_queue.size());
}

void Playback::previous() {
    if (m_queue.isEmpty()) return;
    int idx = m_currentIndex - 1;
    if (idx < 0) idx = m_queue.size() - 1;
    playIndex(idx);
}

void Playback::seek(qint64 ms) {
    m_player->setPosition(ms);
}

void Playback::skipForward10() {
    m_player->setPosition(qMin(m_player->position() + 10000, m_player->duration()));
}

void Playback::skipBackward10() {
    m_player->setPosition(qMax(m_player->position() - 10000, (qint64)0));
}

void Playback::setVolume(int v) {
    v = qBound(0, v, 100);
    if (v == m_volume) return;
    m_volume = v;
    m_audio->setVolume(v / 100.0);
    emit volumeChanged();
}
