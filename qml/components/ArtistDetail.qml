import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    signal back()
    signal playTrack(int trackIndex)
    signal openNowPlaying()

    property string artistName: ""
    property string avatarUrl: ""
    property string artistImageUrl: ""
    property var tracks: []
    property bool listMode: false
    property int lastPlayedIndex: -1

    property color accentCyan:   "#22D3EE"
    property color accentPurple: "#A78BFA"
    property color accentPink:   "#E879F9"
    property color textPrimary:  "#F2F2F7"
    property color textDim:      "#8A8AA0"
    property color textMute:     "#55556A"
    property color bgPanel:      "#12121F"
    property color bgDeep:       "#0A0A14"

    readonly property int totalMinutes: {
        var ms = 0;
        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i].durationText || "0:00";
            var p = t.split(":");
            if (p.length === 2) ms += (parseInt(p[0]) * 60 + parseInt(p[1])) * 1000;
        }
        return Math.floor(ms / 60000);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ===== HEADER =====
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                spacing: 16

                Button {
                    text: "\u2190 Back"
                    focusPolicy: Qt.NoFocus
                    onClicked: root.back()

                    background: Rectangle {
                        implicitWidth: 82
                        implicitHeight: 36
                        radius: 10
                        color: backHover.hovered ? "#26FFFFFF" : "#1AFFFFFF"
                        border.color: "#33A78BFA"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: root.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    HoverHandler { id: backHover }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: root.artistName
                        color: root.textPrimary
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.tracks.length + " track"
                              + (root.tracks.length === 1 ? "" : "s")
                              + "  \u00B7  " + root.totalMinutes + " min"
                        color: root.textDim
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 44; height: 44
                    radius: 12
                    color: toggleHover.hovered ? "#26A78BFA" : "#1AA78BFA"
                    border.color: root.accentPurple
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: toggleHover }

                    Text {
                        anchors.centerIn: parent
                        text: root.listMode ? "\u2261" : "\u25A6"
                        color: root.accentCyan
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.listMode = !root.listMode
                    }
                }
            }
        }

        // ===== CONTENT =====
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.bottomMargin: 24
            clip: true

            // ---- GRID MODE ----
            RowLayout {
                anchors.fill: parent
                spacing: 24
                visible: !root.listMode
                opacity: !root.listMode ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }

                // LEFT: big round avatar + Play all
                ColumnLayout {
                    Layout.preferredWidth: 280
                    Layout.minimumWidth: 280
                    Layout.maximumWidth: 280
                    Layout.alignment: Qt.AlignTop
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 280
                        Layout.preferredHeight: 280
                        radius: 140
                        color: root.bgPanel
                        clip: true
                        border.width: 3
                        border.color: root.accentPurple

                        SequentialAnimation on border.color {
                            running: true
                            loops: Animation.Infinite
                            ColorAnimation { to: "#A78BFA"; duration: 2600 }
                            ColorAnimation { to: "#22D3EE"; duration: 2600 }
                            ColorAnimation { to: "#E879F9"; duration: 2600 }
                            ColorAnimation { to: "#A78BFA"; duration: 2600 }
                        }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.accentPurple
                            shadowBlur: 0.9
                        }

                        Image {
                            anchors.fill: parent
                            source: root.avatarUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: root.avatarUrl !== ""
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: avatarMask
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: root.avatarUrl === ""
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#1A22D3EE" }
                                GradientStop { position: 1.0; color: "#33A78BFA" }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: root.artistName.charAt(0).toUpperCase()
                            color: "#FFFFFF"
                            font.pixelSize: 96
                            font.weight: Font.Bold
                            visible: root.avatarUrl === ""
                        }
                    }

                    Item {
                        id: avatarMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: 280
                            height: 280
                            radius: 140
                            color: "white"
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        text: "\u25B6   Play all"
                        focusPolicy: Qt.NoFocus
                        enabled: root.tracks.length > 0
                        onClicked: {
                            if (root.tracks.length > 0) root.playTrack(0);
                        }
                        background: Rectangle {
                            radius: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#40A78BFA" }
                                GradientStop { position: 1.0; color: "#4022D3EE" }
                            }
                            border.color: root.accentCyan
                            border.width: 1.5
                            opacity: parent.enabled ? 1.0 : 0.4
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

                // RIGHT: song grid
                GridView {
                    id: artistGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 180
                    cellHeight: 200
                    model: root.tracks

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: 180
                        height: 200

                        opacity: 0
                        scale: 0.92
                        Component.onCompleted: { opacity = 1; scale = 1; }
                        Behavior on opacity { NumberAnimation { duration: 240 } }
                        Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: songCard
                            anchors.centerIn: parent
                            width: 168
                            height: 188
                            radius: 12
                            color: "#1A1A28"
                            border.width: 2
                            border.color: root.accentCyan

                            property bool hovered: false
                            scale: hovered ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            SequentialAnimation on border.color {
                                running: true
                                loops: Animation.Infinite
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                                ColorAnimation { to: "#A78BFA"; duration: 2600 }
                                ColorAnimation { to: "#E879F9"; duration: 2600 }
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                            }

                            layer.enabled: hovered
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: root.accentCyan
                                shadowBlur: 0.8
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 96
                                    radius: 8
                                    color: root.bgPanel
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.coverUrl
                                        fillMode: Image.PreserveAspectCrop
                                        visible: modelData.coverUrl !== ""
                                        asynchronous: true
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: modelData.coverUrl === ""
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "#1A22D3EE" }
                                            GradientStop { position: 1.0; color: "#33A78BFA" }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u266A"
                                        color: "#FFFFFF"
                                        font.pixelSize: 32
                                        visible: modelData.coverUrl === ""
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: root.textPrimary
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.album
                                    color: root.textDim
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.durationText
                                    color: root.textMute
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono"
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            // Hover play overlay
                            Rectangle {
                                anchors.centerIn: parent
                                width: 56; height: 56
                                radius: 28
                                z: 10
                                visible: songCard.hovered
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#4022D3EE" }
                                    GradientStop { position: 1.0; color: "#40A78BFA" }
                                }
                                border.color: root.accentCyan
                                border.width: 2
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: root.accentCyan
                                    shadowBlur: 1.0
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u25B6"
                                    color: "#FFFFFF"
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: songCard.hovered = true
                                onExited: songCard.hovered = false
                                onClicked: {
                                    var libIdx = modelData.index;
                                    if (root.lastPlayedIndex === libIdx && playback.currentIndex === libIdx) {
                                        root.openNowPlaying();
                                    } else {
                                        root.playTrack(index);
                                        root.lastPlayedIndex = libIdx;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- LIST MODE ----
            ListView {
                id: artistList
                anchors.fill: parent
                clip: true
                visible: root.listMode
                opacity: root.listMode ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                spacing: 4
                model: root.tracks

                header: Rectangle {
                    width: artistList.width
                    height: 190
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 20

                        Rectangle {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 160
                            Layout.alignment: Qt.AlignVCenter
                            radius: 80
                            color: root.bgPanel
                            clip: true
                            border.color: root.accentPurple
                            border.width: 3

                            Image {
                                id: listAvatarImg
                                anchors.fill: parent
                                anchors.margins: -45
                                source: root.artistImageUrl !== "" ? root.artistImageUrl : root.avatarUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: source !== ""
                                asynchronous: true
                                sourceSize.width: 480
                                sourceSize.height: 480
                                mipmap: true
                                smooth: true
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: listAvatarMask
                                }
                            }

                            Item {
                                id: listAvatarMask
                                anchors.fill: parent
                                visible: false
                                layer.enabled: true
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 80
                                    color: "white"
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: root.avatarUrl === ""
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#1A22D3EE" }
                                    GradientStop { position: 1.0; color: "#33A78BFA" }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: root.artistName.charAt(0).toUpperCase()
                                color: "#FFFFFF"
                                font.pixelSize: 60
                                font.weight: Font.Bold
                                visible: root.avatarUrl === ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 10

                            Text {
                                text: root.artistName
                                color: root.textPrimary
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: root.tracks.length + " tracks  \u00B7  " + root.totalMinutes + " min"
                                color: root.textDim
                                font.pixelSize: 14
                            }
                            Button {
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 42
                                text: "\u25B6 Play all"
                                focusPolicy: Qt.NoFocus
                                onClicked: {
                                    if (root.tracks.length > 0) root.playTrack(0);
                                }
                                background: Rectangle {
                                    radius: 10
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#40A78BFA" }
                                        GradientStop { position: 1.0; color: "#4022D3EE" }
                                    }
                                    border.color: root.accentCyan
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "#FFFFFF"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: artistList.width
                    height: 56
                    radius: 10
                    color: rowHover.hovered ? "#1AFFFFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }

                    HoverHandler { id: rowHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var libIdx = modelData.index;
                            if (root.lastPlayedIndex === libIdx && playback.currentIndex === libIdx) {
                                root.openNowPlaying();
                            } else {
                                root.playTrack(index);
                                root.lastPlayedIndex = libIdx;
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: (index + 1)
                            color: root.textMute
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                            Layout.preferredWidth: 28
                            horizontalAlignment: Text.AlignRight
                        }

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 6
                            color: root.bgPanel
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: modelData.coverUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.coverUrl !== ""
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\u266A"
                                color: root.accentCyan
                                font.pixelSize: 14
                                visible: modelData.coverUrl === ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: root.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.album
                                color: root.textDim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.durationText
                            color: root.textDim
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                        }
                    }
                }
            }
        }
    }

}
