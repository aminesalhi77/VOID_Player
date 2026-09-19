#include "player/Playback.h"
#include <QDebug>
#include <QCoreApplication>
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

    // ============ PERSISTENCE ============
    // Save position every 5 seconds while playing
    m_saveTimer = new QTimer(this);
    m_saveTimer->setInterval(5000);
    connect(m_saveTimer, &QTimer::timeout, this, [this]() {
        if (m_current.filePath.isEmpty()) return;
        QSettings s("VOID", "VOID");
        s.setValue("lastTrack", m_current.filePath);
        s.setValue("lastPosition", m_player->position());
        s.setValue("lastVolume", m_volume);
    });
    m_saveTimer->start();

    // Save state when the app is closing
    connect(qApp, &QCoreApplication::aboutToQuit, this, [this]() {
        if (m_current.filePath.isEmpty()) return;
        QSettings s("VOID", "VOID");
        s.setValue("lastTrack", m_current.filePath);
        s.setValue("lastPosition", m_player->position());
        s.setValue("lastVolume", m_volume);
        s.sync();
        qDebug() << "VOID: saved on quit, position =" << m_player->position();
    });

    // Save on track change
    connect(this, &Playback::trackChanged, this, [this]() {
        if (m_current.filePath.isEmpty()) return;
        QSettings s("VOID", "VOID");
        s.setValue("lastTrack", m_current.filePath);
        s.setValue("lastPosition", 0);
    });

    // Save on volume change
    connect(this, &Playback::volumeChanged, this, [this]() {
        QSettings s("VOID", "VOID");
        s.setValue("lastVolume", m_volume);
    });
}

void Playback::loadQueueOnly(const QList<Track>& tracks) {
    m_queue = tracks;
    // Do NOT play anything — restoreLastSession will pick the track
}

void Playback::restoreLastSession() {
    QSettings s("VOID", "VOID");

    // Restore volume (always)
    int savedVolume = s.value("lastVolume", 70).toInt();
    setVolume(savedVolume);

    // Restore last track if it still exists
    const QString savedPath = s.value("lastTrack", "").toString();
    if (savedPath.isEmpty()) return;

    // Get full track list from the library
    // We don't have direct access — rely on the queue being set from QML
    // So instead: find the track in m_queue and play it paused at the saved position
    if (m_queue.isEmpty()) return;

    int idx = -1;
    for (int i = 0; i < m_queue.size(); i++) {
        if (m_queue.at(i).filePath == savedPath) {
            idx = i;
            break;
        }
    }
    if (idx < 0) return;

    const qint64 savedPos = s.value("lastPosition", 0).toLongLong();

    // Load the track but don't auto-play
    m_currentIndex = idx;
    m_current = m_queue.at(idx);
    emit trackChanged();

    m_player->setSource(QUrl::fromLocalFile(m_current.filePath));

    // Seek to saved position once the media is loaded
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
            [this, savedPos](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::LoadedMedia) {
            m_player->setPosition(savedPos);
        }
    }, Qt::SingleShotConnection);
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
