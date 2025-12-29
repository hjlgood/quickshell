import "../colors"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: rootWofii

    // Geometry
    // width: 600 // REMOVED: Using anchors
    // height: 500 // REMOVED: Using anchors

    // Centering (naive logic, ideally handled by compositor or anchors if supported,
    // but LayerShell usually anchors to edges. We'll use anchors.centerIn: parent if possible
    // or just anchor to top and set margins for a "floating" look, or "layer: overlay" if available.)
    // Note: Standard LayerShell attaches to edges. To "center" a box, we make a fullscreen transparent window
    // and put the box in the middle.

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Keyboard Input
    focusable: true

    // Wayland Properties
    exclusiveZone: -1 // Ignore bounds
    // layer: Quickshell.Layer.Overlay // REMOVED: Property not found on PanelWindow

    // IPC Handler
    IpcHandler {
        target: "wofiiIPCHandle"
        function toggleWofii() {
            rootWofii.visible = !rootWofii.visible;
            if (rootWofii.visible) {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }
    }
    // List logic
    property var allApps: []
    property var filteredApps: []

    function updateList(query) {
        if (!query) {
            filteredApps = allApps;
        } else {
            var lower = query.toLowerCase();
            filteredApps = allApps.filter(function (app) {
                return app.name.toLowerCase().includes(lower) || app.exec.toLowerCase().includes(lower);
            });
        }
        appModel.clear();
        for (var i = 0; i < filteredApps.length; i++) {
            appModel.append(filteredApps[i]);
        }
        // appList.currentIndex = 0;
    }

    // Close on click outside (background)
    MouseArea {
        anchors.fill: parent
        onClicked: rootWofii.visible = false
        z: 0
    }

    // Main Container
    Rectangle {
        id: mainBox
        width: 600
        height: 600
        anchors.centerIn: parent
        radius: 12
        color: Colors.backgroundDark
        border.color: Colors.backgroundLight
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        } // Block click-through to background

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            z: 1 // Ensure content is above background MouseAreas

            // Search Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: Colors.backgroundLight
                radius: 8

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 15
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 18
                    color: Colors.text
                    clip: true
                    focus: true
                    selectByMouse: true // Allow clicking to place cursor
                    Keys.onPressed: event => {
                        // console.log("Wofii KeyBoard Event:", event.key, "Text:", event.text)
                        if (event.key === Qt.Key_PageDown) {
                            appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            appList.currentIndex = Math.max(0, appList.currentIndex - 5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            appList.currentIndex = 0;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            appList.currentIndex = appList.count - 1;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            appList.incrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            appList.decrementCurrentIndex();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            rootWofii.visible = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (appList.count > 0) {
                                var item = appList.model.get(appList.currentIndex);
                                runner.command = ["nohup", "sh", "-c", item.exec + " > /dev/null 2>&1 &"];
                                runner.running = true;
                                rootWofii.visible = false;
                            }
                            event.accepted = true;
                        }
                    }

                    onTextChanged: appList.model.filter(text)

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search Applications..."
                        color: Qt.rgba(0.92, 0.93, 0.96, 0.5)
                        visible: !parent.text && !parent.activeFocus
                        font.pixelSize: 18
                    }
                }
            }

            // List logic moved to rootWofii for scope safety

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5

                model: ListModel {
                    id: appModel
                }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 48
                    color: ListView.isCurrentItem || mouse.containsMouse ? Colors.backgroundLight : "transparent"
                    radius: 6

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            // Launch app
                            runner.command = ["nohup", "sh", "-c", model.exec + " > /dev/null 2>&1 &"]; // Detach
                            runner.running = true;
                            rootWofii.visible = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 15

                        // Icon (Simple colored box if no icon loader available, or try Quickshell logic if exists)
                        // For now just a colorful box based on name logic to be distinct
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 6
                            color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: (model.name || "?")[0]
                                color: Colors.backgroundDark
                                font.bold: true
                            }
                        }

                        Text {
                            text: model.name || "Unknown"
                            color: Colors.text
                            font.pixelSize: 16
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // App Loader Process
            Process {
                id: loader
                // Detailed command to find desktop files, grep Name and Exec, and format nicely
                // Format: Name|Exec
                // Logic: find paths -> grep Name/Exec -> awk/sed to join lines.
                // Simpler: grep -r ^Name= /usr/share/applications | head
                // Robust one-liner is tricky in QML string.
                // We will use a simpler approach: list filename, then read content? No too many processes.
                // Let's use a specialized find+awk.

                // Command explanation:
                // 1. find .desktop files
                // 2. cat them
                // 3. awk to parse Name= and Exec= blocks (assuming standard format)
                // 4. Output: Name|Exec

                // Actually 'grep -h' is safer.
                // We want only the FIRST Name and Exec in the file (Group Header problems?).
                // Usually Name/Exec are in [Desktop Entry].

                command: ["sh", "-c", "grep -E '^(Name|Exec)=' -r /usr/share/applications ~/.local/share/applications -h | awk '{ if($0 ~ /^Name=/) { name=substr($0, 6); } else if($0 ~ /^Exec=/) { exec=substr($0, 6); if(name != \"\") { print name \"|\" exec; name=\"\"; } } }'"]

                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        var output = this.text || "";
                        var lines = output.split("\n");
                        var tempApps = [];

                        for (var i = 0; i < lines.length; i++) {
                            var line = lines[i].trim();
                            if (!line)
                                continue;
                            var parts = line.split("|");
                            if (parts.length >= 2) {
                                var name = parts[0];
                                var exec = parts[1]; // Exec often has %u %F args, we should strip them for cleanliness or keep them? Shell handles them usually.

                                // Strip %u, %F...
                                exec = exec.replace(/ %[fFuUdi]/g, "");

                                tempApps.push({
                                    name: name,
                                    exec: exec
                                });
                            }
                        }

                        // Sort content
                        tempApps.sort(function (a, b) {
                            return a.name.localeCompare(b.name);
                        });

                        rootWofii.allApps = tempApps;
                        rootWofii.updateList("");
                    }
                }
            }

            // App Runner
            Process {
                id: runner
            }

            Connections {
                target: searchInput
                function onTextChanged() {
                    rootWofii.updateList(searchInput.text);
                }
            }
        }
    }

    Component.onCompleted: searchInput.forceActiveFocus()
}
