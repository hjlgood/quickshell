import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic
import "../colors"

PanelWindow {
    id: volumeWindow

    property var targetScreen
    property real anchorHeight: 0
    signal requestClose

    property bool isMuted: false
    property string sinkName: "Loading..."
    property var availableSinks: []

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
        onClicked: volumeWindow.requestClose()
    }

    Rectangle {
        id: menuContent
        width: 300
        height: mainLayoutContainer.implicitHeight + mainLayoutContainer.anchors.margins * 2
        anchors.right: parent.right
        anchors.rightMargin: 60
        color: Colors.backgroundDarkWindow
        radius: 12

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Catch clicks on the menu itself
        }

        Timer {
            id: getVolumeTimer
            interval: 500
            running: true
            repeat: true
            onTriggered: {
                getVolumeProc.running = false;
                getVolumeProc.running = true;
                statusProc.running = false;
                statusProc.running = true;
            }
        }

        Process {
            id: statusProc
            command: ["sh", "-c", "wpctl status"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var txt = (this.text || "");
                    var sinksIdx = txt.indexOf("Sinks:");
                    var sourcesIdx = txt.indexOf("Sources:");

                    if (sinksIdx !== -1 && sourcesIdx !== -1 && sourcesIdx > sinksIdx) {
                        var sinksBlock = txt.substring(sinksIdx + 6, sourcesIdx);

                        // Parse individualNames
                        var names = [];
                        var regex = /(\d+\.\s*.*?)\s*\[vol:/g;
                        var match;
                        while ((match = regex.exec(sinksBlock)) !== null) {
                            names.push(match[1].trim());
                        }

                        volumeWindow.availableSinks = names;

                        // Also update the display name (active one has '*')
                        var activeMatch = sinksBlock.match(/\*\s*(\d+\.\s*.*?)\s*\[vol:/);
                        if (activeMatch) {
                            volumeWindow.sinkName = activeMatch[1].trim();
                        } else if (names.length > 0) {
                            volumeWindow.sinkName = names[0];
                        }
                    }
                    // console.log(volumeWindow.availableSinks);
                }
            }
        }

        Process {
            id: getVolumeProc
            command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    var txt = (this.text || "").trim();
                    if (!txt)
                        return;
                    try {
                        var data = txt.split(":");
                        var vol = parseFloat(data[1]) * 100;
                        var muted = txt.includes("[MUTED]");

                        if (!volSlider.pressed) {
                            volSlider.value = vol;
                        }
                        volumeWindow.isMuted = muted;
                    } catch (e) {}
                }
            }
        }

        Process {
            id: setVolumeProc
            command: []
        }

        Process {
            id: setMuteProc
            command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        }

        Process {
            id: setSinkProc
            command: []
        }

        ColumnLayout {
            id: mainLayoutContainer
            anchors.fill: parent
            anchors.margins: 15
            spacing: 12

            RowLayout {
                id: mainLayout
                Layout.fillWidth: true
                spacing: 15

                MouseArea {
                    width: 24
                    height: 24
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        setMuteProc.running = false;
                        setMuteProc.running = true;
                    }

                    Image {
                        id: muteIcon
                        anchors.fill: parent
                        source: volumeWindow.isMuted ? "../images/volume_muted.svg" : "../images/volume.svg"
                        sourceSize: Qt.size(24, 24)
                        opacity: 0.8

                        Behavior on source {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: muteIcon
                                    property: "opacity"
                                    to: 0
                                    duration: 100
                                }
                                PropertyAction {
                                    target: muteIcon
                                    property: "source"
                                }
                                NumberAnimation {
                                    target: muteIcon
                                    property: "opacity"
                                    to: 0.8
                                    duration: 200
                                }
                            }
                        }
                    }
                }

                Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    from: 0
                    to: 100
                    value: 50

                    onValueChanged: {
                        if (pressed) {
                            var volFloat = (value / 100).toFixed(2);
                            setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", volFloat];
                            setVolumeProc.running = false;
                            setVolumeProc.running = true;
                        }
                    }

                    background: Rectangle {
                        x: volSlider.leftPadding
                        y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 12
                        width: volSlider.availableWidth
                        height: implicitHeight
                        radius: 6
                        color: Colors.backgroundLight

                        Rectangle {
                            width: volSlider.visualPosition * parent.width
                            height: parent.height
                            color: Colors.green
                            radius: 6
                        }
                    }

                    handle: Item {
                        implicitWidth: 0
                        implicitHeight: 0
                    }
                }

                Text {
                    text: volumeWindow.isMuted ? "Muted" : Math.round(volSlider.value) + "%"
                    color: Colors.text
                    font.family: "RedHatDisplay"
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    Layout.preferredWidth: 35
                }
            }

            // Available Sinks List
            Repeater {
                model: volumeWindow.availableSinks
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: sinkRow.implicitHeight + 6
                    color: sinkMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                    radius: 6

                    MouseArea {
                        id: sinkMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var match = modelData.match(/^(\d+)\./);
                            if (match) {
                                setSinkProc.command = ["wpctl", "set-default", match[1]];
                                setSinkProc.running = false;
                                setSinkProc.running = true;
                            }
                        }
                    }

                    RowLayout {
                        id: sinkRow
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        property bool isActive: modelData === volumeWindow.sinkName
                        opacity: isActive ? 1.0 : 0.5

                        Image {
                            source: "../images/volume.svg"
                            width: 14
                            height: 14
                            sourceSize: Qt.size(14, 14)
                        }

                        Text {
                            text: modelData
                            color: Colors.text
                            font.family: "RedHatDisplay"
                            font.pixelSize: 11
                            font.italic: !isActive
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
