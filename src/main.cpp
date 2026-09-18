#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QStandardPaths>
#include <QDir>
#include <QPalette>
#include <QColor>

#include "library/Library.h"
#include "models/TrackModel.h"
#include "player/Playback.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORMTHEME", "qt5ct");
    qputenv("QT_STYLE_OVERRIDE", "Fusion");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

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

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("trackModel", &trackModel);
    engine.rootContext()->setContextProperty("playback", &playback);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule("Void", "Main");

    return app.exec();
}