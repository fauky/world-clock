#include "configreader.h"
#include <QFile>
#include <QTextStream>
#include <QDebug>

ConfigReader::ConfigReader(QObject *parent) : QObject(parent) {}

void ConfigReader::load(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "[ConfigReader] Cannot open config file:" << path
                   << "- using built-in defaults.";
        return;
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();

        // Skip comments and blank lines
        if (line.startsWith('#') || line.isEmpty())
            continue;

        // Split on first '='
        int eq = line.indexOf('=');
        if (eq < 0) continue;

        QString key   = line.left(eq).trimmed();
        QString value = line.mid(eq + 1).trimmed();

        // Strip optional surrounding quotes
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith('\'') && value.endsWith('\''))) {
            value = value.mid(1, value.length() - 2);
        }

        if      (key == "TIMEZONE_LEFT")  m_tzLeft   = value;
        else if (key == "LOCATION_LEFT")  m_locLeft  = value;
        else if (key == "TIMEZONE_RIGHT") m_tzRight  = value;
        else if (key == "LOCATION_RIGHT") m_locRight = value;
    }
}
