#pragma once

#include <QObject>
#include <QString>

class ConfigReader : public QObject
{
    Q_OBJECT

public:
    explicit ConfigReader(QObject *parent = nullptr);

    QString timezoneLeft()  const { return m_tzLeft; }
    QString locationLeft()  const { return m_locLeft; }
    QString timezoneRight() const { return m_tzRight; }
    QString locationRight() const { return m_locRight; }

    void load(const QString &path = "/etc/world-clock/clock.conf");

private:
    QString m_tzLeft   = "Asia/Karachi";
    QString m_locLeft  = "اسلام آباد";
    QString m_tzRight  = "Asia/Riyadh";
    QString m_locRight = "مكة المكرمة";
};
