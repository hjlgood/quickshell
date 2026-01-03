import QtQuick
import "../colors"

Rectangle {
    id: volumeRoot
    width: 36
    height: 25
    color: "transparent"

    property string iconPath: "../images/volume.svg"
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
            source: volumeRoot.iconPath
            width: 15
            height: 15
            sourceSize: Qt.size(16, 16)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            volumeRoot.clicked();
        }
    }
}
