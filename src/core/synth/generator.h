/* miniSynth - A Simple Software Synthesizer
   Copyright (C) 2015 Ville Räisänen <vsr at vsr.name>

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#ifndef GENERATOR_H
#define GENERATOR_H

#include <QAudioDeviceInfo>
#include <QAudioOutput>
#include <QByteArray>
#include <QIODevice>

#include <QMutex>
#include <QList>
#include <QMutableListIterator>

#include "linearSynthesis.h"
#include "modulation.h"
#include "ADSRenvelope.h"
#include "preset.h"

// The state of each active note is described with an Wave object. Wave
// objects are assembled into the QList<Wave> waveList and removed once
// they reach the state STATE_OFF.

class Wave {
public:
    enum {STATE_OFF, STATE_ATTACK, STATE_DECAY, STATE_RELEASE};
    qreal note;
    unsigned char vel, state;
    qreal state_age, age;
    ADSREnvelope env;
};

// The synthesizer is implemented as a QIODevice and is connected to
// a QAudioOutput in mainWindow.cpp. QAudioOutput reads data from the
// synthersizer using the function readData(data, size). readData
// returns maximum of 2048 samples generated with generateData(len).

class Generator : public QIODevice {
    Q_OBJECT
public:
    explicit Generator(const QAudioFormat &_format, QObject *parent = 0);
    ~Generator();

    void start    ();
    void stop     ();
    void setState ();

    void addWave (qreal note, unsigned char vel);

    qint64 readData(char *data, qint64 len);
    qint64 writeData(const char *data, qint64 len);
    qint64 bytesAvailable() const;

    void generateData(qint64 len);

public slots:
    void noteOn   (unsigned char chan, qreal note, unsigned char vel);
    void noteOff  (unsigned char chan, qreal note);

    // Slots for manipulation of the current patch.
    void setMode      (unsigned int _mode);
    void setTimbre    (QVector<int> &amplitudes, QVector<int> &phases);
    void setEnvelope  (ADSREnvelope &env);
    void setModulation(Modulation &modulation);
    void setPreset    (Preset &preset);
    
private:
    QAudioFormat format;
    QByteArray m_buffer;

    // State of the synthesizer
    qreal curtime;
    QList<Wave> waveList;

    // Parameters of the current patch
    LinearSynthesis *linSyn;
    ADSREnvelope     defaultEnv;
    Modulation       mod;
    Waveform        *mod_waveform;

    static const int m_samplingRate = 22050;
    static const int maxUsedBytes = 2048;
    
    qreal *synthData;
    
    QMutex m_lock;
};

#endif // GENERATOR_H
