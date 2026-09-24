import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    signal closeRequested()

    property color accentCyan:   "#22D3EE"
    property color accentPurple: "#A78BFA"
    property color textPrimary:  "#F2F2F7"
    property color textDim:      "#8A8AA0"
    property color textMute:     "#55556A"
    property color bgPanel:      "#12121F"

    property string mode: "create"
    property int    editId: -1
    property string editCurrentName: ""

    property var icons: [
        { name: "heart",      color: "#E879F9" },
        { name: "fire",       color: "#FB923C" },
        { name: "star",       color: "#FBBF24" },
        { name: "moon",       color: "#8B5CF6" },
        { name: "sun",        color: "#FBBF24" },
        { name: "bolt",       color: "#FACC15" },
        { name: "music",      color: "#22D3EE" },
        { name: "headphones", color: "#22D3EE" },
        { name: "gym",        color: "#EF4444" },
        { name: "run",        color: "#F97316" },
        { name: "yoga",       color: "#4ADE80" },
        { name: "bike",       color: "#3B82F6" },
        { name: "game",       color: "#A78BFA" },
        { name: "ghost",      color: "#E5E7EB" },
        { name: "alien",      color: "#4ADE80" },
        { name: "coffee",     color: "#92400E" },
        { name: "sleep",      color: "#6366F1" },
        { name: "party",      color: "#F472B6" },
        { name: "rain",       color: "#60A5FA" },
        { name: "snow",       color: "#BAE6FD" },
        { name: "book",       color: "#FCD34D" },
        { name: "code",       color: "#22D3EE" },
        { name: "work",       color: "#94A3B8" },
        { name: "chill",      color: "#38BDF8" },
        { name: "vacation",   color: "#4ADE80" },
        { name: "romance",    color: "#F472B6" },
        { name: "sad",        color: "#94A3B8" },
        { name: "focus",      color: "#EF4444" },
        { name: "rocket",     color: "#F97316" },
        { name: "crown",      color: "#FBBF24" }
    ]

    property string selectedIcon: "music"
    property string selectedColor: "#22D3EE"

    function reset() {
        nameInput.text = mode === "edit" ? editCurrentName : "";
        selectedIcon = "music";
        selectedColor = "#22D3EE";
    }

    Component.onCompleted: reset()

    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        MouseArea { anchors.fill: parent }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 640)
        height: Math.min(parent.height - 80, 620)
        radius: 20
        color: "#0D0D16"
        border.color: root.accentCyan
        border.width: 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.accentCyan
            shadowBlur: 1.0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Text {
                    text: root.mode === "create" ? "New playlist" : "Edit playlist"
                    color: root.textPrimary
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: closeHover.hovered ? "#33F87171" : "#1AF87171"
                    border.color: "#66F87171"
                    border.width: 1
                    HoverHandler { id: closeHover }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#F87171"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: "NAME"
                    color: root.textMute
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.weight: Font.Bold
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: root.bgPanel
                    border.color: nameInput.activeFocus ? root.accentCyan : "#2A2A3A"
                    border.width: 1
                    TextField {
                        id: nameInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        placeholderText: "e.g., Chill Vibes, Workout Mix…"
                        placeholderTextColor: root.textMute
                        color: root.textPrimary
                        font.pixelSize: 15
                        background: null
                        selectByMouse: true
                    }
                }
            }

            Text {
                text: "CHOOSE AN ICON"
                color: root.textMute
                font.pixelSize: 10
                font.letterSpacing: 1.5
                font.weight: Font.Bold
                Layout.topMargin: 4
            }

            GridView {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                cellWidth: 68
                cellHeight: 68
                clip: true
                model: root.icons

                delegate: Item {
                    required property var modelData
                    width: 68
                    height: 68

                    Rectangle {
                        anchors.centerIn: parent
                        width: 56; height: 56
                        radius: 14
                        color: root.selectedIcon === modelData.name
                               ? modelData.color + "33"
                               : "#1A1A28"
                        border.color: root.selectedIcon === modelData.name
                                      ? modelData.color
                                      : "#2A2A3A"
                        border.width: root.selectedIcon === modelData.name ? 2 : 1

                        Image {
                            anchors.centerIn: parent
                            width: 36; height: 36
                            source: Qt.resolvedUrl("../assets/icons/playlists/" + modelData.name + ".svg")
                            sourceSize.width: 72
                            sourceSize.height: 72
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIcon = modelData.name;
                                root.selectedColor = modelData.color;
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Cancel"
                    focusPolicy: Qt.NoFocus
                    Layout.preferredHeight: 44
                    Layout.fillWidth: true
                    onClicked: root.closeRequested()
                    background: Rectangle {
                        radius: 10
                        color: cancelHover.hovered ? "#26FFFFFF" : "#1AFFFFFF"
                        border.color: "#33FFFFFF"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: root.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    HoverHandler { id: cancelHover }
                }

                Button {
                    text: root.mode === "create" ? "Create playlist" : "Save changes"
                    focusPolicy: Qt.NoFocus
                    Layout.preferredHeight: 44
                    Layout.fillWidth: true
                    enabled: nameInput.text.trim() !== ""

                    onClicked: {
                        var name = nameInput.text.trim();
                        if (name === "") return;
                        if (root.mode === "create") {
                            library.createPlaylist(name, root.selectedIcon, root.selectedColor);
                        } else {
                            library.renamePlaylist(root.editId, name);
                            library.updatePlaylistIcon(root.editId, root.selectedIcon, root.selectedColor);
                        }
                  root.closeRequested();
                    }

                    background: Rectangle {
                        radius: 10
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#40A78BFA" }
                            GradientStop { position: 1.0; color: "#4022D3EE" }
                        }
                        border.color: root.accentCyan
                        border.width: 1
                        opacity: parent.enabled ? 1 : 0.4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
