/* GCompris - GSynth.cpp
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

#include "GSynth.h"
#include "generator.h"

#include <QDebug>

GSynth *GSynth::m_instance = nullptr;

GSynth::GSynth(QObject *parent) : QObject(parent)
{
    bufferSize = 8192;

    m_format.setSampleRate(22050);
    m_format.setChannelCount(1);
    m_format.setSampleSize(16);
    m_format.setCodec("audio/pcm");
    m_format.setByteOrder(QAudioFormat::LittleEndian);
    m_format.setSampleType(QAudioFormat::SignedInt);

    QAudioDeviceInfo info(QAudioDeviceInfo::defaultOutputDevice());
    if (!info.isFormatSupported(m_format)) {
        qWarning() << "Default format not supported - trying to use nearest";
        m_format = info.nearestFormat(m_format);
    }
    m_device = QAudioDeviceInfo::defaultOutputDevice();
    m_buffer = QByteArray(bufferSize, 0);

    m_audioOutput = new QAudioOutput(m_device, m_format, this);
    m_audioOutput->setBufferSize(bufferSize);
    m_generator   = new Generator(m_format, this);
    // todo Only start generator if musical activity, and stop it on exit (in main.qml, activity.isMusicalActivity)
    m_generator->setPreset(PresetCustom);
    m_generator->start();
    m_audioOutput->start(m_generator);
    m_audioOutput->setVolume(1);
}

GSynth::~GSynth() {
    m_audioOutput->stop();
    m_generator->stop();
    delete m_audioOutput;
    delete m_generator;
    
    auto i = m_timers.constBegin();
    while (i != m_timers.constEnd()) {
        delete i.value();
        ++i;
    }
}

void GSynth::generate(qreal note, int duration) {
    //test part...
    // Not being a real to give the possibilities to create note intervals.
    // We need to keep the m_timers with notes as int, 100 should be enough
    int note_int = static_cast<int>(note * 100);
    m_generator->noteOn(1, note, 255);
    if(!m_timers.contains(note_int)) {
        m_timers[note_int] = new QTimer();
        connect(m_timers[note_int], &QTimer::timeout, this,
                [this, note]() {
                    stopAudio(note);
                });
    }
    m_timers[note_int]->start(duration);
}

void GSynth::stopAudio(qreal note) {
    m_generator->noteOff(1, note);
}

QObject *GSynth::synthProvider(QQmlEngine *engine,
                               QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    GSynth* synth = getInstance();
    return synth;
}
