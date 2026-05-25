#include "clockprovider.h"
#include <QDebug>

ClockProvider::ClockProvider(QObject *parent)
    : QObject(parent)
    , m_tz(QTimeZone("UTC"))
{
    connect(&m_timer, &QTimer::timeout, this, &ClockProvider::tick);
    m_timer.setInterval(1000);
    m_timer.start();
    update();
}

void ClockProvider::setTimezone(const QString &tz)
{
    QTimeZone newTz(tz.toLatin1());
    if (!newTz.isValid()) {
        qWarning() << "[ClockProvider] Invalid timezone:" << tz << "- keeping UTC";
        return;
    }
    m_tz = newTz;
    update();
    emit timezoneChanged();
}

void ClockProvider::tick()
{
    update();
    emit timeChanged();
}

void ClockProvider::update()
{
    QDateTime now = QDateTime::currentDateTimeUtc().toTimeZone(m_tz);
    QTime t = now.time();
    m_hours   = t.hour()   % 12;   // 0-11 for analog hand
    m_minutes = t.minute();
    m_seconds = t.second();

    // Digital display: 12-hour format with leading zeros and AM/PM
    int displayHour = t.hour() % 12;
    if (displayHour == 0) displayHour = 12;
    m_ampm = (t.hour() < 12) ? "AM" : "PM";
    m_digital = QString("%1:%2")
        .arg(displayHour,  2, 10, QChar('0'))
        .arg(m_minutes,    2, 10, QChar('0'));
}
