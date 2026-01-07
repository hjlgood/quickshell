import Quickshell
import QtQuick
import QtQuick.Layouts
import "../colors"

PanelWindow {
    id: calendarWindow

    property var targetScreen
    property real anchorHeight: 0
    signal requestClose

    // Calendar Logic
    property var currentViewDate: new Date()
    property var today: new Date()

    function updateToday() {
        today = new Date();
    }

    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate();
    }
    function startDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay();
    }
    function prevMonth() {
        var d = new Date(currentViewDate);
        d.setMonth(d.getMonth() - 1);
        currentViewDate = d;
    }
    function nextMonth() {
        var d = new Date(currentViewDate);
        d.setMonth(d.getMonth() + 1);
        currentViewDate = d;
    }

    screen: targetScreen

    // Use a full-width transparent window to allow easy centering
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
    exclusiveZone: -1 // Don't push other windows

    MouseArea {
        id: globalClickDismissArea
        anchors.fill: parent
        onClicked: calendarWindow.requestClose()
    }

    Rectangle {
        id: calendarContent
        width: 320
        height: 300
        anchors.horizontalCenter: parent.horizontalCenter
        color: Colors.backgroundDarkWindow
        radius: 12

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Catch clicks on the menu itself
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Calendar Header
            RowLayout {
                Layout.fillWidth: true

                // Month/Year Text
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(calendarWindow.currentViewDate, "MMMM yyyy")
                    color: Colors.text
                    font.family: "RedHatDisplay"
                    font.pixelSize: 18
                    font.bold: true
                }

                // Navigation
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: mouseLeft.containsMouse ? Colors.backgroundLight : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "<"
                            color: Colors.text
                            font.bold: true
                        }
                        MouseArea {
                            id: mouseLeft
                            anchors.fill: parent
                            onClicked: calendarWindow.prevMonth()
                        }
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 5
                        color: mouseRight.containsMouse ? Colors.backgroundLight : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: ">"
                            color: Colors.text
                            font.bold: true
                        }
                        MouseArea {
                            id: mouseRight
                            anchors.fill: parent
                            onClicked: calendarWindow.nextMonth()
                        }
                    }
                }
            }

            // Days Grid
            GridLayout {
                columns: 7
                columnSpacing: 5
                rowSpacing: 5
                Layout.fillWidth: true

                Repeater {
                    model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    Text {
                        text: modelData
                        color: Colors.backgroundLight
                        font.family: "RedHatDisplay"
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Repeater {
                    model: calendarWindow.startDayOfMonth(calendarWindow.currentViewDate.getMonth(), calendarWindow.currentViewDate.getFullYear())
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.preferredHeight: 30
                    }
                }

                Repeater {
                    model: calendarWindow.daysInMonth(calendarWindow.currentViewDate.getMonth(), calendarWindow.currentViewDate.getFullYear())
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.preferredHeight: 35

                        property bool isToday: (index + 1) === calendarWindow.today.getDate() && calendarWindow.currentViewDate.getMonth() === calendarWindow.today.getMonth() && calendarWindow.currentViewDate.getFullYear() === calendarWindow.today.getFullYear()

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            radius: 15
                            color: parent.isToday ? Colors.accent : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            color: parent.isToday ? Colors.backgroundDark : Colors.text
                            font.family: "RedHatDisplay"
                            font.bold: parent.isToday
                        }
                    }
                }
            }
            Item {
                Layout.fillHeight: true
            } // Spacer
        }
    }
}
