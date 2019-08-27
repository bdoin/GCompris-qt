/* GCompris - railroad.qml
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
import QtQuick 2.6
import GCompris 1.0
import "../../core"
import "inter-note.js" as Activity

ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}
    property bool isHorizontal: background.width >= background.height

    pageComponent: Image {
        id: background
        source: Activity.resourceURL + "inter-note-bg.svg"
        sourceSize.height: background.height
        fillMode: Image.PreserveAspectCrop
        anchors.horizontalCenter: parent.horizontalCenter

        signal start
        signal stop

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            property Item main: activity.main
            property alias background: background
            property alias bar: bar
            property alias bonus: bonus
            property alias score: score
            property alias listModel: listModel
            property alias answerZone: answerZone
            property alias animateFlow: animateFlow
            property alias introMessage: introMessage
            property bool keyNavigationMode: false
        }

        onStart: { Activity.start(items) }
        onStop: { Activity.stop() }
        Keys.enabled: !animateFlow.running && !introMessage.visible
        Keys.onPressed: {
            items.keyNavigationMode = true;
            items.answerZone.handleKeys(event);
        }

        // Intro message
        IntroMessage {
            id: introMessage
            y: background.height / 4.7
            anchors {
                right: parent.right
                rightMargin: 5
                left: parent.left
                leftMargin: 5
            }
            z: score.z + 1
            onIntroDone: {
            }
            intro: [
                qsTr("TBD."),
            ]
        }

        // Answer Zone
        Rectangle {
            id: playArea
            width: background.width
            height: background.height * 0.8
            anchors.top: background.top
            color: 'transparent'
            z: 1

            GridView {
                id: answerZone
                cellWidth: width / listModel.count
                cellHeight: height
                width: parent.width
                height: parent.height
                anchors.top: parent.top
                interactive: false
                model: listModel

                delegate: Rectangle {
                    id: note
                    height: answerZone.cellHeight * 0.9
                    width: answerZone.cellWidth * 0.9
                    color: noteColor
                    property real noteValue: noteVal
                    function checkDrop(dragItem) {
                        // Checks the drop location of this note
                        var globalCoordinates = dragItem.mapToItem(answerZone, 0, 0)
                        var selectedSwapIndex = Math.round((globalCoordinates.x / answerZone.width) * listModel.count)
                        if(selectedSwapIndex > (listModel.count - 1)) {
                            // Handles index overflow
                            selectedSwapIndex = listModel.count - 1
                        } else if(selectedSwapIndex < 0) {
                            selectedSwapIndex = 0;
                        }
                        var min = Math.min(selectedSwapIndex, answerZone.currentIndex);
                        var max = Math.max(selectedSwapIndex, answerZone.currentIndex);
                        console.log("min max=", min, max);
                        items.listModel.move(min, max, 1);
                        items.listModel.move(max-1, min, 1);
                    }

                    MouseArea {
                        id: displayNoteMouseArea
                        enabled: !introMessage.visible
                        anchors.fill: parent
                        drag.axis: Drag.XAxis

                        onPressed: {
                            console.log("onPressed", index, note.noteValue, note.color)
                            items.keyNavigationMode = false;
                            GSynth.generate(note.noteValue, 400)
                            answerZone.currentIndex = index
                            answerZone.selectedSwapIndex = -1;
                        }
                        onPressAndHold: {
                            console.log("onPressedAndHold", index, note.noteValue, note.color, mouse.wasHeld)
                            if(mouse.wasHeld) {
                                items.keyNavigationMode = false;
                                drag.target = parent
                                parent.z = 100
                                answerZone.selectedSwapIndex = -1;

                            }
                        }
                        onReleased: {
                            console.log("onReleased", index, note.noteValue)
                            console.log("drag.target=", drag.target, drag.active)
                            if(drag.active) {
                                parent.z = 1
                                parent.checkDrop(drag.target)
                                parent.Drag.cancel()
                            }
                        }
                    }
                }

                onXChanged: {
                    if(answerZone.x >= background.width) {
                        animateFlow.stop();
                        listModel.clear();
                        items.memoryMode = true;
                    }
                }

                PropertyAnimation {
                    id: animateFlow
                    target: answerZone
                    properties: "x"
                    from: answerZone.x
                    to: background.width
                    duration: 4000
                    easing.type: Easing.InExpo
                    loops: 1
                    onStopped: answerZone.x = 2;
                }

                function handleKeys(event) {
                    if(event.key === Qt.Key_Down) {
                        answerZone.currentIndex = -1
                    }
                    if(event.key === Qt.Key_Up) {
                        answerZone.currentIndex = -1
                    }
                    if(event.key === Qt.Key_Left) {
                        answerZone.moveCurrentIndexLeft()
                    }
                    if(event.key === Qt.Key_Right) {
                        answerZone.moveCurrentIndexRight()
                    }
                    // Checks answer.
                    if((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                        Activity.checkAnswer();
                    }
                    // Swaps two note with help of Space/Enter keys.
                    if(event.key === Qt.Key_Space) {
                        if(selectedSwapIndex === -1 && listModel.count > 1) {
                            answerZone.selectedSwapIndex = answerZone.currentIndex;
                            swapHighlight.x = answerZone.currentItem.x;
                            swapHighlight.anchors.top = answerZone.top;
                            console.log("selection done", answerZone.selectedSwapIndex);
                        }
                        else if(answerZone.currentIndex != selectedSwapIndex && listModel.count > 1) {
                            var min = Math.min(selectedSwapIndex, answerZone.currentIndex);
                            var max = Math.max(selectedSwapIndex, answerZone.currentIndex);
                            items.listModel.move(min, max, 1);
                            items.listModel.move(max-1, min, 1);
                            answerZone.selectedSwapIndex = -1;
                        }
                    }
                }
                // variable for storing the index of notes to be swapped via key navigations.
                property int selectedSwapIndex: -1

                Keys.enabled: true
                focus: true
                keyNavigationWraps: true
                highlightRangeMode: GridView.ApplyRange
                highlight: Image {
                    source: "qrc:/gcompris/src/core/resource/apply.svg"
                    width: answerZone.cellWidth * 0.7
                    sourceSize.width: width
                    fillMode: Image.PreserveAspectFit
                    anchors.top: parent.top
                    anchors.topMargin: 100
                    z: 1000
                    visible: (!animateFlow.running) && items.keyNavigationMode
                    x: (visible && answerZone.currentItem) ? answerZone.currentItem.x : 0
                    y: (visible && answerZone.currentItem) ? answerZone.currentItem.y : 0
                    Behavior on x {
                        SpringAnimation {
                            spring: 3
                            damping: 0.2
                        }
                    }
                    Behavior on y {
                        SpringAnimation {
                            spring: 3
                            damping: 0.2
                        }
                    }
                }
                highlightFollowsCurrentItem: false
            }

            // Used to highlight a note selected for swaping via key navigations
            Image {
                id: swapHighlight
                source: "qrc:/gcompris/src/core/resource/bar_up.svg"
                width: answerZone.cellWidth * 0.7
                sourceSize.width: width
                fillMode: Image.PreserveAspectFit
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 100
                z: 1000
                visible: answerZone.selectedSwapIndex != -1 ? true : false
            }

            ListModel {
                id: listModel
            }
        }

        // Answer Submission button
        BarButton {
            id: okButton
            source: "qrc:/gcompris/src/core/resource/bar_ok.svg"
            height: score.height
            width: height
            sourceSize.width: width
            sourceSize.height: height
            anchors.top: score.top
            z: score.z
            anchors {
                right: score.left
                rightMargin: 10
            }
            ParticleSystemStarLoader {
                id: okButtonParticles
                clip: false
            }
            MouseArea {
                id: okButtonMouseArea
                anchors.fill: parent
                enabled: !animateFlow.running && listModel.count > 0
                onClicked: Activity.checkAnswer()
            }
        }

        DialogHelp {
            id: dialogHelp
            onClose: home()
        }

        Score {
            id: score
            height: bar.height * 0.8
            width: height
            anchors.top: parent.top
            anchors.topMargin: 10 * ApplicationInfo.ratio
            anchors.right: parent.right
            anchors.leftMargin: 10 * ApplicationInfo.ratio
            anchors.bottom: undefined
            anchors.left: undefined
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home | level }
            onHelpClicked: {
                displayDialog(dialogHelp)
            }
            z: introMessage.z
            onPreviousLevelClicked: Activity.previousLevel()
            onNextLevelClicked: Activity.nextLevel()
            onHomeClicked: activity.home()
        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(Activity.nextSubLevel)
        }
    }
}
