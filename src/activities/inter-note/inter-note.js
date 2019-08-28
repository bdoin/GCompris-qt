/* GCompris - inter-note.js
 *
 * Copyright (C) 2018 Bruno COUDOIN <bruno.coudoin@gcompris.net>
 *
 * Authors:
 *   Bruno COUDOIN (from an original idea of Mariano SANS)
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
.pragma library
.import QtQuick 2.6 as Quick
.import GCompris 1.0 as GCompris
.import "qrc:/gcompris/src/core/core.js" as Core

var currentLevel = 0
var numberOfLevel = 10
var resourceURL = "qrc:/gcompris/src/activities/inter-note/resource/"
var items

/**
* Stores configuration for each level.
* 'NotesInCorrectAnswers' contains no. of wagons in correct answer.
* 'memoryTime' contains time(in seconds) for memorizing the wagons.
* 'numberOfSubLevels' contains no. of sublevels in each level.
* 'columnsInHorizontalMode' contains no. of columns in a row of sampleZone in horizontal mode.
* 'columnsInVerticalMode' contains no. of columns in a row of sampleZone in vertical mode.
* 'nbOfNotes' number of notes to be displayed in sampleZone.
* 'noteInterval' number of notes to create in between each 'normal' notes
*/
var dataset = {
    "NotesToFind": [5, 7, 8, 10, 12, 15, 15, 16, 16, 16],
    "NotesInterval": [1, 0.5, 0.5, 0.25, 0.25, 0.2, 0.2, 0.2, 0.2, 0.2],
    "numberOfSubLevels": 3,
    "columnsInHorizontalMode": [3, 5, 3, 5, 3, 5, 3, 5, 3, 5],
    "columsInVerticalMode": [3, 4, 3, 4, 3, 4, 3, 4, 3, 4],
}

// Color have not particular meaning, just to ease the user to remember tested notes
var colorset = [
            "#ffdda1", "#ffc151", "#f8c537", "#edb230", "#e77728", "#f55536",
            "#c5a021", "#a4243b", "#d8c99b", "#d8973c", "#51a3a3", "#2f6690",
            "#d9dcd6", "#16425b", "#88a09e", "#d5a021", "#704c5e", "#b88c9e",
        ]

function start(items_) {
    items = items_
    currentLevel = 0
    items.score.numberOfSubLevels = dataset["numberOfSubLevels"];
    items.score.currentSubLevel = 1;
    initLevel()
}

function stop() {
}

function initLevel() {
    items.animateFlow.stop(); // Stops any previous animations
    items.listModel.clear();
    items.answerZone.currentIndex = 0;
    items.answerZone.selectedSwapIndex = -1;

    // Shuffle the colorset to make the game really random
    Core.shuffle(colorset);
    if(colorset.length < dataset["NotesToFind"][currentLevel]) {
        console.log("ERROR: INTER-NOTE: colorset is too small")
        return;
    }

    // Create the note lists and shuffle it
    var notes = [];
    for(var i=0; i<dataset["NotesToFind"][currentLevel]; i++) {
        notes[i] = 64 + dataset["NotesInterval"][currentLevel] * i;
    }
    Core.shuffle(notes);

    for(var i=0; i<dataset["NotesToFind"][currentLevel]; i++) {
        items.listModel.insert(i,
                               {
                                   "noteColor": colorset[i],
                                   "noteVal": notes[i]
                               });
    }

    items.bar.level = currentLevel + 1;
}

function nextLevel() {
    if(numberOfLevel <= ++currentLevel) {
        currentLevel = 0
    }
    items.score.currentSubLevel = 1;
    initLevel();
}

function previousLevel() {
    if(--currentLevel < 0) {
        currentLevel = numberOfLevel - 1
    }
    items.score.currentSubLevel = 1;
    initLevel();
}

function restoreLevel() {
    initLevel();
}

function nextSubLevel() {
    /* Sets up the next sublevel */
    items.score.currentSubLevel ++;
    if(items.score.currentSubLevel > dataset["numberOfSubLevels"]) {
        nextLevel();
    }
    else {
        initLevel();
    }
}

function checkAnswer() {
    /* Checks if the top level setup equals the solutions */
    var isSolution = true;
    var note = items.listModel.get(0).note;
    for (var index = 1; index < items.listModel.count; index++) {
        if(items.listModel.get(index).note < note) {
            isSolution = false;
            break;
        }
        note = items.listModel.get(index).note;
    }
    if(isSolution === true) {
        items.bonus.good("flower");
    }
    else {
        items.bonus.bad("flower");
    }
}
