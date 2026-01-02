import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../colors"

Item {
    id: workspaceRoot
    implicitHeight: 25
    implicitWidth: wsRow.implicitWidth + 20

    property int activeWorkspaceId: 1
    property var workingWorkspaceIds: []
    property int maxWorkspaceId: 10

    // Polling Timer (1s)
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: workspaceProc.running = true
    }

    // Workspace Discovery Process
    Process {
        id: workspaceProc
        command: ["sh", "-c", "hyprctl activeworkspace -j; echo '===SPLIT==='; hyprctl workspaces -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = (this.text || "").trim();
                if (!txt)
                    return;
                var parts = txt.split("===SPLIT===");
                if (parts.length < 2)
                    return;
                try {
                    var activeJson = JSON.parse(parts[0]);
                    var activeId = activeJson.id;

                    var allJson = JSON.parse(parts[1]);
                    var ids = [];
                    var max = 0;

                    for (var i = 0; i < allJson.length; i++) {
                        var wid = allJson[i].id;
                        if (wid > 0) {
                            ids.push(wid);
                            if (wid > max)
                                max = wid;
                        }
                    }
                    if (activeId > max)
                        max = activeId;

                    workspaceRoot.activeWorkspaceId = activeId;
                    workspaceRoot.workingWorkspaceIds = ids;
                    workspaceRoot.maxWorkspaceId = max;
                } catch (e) {}
            }
        }
    }

    // Workspace Switch Process
    Process {
        id: workspaceSwitchProc
        command: []
    }

    Component.onCompleted: workspaceProc.running = true

    RowLayout {
        id: wsRow
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Repeater {
            model: 20
            Item {
                property int wsId: index + 1
                property bool inRange: wsId <= workspaceRoot.maxWorkspaceId
                property bool isActive: wsId === workspaceRoot.activeWorkspaceId
                property bool isOccupied: workspaceRoot.workingWorkspaceIds.indexOf(wsId) !== -1

                Layout.preferredWidth: inRange ? (isActive ? 24 : (isOccupied ? 12 : 8)) : 0
                Layout.preferredHeight: 4
                visible: Layout.preferredWidth > 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutQuint
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: isActive ? Colors.accent : (isOccupied ? Colors.text : Colors.backgroundLight)
                    opacity: inRange ? (isActive ? 1.0 : (isOccupied ? 0.7 : 0.4)) : 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: inRange
                    onClicked: {
                        workspaceSwitchProc.command = ["hyprctl", "dispatch", "workspace", wsId];
                        workspaceSwitchProc.running = true;
                    }
                }
            }
        }
    }
}
