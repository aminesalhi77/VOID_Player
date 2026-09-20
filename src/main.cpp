#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QStandardPaths>
#include <QDir>
#include <QPalette>
#include <QColor>

#include "library/Track.h"
#include "library/Library.h"
#include "models/TrackModel.h"
#include "player/Playback.h"
#include "player/ArtistImageFetcher.h"
#include "player/LyricsFetcher.h"
#include <QAudioBuffer>

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORMTHEME", "qt5ct");
    qputenv("QT_STYLE_OVERRIDE", "Fusion");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    // Register QAudioBuffer so QAudioBufferOutput signals reach AudioAnalyzer
    qRegisterMetaType<QAudioBuffer>("QAudioBuffer");

    // Force GStreamer backend — FFmpeg backend lacks QAudioBufferOutput support
    qputenv("QT_MEDIA_BACKEND", "gstreamer");

    qRegisterMetaType<Track>("Track");
    QApplication app(argc, argv);
    app.setApplicationName("VOID");
    app.setApplicationDisplayName("VOID");
    app.setOrganizationName("VOID");
    app.setApplicationVersion("0.1.0");

    // *** PROJECT-ONLY FIX — override KDE palette ***
    QPalette pal;
    pal.setColor(QPalette::Highlight, QColor("#22d3ee"));
    pal.setColor(QPalette::HighlightedText, QColor("#050508"));
    pal.setColor(QPalette::Window, QColor("#0d0d16"));
    pal.setColor(QPalette::WindowText, QColor("#f2f2f7"));
    pal.setColor(QPalette::Base, QColor("#0d0d16"));
    pal.setColor(QPalette::Text, QColor("#f2f2f7"));
    pal.setColor(QPalette::Button, QColor("#14141f"));
    pal.setColor(QPalette::ButtonText, QColor("#f2f2f7"));
    QGuiApplication::setPalette(pal);

    QQuickStyle::setStyle("Basic");

    QDir().mkpath(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/covers");

    Library library;
    TrackModel trackModel(&library);
    Playback playback;
    ArtistImageFetcher artistImages;
    artistImages.setDb(&library.db());
    artistImages.preloadFromDb();
    LyricsFetcher lyrics;
    lyrics.setDb(&library.db());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("trackModel", &trackModel);
    engine.rootContext()->setContextProperty("playback", &playback);
    engine.rootContext()->setContextProperty("artistImages", &artistImages);
    engine.rootContext()->setContextProperty("lyrics", &lyrics);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule("Void", "Main");

    // Save playback state when app is about to quit
    QObject::connect(&app, &QCoreApplication::aboutToQuit, &playback, [&playback]() {
        // Playback saves its own state
    });

    return app.exec();
}