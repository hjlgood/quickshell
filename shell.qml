import Quickshell
import QtQuick 2.15

// 1. Import the components folder relative to this file
// import "./sidebar/"
import "./wofii/"
import "./pp/"
import "./panel/"

QtObject {
    property var panel: Panel {}
    // property var sidebar: Sidebar {}
    property var wofii: Wofii {
        visible: false
    }

    // property var pp: Pp {}
}
