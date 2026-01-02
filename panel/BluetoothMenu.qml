import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../colors"

PanelWindow {
    id: bluetoothWindow

    property var targetScreen
    property real anchorHeight: 0
    signal requestClose

    property var availableDevices: []
    property var scanResults: []

    onVisibleChanged: {
        if (visible) {
            infoProc.running = false;
            infoProc.running = true;
            scanProc.running = false;
            scanProc.running = true;
        }
    }

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
        onClicked: bluetoothWindow.requestClose()
    }

    Rectangle {
        id: menuContent
        width: 300
        height: mainLayout.implicitHeight + 30
        anchors.right: parent.right
        anchors.rightMargin: 10
        color: Colors.backgroundDarkWindow
        radius: 12

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Catch clicks on the menu itself
        }

        Timer {
            id: refreshTimer
            interval: 2000
            running: bluetoothWindow.visible
            repeat: true
            onTriggered: {
                infoProc.running = false;
                infoProc.running = true;
            }
        }

        Process {
            id: infoProc
            command: ["sh", "-c", "bluetoothctl info"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var txt = (this.text || "");
                    var devices = [];
                    var lines = txt.split("\n");
                    var currentDev = null;

                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.startsWith("Device ")) {
                            currentDev = {
                                name: "",
                                battery: "",
                                mac: line.split(" ")[1]
                            };
                            devices.push(currentDev);
                        } else if (line.startsWith("Name: ") || line.startsWith("Alias: ")) {
                            var name = line.split(": ")[1];
                            if (currentDev && !currentDev.name) {
                                currentDev.name = name;
                            }
                        } else if (line.includes("Battery Percentage:")) {
                            var batMatch = line.match(/\((\d+)\)/);
                            if (currentDev && batMatch) {
                                currentDev.battery = batMatch[1] + "%";
                            }
                        }
                    }

                    // Fallback for single device info if no "Device " header
                    if (devices.length === 0 && txt.includes("Name:")) {
                        var nameMatch = txt.match(/Name:\s*(.+)/);
                        var aliasMatch = txt.match(/Alias:\s*(.+)/);
                        var batMatch = txt.match(/Battery Percentage:.*\((\d+)\)/);
                        var macMatch = txt.match(/Device\s+([0-9A-F:]{17})/i);
                        var name = (nameMatch ? nameMatch[1] : (aliasMatch ? aliasMatch[1] : "Unknown"));
                        var battery = (batMatch ? batMatch[1] + "%" : "");
                        var mac = (macMatch ? macMatch[1] : "");
                        devices.push({
                            name: name,
                            battery: battery,
                            mac: mac
                        });
                    }

                    // Clean up: filter out devices with no name
                    bluetoothWindow.availableDevices = devices.filter(d => d.name);
                }
            }
        }

        Process {
            id: scanProc
            command: ["sh", "-c", "bluetoothctl --timeout 3 scan on > /dev/null 2>&1; bluetoothctl devices | cut -d ' ' -f 2 | xargs -I {} bluetoothctl info {}"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var txt = (this.text || "");
                    var found = [];
                    var lines = txt.split("\n");
                    var currentMac = "";

                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.startsWith("Device ")) {
                            currentMac = line.split(" ")[1];
                        } else if (line.startsWith("Name: ") || line.startsWith("Alias: ")) {
                            var name = line.split(": ")[1];
                            if (name && currentMac) {
                                // Check if it's already in availableDevices to avoid duplicates
                                var isPaired = false;
                                for (var j = 0; j < bluetoothWindow.availableDevices.length; j++) {
                                    if (bluetoothWindow.availableDevices[j].name === name) {
                                        isPaired = true;
                                        break;
                                    }
                                }
                                if (!isPaired && !found.find(d => d.mac === currentMac)) {
                                    found.push({
                                        name: name,
                                        mac: currentMac
                                    });
                                }
                            }
                        }
                    }
                    bluetoothWindow.scanResults = found;
                }
            }
        }

        Process {
            id: connectProc
            command: ["bluetoothctl", "connect"]
        }

        Process {
            id: removeProc
            command: ["bluetoothctl", "remove"]
        }

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            Text {
                text: "Bluetooth Devices"
                color: Colors.text
                font.family: "RedHatDisplay"
                font.pixelSize: 13
                font.weight: Font.Bold
                opacity: 0.8
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.text
                opacity: 0.1
            }

            Repeater {
                model: bluetoothWindow.availableDevices
                delegate: MouseArea {
                    Layout.fillWidth: true
                    height: 28
                    hoverEnabled: true

                    onClicked: {
                        if (modelData.mac) {
                            removeProc.command = ["bluetoothctl", "remove", modelData.mac];
                            removeProc.running = true;
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.text
                        opacity: parent.containsMouse ? 0.05 : 0
                        radius: 4
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Image {
                            source: "../images/bluetooth.svg"
                            width: 14
                            height: 14
                            sourceSize: Qt.size(14, 14)
                            opacity: 0.7
                        }

                        Text {
                            text: modelData.name
                            color: Colors.text
                            font.family: "RedHatDisplay"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.battery
                            color: Colors.text
                            font.family: "RedHatDisplay"
                            font.pixelSize: 11
                            opacity: 0.6
                            visible: modelData.battery !== ""
                        }
                    }
                }
            }

            Text {
                visible: bluetoothWindow.availableDevices.length === 0
                text: "No paired devices"
                color: Colors.text
                font.family: "RedHatDisplay"
                font.pixelSize: 11
                font.italic: true
                opacity: 0.5
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.text
                opacity: 0.1
                visible: bluetoothWindow.scanResults.length > 0 || scanProc.running
            }

            RowLayout {
                Layout.fillWidth: true
                visible: bluetoothWindow.scanResults.length > 0 || scanProc.running

                Text {
                    text: "Discovered Devices"
                    color: Colors.text
                    font.family: "RedHatDisplay"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    opacity: 0.6
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: scanProc.running
                    text: "Scanning..."
                    color: Colors.text
                    font.family: "RedHatDisplay"
                    font.pixelSize: 10
                    font.italic: true
                    opacity: 0.4
                }
            }

            Repeater {
                model: bluetoothWindow.scanResults
                delegate: MouseArea {
                    Layout.fillWidth: true
                    height: 24
                    hoverEnabled: true

                    onClicked: {
                        connectProc.command = ["bluetoothctl", "connect", modelData.mac];
                        connectProc.running = true;
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Colors.text
                        opacity: parent.containsMouse ? 0.05 : 0
                        radius: 4
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Image {
                            source: "../images/bluetooth.svg"
                            width: 12
                            height: 12
                            sourceSize: Qt.size(12, 12)
                            opacity: 0.5
                        }

                        Text {
                            text: modelData.name
                            color: Colors.text
                            font.family: "RedHatDisplay"
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            opacity: 0.7
                        }
                    }
                }
            }
        }
    }
}
