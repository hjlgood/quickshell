import QtQuick
import QtQuick.Layouts
import "../colors"

Item {
    id: clockRoot
    implicitWidth: clockText.implicitWidth + 16
    implicitHeight: 25

    signal clicked

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: mouse.containsMouse ? Colors.backgroundLight : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Text {
            id: clockText
            anchors.centerIn: parent
            color: Colors.text
            font.family: "RedHatDisplay"
            font.pixelSize: 13
            font.weight: Font.Bold
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d, HH:mm")
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clockRoot.clicked();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockText.text = Qt.formatDateTime(new Date(), "dddd, MMMM d, HH:mm");
        }
    }
}
