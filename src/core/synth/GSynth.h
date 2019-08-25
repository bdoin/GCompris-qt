/* GCompris - GSynth.h
 *
 * Copyright (C) 2018 Timothée Giet <animtim@gmail.com>
 *
 * Authors:
 *   Johnny Jazeix <jazeix@gmail.com>
 *   Timothée Giet <animtim@gmail.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, see <https://www.gnu.org/licenses/>.
 */
#ifndef GSYNTH_H
#define GSYNTH_H

#include <QAudioDeviceInfo>
#include <QAudioOutput>
#include <QTimer>
#include <QQmlEngine>
#include "preset.h"

class Generator;

class GSynth : public QObject
{
    Q_OBJECT

public:
    explicit GSynth(QObject *parent = 0);
    virtual ~GSynth();

    /**
     * Generate a note and start the corresponding timer
     *  to stop it at "duration" ms.
     *
     * @param note note to play
     * @param duration how much time the note needs to be played
     */
    Q_INVOKABLE void generate(qreal note, int duration);

    static GSynth *getInstance() {
        if(!m_instance) {
            m_instance = new GSynth();
        }
        return m_instance;
    }
    static QObject *synthProvider(QQmlEngine *engine,
                                  QJSEngine *scriptEngine);

protected:
    static GSynth *m_instance;

private slots:
    void stopAudio(qreal note);

private:
    unsigned int bufferSize;

    Generator        *m_generator;
    QAudioDeviceInfo  m_device;
    QAudioFormat      m_format;
    QByteArray        m_buffer;
    QAudioOutput     *m_audioOutput;
    QMap<int, QTimer *> m_timers;
    
    Preset PresetCustom;
};

#endif // GSYNTH_H
 
