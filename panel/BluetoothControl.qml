import QtQuick
import "../colors"

Rectangle {
    id: bluetoothRoot
    width: 36
    height: 25
    color: "transparent"

    property string iconPath: "../images/bluetooth.svg"
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
            source: bluetoothRoot.iconPath
            width: 13
            height: 13
            sourceSize: Qt.size(16, 16)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            bluetoothRoot.clicked();
        }
    }
}
