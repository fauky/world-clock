#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QScreen>

#include "clockprovider.h"
#include "configreader.h"

int main(int argc, char *argv[])
{
    // Required for proper rendering on RPi framebuffer / EGLFS
    qputenv("QT_QPA_EGLFS_PHYSICAL_WIDTH",  "95");   // 4.3" @ 480px → ~95 mm
    qputenv("QT_QPA_EGLFS_PHYSICAL_HEIGHT", "54");   // 16:9 → ~54 mm

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling, false);
    QGuiApplication app(argc, argv);

    // Force Material style
    QQuickStyle::setStyle("Material");

    // Read config
    ConfigReader cfg;
    cfg.load("/etc/world-clock/clock.conf");

    // Create two clock providers and configure them
    ClockProvider leftClock;
    leftClock.setTimezone(cfg.timezoneLeft());

    ClockProvider rightClock;
    rightClock.setTimezone(cfg.timezoneRight());

    // Expose everything to QML
    QQmlApplicationEngine engine;
    QQmlContext *ctx = engine.rootContext();

    ctx->setContextProperty("leftClock",     &leftClock);
    ctx->setContextProperty("rightClock",    &rightClock);
    ctx->setContextProperty("locationLeft",  cfg.locationLeft());
    ctx->setContextProperty("locationRight", cfg.locationRight());

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
