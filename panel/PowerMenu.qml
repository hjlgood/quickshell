import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../colors"

PanelWindow {
    id: powerMenuWindow

    property var targetScreen
    property real anchorHeight: 0
    signal requestClose

    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    margins {
        top: anchorHeight + 10
    }
    color: "transparent"
    exclusiveZone: -1

    MouseArea {
        id: globalClickDismissArea
        anchors.fill: parent
        onClicked: powerMenuWindow.requestClose()
    }

    Rectangle {
        id: menuContent
        width: 200
        height: mainLayout.implicitHeight + mainLayout.anchors.margins * 2
        anchors.right: parent.right
        anchors.rightMargin: 20
        color: Colors.backgroundDarkWindow
        radius: 12

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Catch clicks on the menu itself
        }

        Process {
            id: powerProc
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 15
            spacing: 8

            PowerButton {
                text: "Lock"
                icon: "../images/lock.svg"
                onClicked: {
                    powerProc.command = ["sh", "-c", "hyprlock -c $HOME/.config/my_config/hypr/lockscreen.conf"];
                    powerProc.running = true;
                    powerMenuWindow.requestClose();
                }
            }

            PowerButton {
                text: "Logout"
                icon: "../images/logout.svg"
                onClicked: {
                    powerProc.command = ["hyprctl", "dispatch", "exit"];
                    powerProc.running = true;
                    powerMenuWindow.requestClose();
                }
            }

            PowerButton {
                text: "Suspend"
                icon: "../images/suspend.svg"
                onClicked: {
                    powerProc.command = ["systemctl", "suspend"];
                    powerProc.running = true;
                    powerMenuWindow.requestClose();
                }
            }

            PowerButton {
                text: "Reboot"
                icon: "../images/reboot.svg"
                onClicked: {
                    powerProc.command = ["systemctl", "reboot"];
                    powerProc.running = true;
                    powerMenuWindow.requestClose();
                }
            }

            PowerButton {
                text: "Shutdown"
                icon: "../images/shutdown.svg"
                onClicked: {
                    powerProc.command = ["systemctl", "poweroff"];
                    powerProc.running = true;
                    powerMenuWindow.requestClose();
                }
            }
        }
    }

    component PowerButton: Rectangle {
        id: btnRoot
        property string text: ""
        property string icon: ""
        signal clicked

        Layout.fillWidth: true
        height: 40
        radius: 8
        color: mouse.containsMouse ? Colors.backgroundLight : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 15

            Image {
                source: btnRoot.icon
                width: 20
                height: 20
                sourceSize: Qt.size(20, 20)
            }

            Text {
                text: btnRoot.text
                color: Colors.text
                font.family: "RedHatDisplay"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            } // Spacer
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.clicked()
        }
    }
}
