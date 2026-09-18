import QtQuick
import QtQuick.Controls

// Silent override — kills platform focus rings and selection highlights.
// Import this in Main.qml, and reference its style values where needed.
QtObject {
    id: kill

    // Neutral focus ring (never drawn, but if Qt insists, it's a soft grey)
    readonly property color focusRing: "#ffffff10"

    // Neutral selection/highlight
    readonly property color selection: "#ffffff10"
    readonly property color selectionText: "#f2f2f7"
}