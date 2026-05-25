#pragma once

#include <QObject>
#include <QTimer>
#include <QTimeZone>
#include <QDateTime>

/**
 * ClockProvider
 * Registered as a QML type. One instance per clock.
 * Fires timeChanged() every second; QML reads individual properties.
 */
class ClockProvider : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString timezone  READ timezone  WRITE setTimezone  NOTIFY timezoneChanged)
    Q_PROPERTY(int     hours     READ hours     NOTIFY timeChanged)
    Q_PROPERTY(int     minutes   READ minutes   NOTIFY timeChanged)
    Q_PROPERTY(int     seconds   READ seconds   NOTIFY timeChanged)
    Q_PROPERTY(QString digital   READ digital   NOTIFY timeChanged)   // "HH:MM"
    Q_PROPERTY(QString ampm      READ ampm      NOTIFY timeChanged)   // "AM"/"PM"

public:
    explicit ClockProvider(QObject *parent = nullptr);

    QString timezone()  const { return QString::fromLatin1(m_tz.id()); }
    int     hours()     const { return m_hours;   }
    int     minutes()   const { return m_minutes; }
    int     seconds()   const { return m_seconds; }
    QString digital()   const { return m_digital; }
    QString ampm()      const { return m_ampm; }

    void setTimezone(const QString &tz);

signals:
    void timezoneChanged();
    void timeChanged();

private slots:
    void tick();

private:
    QTimeZone m_tz;
    QTimer    m_timer;
    int       m_hours   = 0;
    int       m_minutes = 0;
    int       m_seconds = 0;
    QString   m_digital;
    QString   m_ampm;

    void update();
};
