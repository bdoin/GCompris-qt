/* GCompris - Note.qml
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
import "inter-note.js" as Activity

Item {
    id: draggedItem
    property string colorNote
    property real note
    Component.onCompleted: console.log("Note created=", note, colorNote)
    Rectangle {
        id: img
        color: colorNote
        height: background.height / 8.0
        width: ((background.width >= background.height) ? background.width : background.height) / 5.66
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
    }
    function destroy() {
        // Destroy this copy object on drop
        draggedItem.destroy();
    }
}
