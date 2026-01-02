import Quickshell
import QtQuick
import QtQuick.Layouts
import "../colors"

QtObject {
    id: panelRoot

    property bool calendarVisible: false
    property bool powerMenuVisible: false
    property bool volumeMenuVisible: false
    property bool bluetoothMenuVisible: false

    property PanelWindow panel: PanelWindow {
        id: root
        anchors {
            top: true
            left: true
            right: true
        }

        // Panel properties
        implicitHeight: 25
        screen: Quickshell.screens[1]
        color: "transparent"

        // Clock properties
        Rectangle {
            anchors.fill: parent
            color: Colors.backgroundDark

            Workspace {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Clock {
                id: clock
                anchors.centerIn: parent
                onClicked: {
                    panelRoot.calendarVisible = !panelRoot.calendarVisible;
                }
            }

            VolumeControl {
                id: volumeControl
                anchors.right: bluetoothControl.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: panelRoot.volumeMenuVisible = !panelRoot.volumeMenuVisible
            }

            BluetoothControl {
                id: bluetoothControl
                anchors.right: powerControl.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: panelRoot.bluetoothMenuVisible = !panelRoot.bluetoothMenuVisible
            }

            PowerControl {
                id: powerControl
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: panelRoot.powerMenuVisible = !panelRoot.powerMenuVisible
            }
        }
    }

    // Calendar properties
    property Calendar calendar: Calendar {
        id: calendarPopup
        visible: panelRoot.calendarVisible
        targetScreen: panelRoot.panel.screen
        anchorHeight: panelRoot.panel.height
        onRequestClose: panelRoot.calendarVisible = false
    }

    // Power Menu properties
    property PowerMenu powerMenu: PowerMenu {
        id: powerMenuPopup
        visible: panelRoot.powerMenuVisible
        targetScreen: panelRoot.panel.screen
        anchorHeight: panelRoot.panel.height
        onRequestClose: panelRoot.powerMenuVisible = false
    }

    // Volume Menu properties
    property VolumeMenu volumeMenu: VolumeMenu {
        id: volumeMenuPopup
        visible: panelRoot.volumeMenuVisible
        targetScreen: panelRoot.panel.screen
        anchorHeight: panelRoot.panel.height
        onRequestClose: panelRoot.volumeMenuVisible = false
    }

    // Bluetooth Menu properties
    property BluetoothMenu bluetoothMenu: BluetoothMenu {
        id: bluetoothMenuPopup
        visible: panelRoot.bluetoothMenuVisible
        targetScreen: panelRoot.panel.screen
        anchorHeight: panelRoot.panel.height
        onRequestClose: panelRoot.bluetoothMenuVisible = false
    }
}
