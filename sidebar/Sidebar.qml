import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic
import "../colors"

PanelWindow {
    id: rootWindow
    anchors {
        top: true
        bottom: true
        right: true
    }
    
    // Force to Monitor 1 (Index 0). Change [0] to [1] for the second monitor.
    screen: Quickshell.screens[1]

    // Dynamic Width: Physically resizing the window surface is the only reliable way 
    // to pass input through to underlying apps on Wayland.
    implicitWidth: windowWidth 
    property int windowWidth: 10
    
    // Timer to delay width collapse until fade animation finishes
    Timer {
        id: widthCollapseTimer
        interval: 350 // Slightly longer than opacity animation (300ms usually)
        onTriggered: windowWidth = 10
    }
    
    color: "transparent"

    // Wayland Properties
    exclusiveZone: -1
    
    // REMOVED: mask property (unreliable for clicks)

    // Nord Theme Colors: Loaded from Colors.qml

    // Logic
    property var currentViewDate: new Date()
    property bool isMuted: false
    property bool isCollapsed: true

    onIsCollapsedChanged: {
        if (!isCollapsed) {
            // Expand immediately to full width (safe large value) to capture clicks
            windowWidth = 5000
            widthCollapseTimer.stop()
        } else {
            // Delay shrinking width to allow fade out
            widthCollapseTimer.restart()
        }
    }

    function daysInMonth(month, year) { return new Date(year, month + 1, 0).getDate(); }
    function startDayOfMonth(month, year) { return new Date(year, month, 1).getDay(); }
    function prevMonth() { var d = new Date(currentViewDate); d.setMonth(d.getMonth() - 1); currentViewDate = d; }
    function nextMonth() { var d = new Date(currentViewDate); d.setMonth(d.getMonth() + 1); currentViewDate = d; }
    IpcHandler{
        id: root
        target: "sidebarIPCHandle"
        function toggleCollapse() { isCollapsed = !isCollapsed; }
    }

    Timer {
        id: collapseVolChangeTimer
        interval: 3000
        repeat: false
        onTriggered: isCollapsed = true
    }
    // Screen Edge Sensor (to expand)
    // Needs to stay at the RIGHT edge regardless of window content shifting
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 10 
        color: "transparent"
        z: 999
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (isCollapsed) {
                    isCollapsed = false;
                }
            }
        }
    }

    // Clipping Wrapper
    // Since Window can't clip, we use this Item to ensure clean cut-off during animation.
    Item {
        id: contentScope
        anchors.fill: parent
        clip: true 
        
        // Overlay MouseArea to detect "Click Outside"
        // Active only when expanded. Covers the entire window (5000px).
        // z: -1 Ensures it is behind the mainWidget content.
        MouseArea {
            anchors.fill: parent
            enabled: !isCollapsed
            z: -1
            onClicked: rootWindow.isCollapsed = true
        } 

        // Main Container
        Rectangle {
            id: mainWidget
            width: 360
            height: parent.height - 40 
            
            // FADE OUT LOGIC:
            // 1. Anchor to RIGHT (Screen Edge) so it doesn't move/slide when width shrinks.
            anchors.right: parent.right
            anchors.rightMargin: 20 
            anchors.verticalCenter: parent.verticalCenter
            
            // 2. Opacity Animation
            opacity: isCollapsed ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } } // REMOVED: Instant
            
            radius: 16
            color: Colors.backgroundDark
            border.color: Colors.backgroundLight
            border.width: 1

            // FIX: Enable Layering to render this complex item as a single texture.
            // This prevents "tearing" or internal jitter during the slide animation.
            layer.enabled: true
            layer.smooth: true

            // Blocker MouseArea: Swallows clicks on the sidebar itself so they don't close it
            MouseArea {
                anchors.fill: parent
                hoverEnabled: false
                onPressed: mouse.accepted = true
                onClicked: mouse.accepted = true
                z: -1 // Behind controls in mainWidget, but in front of Overlay (because mainWidget is in front of Overlay)
            }



        
        // REMOVED: Transform Translate. 
        // We rely on the window width shrinking from the left (anchored right) 
        // and 'clip: true' to create the "slide/wipe" visual effect.


        // Reusable Components
        component IconButton: Rectangle {
            id: root
            property string iconSource: ""
            property color baseColor: "transparent"
            property color hoverColor: "#ffffff"
            property real hoverOpacity: 0.2
            signal clicked()

            implicitWidth: 48; implicitHeight: 48; radius: 12
            color: mouse.containsMouse ? Qt.rgba(1,1,1, hoverOpacity) : baseColor

            Image {
                anchors.centerIn: parent
                source: root.iconSource
                width: 24; height: 24
                sourceSize: "24x24"
            }
            MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
        }

        component SmallIconButton: Rectangle {
            id: root
            property string iconSource: ""
            property color baseColor: "transparent"
            property color hoverColor: "#ffffff"
            property real hoverOpacity: 0.2
            property color defaultColor: Qt.rgba(0,0,0, 0.4) 
            signal clicked()

            implicitWidth: 32; implicitHeight: 32; radius: 8
            color: mouse.containsMouse ? Qt.rgba(1,1,1, hoverOpacity) : baseColor

            Image { 
                anchors.centerIn: parent
                source: root.iconSource
                width: 24; height: 24
                sourceSize: "24x24"
            }
            MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
        }

        // Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 30

            // 1. Clock (Larger 110px) (Top)
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0
                Text {
                    id: timeText
                    Layout.alignment: Qt.AlignHCenter
                    color: Colors.text
                    font.family: "RedHatDisplay" 
                    font.pixelSize: 110
                    font.weight: Font.Thin
                    text: Qt.formatTime(new Date(), "hh:mm")
                }
                Text {
                    id: dateText
                    Layout.alignment: Qt.AlignHCenter
                    color: Colors.text
                    font.family: "RedHatDisplay"
                    font.pixelSize: 18
                    text: Qt.formatDate(new Date(), "dddd, MMMM d, yyyy")
                }
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        var d = new Date();
                        timeText.text = Qt.formatTime(d, "hh:mm");
                        dateText.text = Qt.formatDate(d, "dddd, MMMM d, yyyy");
                    }
                }
            }
            
            // 2. Calendar
            ColumnLayout {
                Layout.fillWidth: true
                // Fixed height to prevent jumping (Header ~32 + spacing 10 + Grid ~ (6 * 34) ~ 204. Let's reserve ~260 safe space or strictly calculate)
                // Actually, just fixing the preferredHeight of this container is easier.
                // Layout.preferredHeight: 300 // Adjust as needed
                
                // Better approach: Reserve space for max 6 rows.
                // Row height 30 + spacing 4 = 34 per row. 6 rows = 204.
                // Header (32) + Spacing (10) + Weekdays (Text height ~20) + Spacing (10) approx.
                // Let's wrap the Grid in a fixed Item.
                 
                spacing: 10
                
                // Header
                RowLayout {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                    SmallIconButton { iconSource: "arrow_left.svg"; onClicked: prevMonth() }
                    Text {
                        text: Qt.formatDate(currentViewDate, "MMMM yyyy")
                        color: Colors.text; font.family: "RedHatDisplay"; font.pixelSize: 16; font.bold: true
                        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                    }
                    SmallIconButton { iconSource: "arrow_right.svg"; onClicked: nextMonth() }
                }

                // Days Container with Fixed Height
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250 // Sufficient for 6 rows + headers. 
                    // 30px * 6 + 4*5 spacing = 200px for grid body. plus header text. 250 is comfortable.
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        


                        // Days Grid
                        GridLayout {
                           columns: 7; rowSpacing: 4; columnSpacing: 4; Layout.fillWidth: true
                           
                           // Weekday Headers
                           Repeater { 
                               model: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
                               Text { 
                                   text: modelData
                                   color: Colors.backgroundLight
                                   font.family: "RedHatDisplay"
                                   Layout.fillWidth: true 
                                   horizontalAlignment: Text.AlignHCenter 
                               } 
                           }
                           
                           // Spacer for first day offset
                           Repeater { 
                               model: startDayOfMonth(currentViewDate.getMonth(), currentViewDate.getFullYear())
                               Item { width: 1; height: 1; Layout.fillWidth: true } 
                           }
                           
                           // Actual Days
                           Repeater {
                               model: daysInMonth(currentViewDate.getMonth(), currentViewDate.getFullYear())
                               Rectangle {
                                   Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 15
                                   property bool isToday: (index + 1) === new Date().getDate() && currentViewDate.getMonth() === new Date().getMonth()
                                   color: isToday ? Colors.accent : "transparent"
                                   Text { anchors.centerIn: parent; text: index + 1; color: parent.isToday ? Colors.backgroundDark : Colors.text; font.family: "RedHatDisplay" }
                               }
                           }
                        }
                        
                        // Spacer to fill remaining fixed height so content stays at top
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // // 3. Media Controls (Visible Buttons)
            // RowLayout {
            //     Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 20
            //     SmallIconButton { iconSource: "media_prev.svg"; onClicked: console.log("Prev") }
            //     SmallIconButton { iconSource: "media_play.svg"; onClicked: console.log("Play") }
            //     SmallIconButton { iconSource: "media_next.svg"; onClicked: console.log("Next") }
            // }
            
            // // 4. Notifications Popup
            // ColumnLayout {
            //     Layout.fillWidth: true
            //     spacing: 5
            //     visible: NotificationServer.notifications.length > 0 
            //     
            //     Text { text: "Notifications"; color: Colors.backgroundLight; font.pixelSize: 12 }
            //     
            //     ListView {
            //         Layout.fillWidth: true
            //         Layout.preferredHeight: 60 
            //         clip: true
            //         model: NotificationServer.notifications
            //         delegate: Rectangle {
            //             width: ListView.view.width
            //             height: 50
            //             color: Qt.rgba(0,0,0,0.2)
            //             radius: 8
            //             RowLayout {
            //                 anchors.fill: parent; anchors.margins: 10
            //                 ColumnLayout {
            //                     Text { text: model.modelData.summary; color: Colors.text; font.bold: true; font.pixelSize: 14 }
            //                     Text { text: model.modelData.body; color: Colors.text; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            //                 }
            //             }
            //         }
            //     }
            // }

            // // 5. Connectivity (Wifi/BT) - New Row
            // RowLayout {
            //     Layout.fillWidth: true
            //     Layout.alignment: Qt.AlignHCenter
            //     spacing: 20
            //     
            //     // Wifi Toggle
            //     Rectangle {
            //         width: 32; height: 32; radius: 8
            //         color: Qt.rgba(0,0,0,0.4)
            //         Image { anchors.centerIn: parent; source: "wifi.svg"; width: 16; height: 16; sourceSize: Qt.size(16,16) }
            //         MouseArea { anchors.fill: parent; onClicked: console.log("Toggle Wifi") }
            //     }

            //     // Bluetooth Toggle
            //     Rectangle {
            //         width: 32; height: 32; radius: 8
            //         color: Qt.rgba(0,0,0,0.4)
            //         Image { anchors.centerIn: parent; source: "bluetooth.svg"; width: 16; height: 16; sourceSize: Qt.size(16,16) }
            //         MouseArea { anchors.fill: parent; onClicked: console.log("Toggle BT") }
            //     }
            // }
            
            Item { Layout.fillHeight: true } // Spacer
            
            // 6. System Info (Bottom)
            ColumnLayout {
                id: systemInfo
                Layout.fillWidth: true
                spacing: 15
                
                property real cpuUsage: 0
                property real ramUsage: 0
                property real diskUsage: 0
                property int activeWorkspaceId: 1
                property var workingWorkspaceIds: []
                property int maxWorkspaceId: 10

                // Timers to trigger polling
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        cpuProc.running = false; cpuProc.running = true
                        ramProc.running = false; ramProc.running = true
                        diskProc.running = false; diskProc.running = true
                        if (!workspaceProc.running) workspaceProc.running = true
                    }
                }

                // CPU Process
                Process {
                    id: cpuProc
                    command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'"] 
                    // Note: $8 is usually 'id' (idle). 100 - idle = utilization. 
                    // Output: " 4.5" (float)
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var val = parseFloat((this.text || "0").trim())
                            if (!isNaN(val)) systemInfo.cpuUsage = val / 100.0 // Normalize to 0.0-1.0
                        }
                    }
                }

                // RAM Process
                Process {
                    id: ramProc
                    command: ["sh", "-c", "free | grep Mem | awk '{print $3/$2}'"]
                    // Output: "0.45" (ratio)
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var val = parseFloat((this.text || "0").trim())
                            if (!isNaN(val)) systemInfo.ramUsage = val
                        }
                    }
                }

                // Disk Process
                Process {
                    id: diskProc
                    command: ["sh", "-c", "df --output=pcent / | tail -n 1 | tr -d '%'"]
                    // Output: "45" (integer percent)
                    stdout: StdioCollector {
                        onStreamFinished: {
                            var val = parseFloat((this.text || "0").trim())
                            if (!isNaN(val)) systemInfo.diskUsage = val / 100.0
                        }
                    }
                }

                // Workspace Process
                Process {
                    id: workspaceProc
                    command: ["sh", "-c", "hyprctl activeworkspace -j; echo '===SPLIT==='; hyprctl workspaces -j"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                             var txt = (this.text || "").trim()
                             if (!txt) return
                             var parts = txt.split("===SPLIT===")
                             if (parts.length < 2) return

                             try {
                                 // Active Workspace
                                 var activeJson = JSON.parse(parts[0])
                                 var activeId = activeJson.id
                                 
                                 // All Workspaces
                                 var allJson = JSON.parse(parts[1])
                                 var ids = []
                                 var max = 10
                                 
                                 for (var i = 0; i < allJson.length; i++) {
                                     var wid = allJson[i].id
                                     if (wid > 0) { 
                                         ids.push(wid)
                                         if (wid > max) max = wid
                                     }
                                 }
                                 
                                 // If active workspace is somehow larger than max found (e.g. empty new workspace), ensure we show it
                                 if (activeId > max) max = activeId
                                 
                                 systemInfo.activeWorkspaceId = activeId
                                 systemInfo.workingWorkspaceIds = ids
                                 systemInfo.maxWorkspaceId = max
                             } catch (e) {
                                 // console.log("Workspace JSON parse error", e)
                             }
                        }
                    }
                }
                
                Component.onCompleted: {
                    cpuProc.running = true
                    ramProc.running = true
                    diskProc.running = true
                    workspaceProc.running = true
                }

                Process {
                    id: workspaceSwitchProc
                    command: []
                    onRunningChanged: {
                        if (!running && exitCode !== 0) {
                            console.error("Failed to switch workspace")
                        }
                    }
                }

                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    // Workspace Indicator
                    Repeater {
                       model: systemInfo.maxWorkspaceId
                       Rectangle {
                           Layout.fillWidth: true
                           Layout.preferredHeight: 6
                           radius: 3
                           
                           property int wsId: index + 1
                           property bool isActive: wsId === systemInfo.activeWorkspaceId
                           property bool isOccupied: systemInfo.workingWorkspaceIds.indexOf(wsId) !== -1
                           
                           // Active: Accent, Occupied: White/Text (dimmed), Empty: BackgroundLight (very dimmed)
                           color: isActive ? Colors.accent : (isOccupied ? Colors.text : Colors.backgroundLight)
                           opacity: isActive ? 1.0 : (isOccupied ? 0.5 : 0.3)
                           
                           Behavior on color { ColorAnimation { duration: 200 } }
                           Behavior on opacity { NumberAnimation { duration: 200 } }

                           MouseArea {
                               anchors.fill: parent
                               cursorShape: Qt.PointingHandCursor
                               onClicked: {
                                   workspaceSwitchProc.command = ["hyprctl", "dispatch", "workspace", wsId]
                                   workspaceSwitchProc.running = true
                               }
                           }
                       }
                    }
                }

                RowLayout {
                    Image { source: "cpu.svg"; sourceSize: Qt.size(24,24); Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 8; color: Colors.backgroundLight; radius: 4
                        Rectangle { 
                            width: parent.width * systemInfo.cpuUsage
                            height: parent.height; color: Colors.accent; radius: 4 
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                        }
                    }
                    Text { text: Math.round(systemInfo.cpuUsage * 100) + "%"; color: Colors.text; font.family: "RedHatDisplay"; font.pixelSize: 12; Layout.preferredWidth: 30 }
                }
                RowLayout {
                    Image { source: "ram.svg"; sourceSize: Qt.size(24,24); Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 8; color: Colors.backgroundLight; radius: 4
                        Rectangle { 
                            width: parent.width * systemInfo.ramUsage
                            height: parent.height; color: Colors.yellow; radius: 4 
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                        }
                    }
                    Text { text: Math.round(systemInfo.ramUsage * 100) + "%"; color: Colors.text; font.family: "RedHatDisplay"; font.pixelSize: 12; Layout.preferredWidth: 30 }
                }
                RowLayout {
                    Image { source: "disk.svg"; sourceSize: Qt.size(24,24); Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 8; color: Colors.backgroundLight; radius: 4
                        Rectangle { 
                            width: parent.width * systemInfo.diskUsage
                            height: parent.height; color: Colors.purple; radius: 4 
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                        }
                    }
                    Text { text: Math.round(systemInfo.diskUsage * 100) + "%"; color: Colors.text; font.family: "RedHatDisplay"; font.pixelSize: 12; Layout.preferredWidth: 30 }
                }

                RowLayout {
                    id: volRow
                    // spacing: 10 
                    
                    // Animated Mute Icon
                    MouseArea {
                        width: 24; height: 24 
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isMuted) {
                                isMuted = false
                            } else {
                                isMuted = true
                            }
                        }
                        
                        Image {
                            anchors.fill: parent
                            source: isMuted ? "volume_muted.svg" : "volume.svg"
                            sourceSize: Qt.size(24,24)
                            Behavior on source { SequentialAnimation {
                                NumberAnimation { target: parent; property: "opacity"; to: 0; duration: 100 }
                                PropertyAction { target: parent; property: "source" }
                                NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 200 }
                            }}
                        }
                    }
                    
                    Timer{
                        id: getVolumeTimer
                        interval: 500
                        running: true
                        repeat: true
                        onTriggered: {
                            getVolumeProc.running = false;
                            getVolumeProc.running = true;
                        }
                    }
                    // Logic for Volume
                    property real lastVolume: 50 // Default fallback
                    Process {
                        id: getVolumeProc
                        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: { 
                                var txt = (this.text || "").trim()
                                if (!txt) return
                                try {
                                    var data = txt.split(":")
                                    var vol = parseFloat(data[1] * 100)
                                    var muted = data[2]
                                    if (typeof vol !== "undefined") {
                                        if (!volSlider.pressed) {
                                            if (Math.abs(vol - volSlider.value) > 1 && rootWindow.isCollapsed == true) {
                                                rootWindow.isCollapsed = false
                                                collapseVolChangeTimer.restart()
                                            }
                                            volSlider.value = vol
                                            volRow.lastVolume = vol
                                        }
                                        rootWindow.isMuted = muted
                                    }
                                } catch (e) { }
                            }
                        }
                    }


                    // Process to SET volume
                    Process {
                        id: setVolumeProc
                        command: [] // Set dynamically
                    }

                     Slider {
                        id: volSlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8 
                        leftPadding: 0  
                        rightPadding: 0 
                        
                        from: 0; to: 100
                        value: 50 // Initial value, updated by getVolumeProc
                        
                        onValueChanged: {
                            if (!isMuted && pressed) { // Only set if user is interacting
                                parent.lastVolume = value
                                // Send dbus/shell command
                                var volFloat = (value / 100).toFixed(2)
                                setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", volFloat]
                                setVolumeProc.running = true
                            }
                        }

                        // Smooth animation
                        Behavior on value {
                            // enabled: !volSlider.pressed 
                            NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                        }


                        // Visuals
                        background: Rectangle {
                            height: 8
                            width: parent.availableWidth
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            radius: 4
                            color: Colors.backgroundLight
                            
                            Rectangle { 
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                color: Colors.green
                                radius: 4 
                            }
                        }
                        handle: Rectangle { 
                            x: parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 0; implicitHeight: 0 
                            color: "transparent" 
                        }
                    }
                    
                    // Text { text: "75%"; color: Colors.text; font.family: "RedHatDisplay"; font.pixelSize: 12; Layout.preferredWidth: 30 }
                    Text {
                        text: isMuted ? "Muted" : Math.round(volSlider.value) + "%"
                        color: Colors.text
                        font.family: "RedHatDisplay"
                        font.pixelSize: 12
                        Layout.preferredWidth: 30
                        //horizontalAlignment: Text.AlignRight
                    }
                }
            }


            // 7. Power Controls (Bottom)
            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                spacing: 10
                
                // Shared Process for Power Actions
                Process { 
                    id: powerProc
                    
                    // Debugging Output
                    stdout: StdioCollector {
                        onStreamFinished: console.log("PowerProc STDOUT:", this.text)
                    }
                    stderr: StdioCollector {
                        onStreamFinished: console.error("PowerProc STDERR:", this.text)
                    }
                    onRunningChanged: {
                        if (!running) {
                            console.log("PowerProc finished with exit code:", powerProc.exitCode)
                        }
                    }
                }

                IconButton{
                    iconSource: "collapse.svg" 
                    onClicked: root.toggleCollapse() 
                    baseColor: "transparent" // Removed background
                }

                // Lock Screen
                IconButton { 
                    iconSource: "lock.svg"
                    baseColor: "transparent"
                    onClicked: {
                        // FIX: Replace ~ with full path. Process does not expand ~
                        powerProc.command = ["sh", "-c", "hyprlock -c $HOME/.config/my_config/hypr/lockscreen.conf"]
                        powerProc.running = true
                    }
                }

                // Logout
                IconButton { 
                    iconSource: "logout.svg"
                    baseColor: "transparent"
                    onClicked: {
                        powerProc.command = ["hyprctl", "dispatch", "exit"]
                        powerProc.running = true
                    }
                }

                // Suspend
                IconButton { 
                    iconSource: "suspend.svg"
                    baseColor: "transparent"
                    onClicked: {
                        powerProc.command = ["systemctl", "suspend"]
                        powerProc.running = true
                    }
                }

                // Reboot
                IconButton { 
                    iconSource: "reboot.svg"
                    baseColor: "transparent" 
                    onClicked: {
                        powerProc.command = ["systemctl", "reboot"]
                        powerProc.running = true
                    }
                }

                // Shutdown
                IconButton { 
                    iconSource: "shutdown.svg"
                    baseColor: "transparent"
                    onClicked: {
                        powerProc.command = ["systemctl", "poweroff"]
                        powerProc.running = true
                    }
                }
            }
    } // End mainWidget (Actually Content Column)
        } // End mainWidget
    } // End Clipping Wrapper
} // End PanelWindow
