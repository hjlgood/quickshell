import Quickshell
import Quickshell.Io
import QtQuick
import "../colors"

Rectangle {
    id: powerRoot
    width: 36
    height: 25 // Matches panel height
    color: "transparent"

    property string iconPath: "../images/shutdown.svg"
    signal clicked

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: mouseArea.containsMouse ? Colors.backgroundLight : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Image {
            anchors.centerIn: parent
            source: powerRoot.iconPath
            width: 16
            height: 16
            sourceSize: Qt.size(16, 16)

            // Apply text color to icon if needed, or just keep it as is.
            // nord shutdown.svg is usually white/light.
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            powerRoot.clicked();
        }
    }
}
