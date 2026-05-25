QT += quick core

CONFIG += c++14
TARGET = world-clock
TEMPLATE = app

# Qt Quick Controls 2 (Material style)
QT += quickcontrols2

SOURCES += \
    src/main.cpp \
    src/clockprovider.cpp \
    src/configreader.cpp

HEADERS += \
    src/clockprovider.h \
    src/configreader.h

RESOURCES += \
    qml/qml.qrc

# Deploy target directory for RPi
target.path = /opt/world-clock
INSTALLS += target
