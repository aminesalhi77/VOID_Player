import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // Data — set by Main.qml
    property string artistName: ""
    property string trackTitle: ""
    property string albumName: ""
    property int durationSec: 0
    property int currentPositionMs: 0
    property string filePath: ""

    signal addLyricsRequested()
    signal refreshRequested()

    // Colors
    property color accentCyan:   "#22D3EE"
    property color accentPurple: "#A78BFA"
    property color textPrimary:  "#F2F2F7"
    property color textDim:      "#8A8AA0"
    property color textMute:     "#55556A"

    // Signal — user clicked a lyric line to seek
    signal seekRequested(int timeMs)

    // Fetch on track change
    onTrackTitleChanged: {
        if (trackTitle === "") return;

        // Priority 1: user-entered lyrics
        if (filePath !== "" && library.hasCustomLyrics(filePath)) {
            var txt = library.loadCustomLyrics(filePath);
            var synced = library.customLyricsSynced(filePath);
            lyrics.loadCustomText(txt, synced);
            return;
        }

        // Priority 2: cached auto-fetched lyrics
        if (filePath !== "" && library.hasCachedLyrics(filePath)) {
            var ct = library.loadCachedLyrics(filePath);
            var cs = library.cachedLyricsSynced(filePath);
            lyrics.loadCustomText(ct, cs);
            return;
        }

        // Priority 3: fetch from the internet
        lyrics.fetch(artistName, trackTitle, albumName, durationSec);
    }


    Connections {
        target: lyrics
        function onStatusChanged() {
            if (lyrics.status === "found") {
                root.saveLyricsToCache();
            }
        }
    }

    // Update highlight position from playback — hard binding
    Connections {
        target: playback
        function onPositionChanged() {
            lyrics.setPosition(playback.position);
        }
        function onTrackChanged() {
            lyrics.setPosition(0);
        }
    }

    // Refresh button (top-right of panel)
    Rectangle {
        id: refreshBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        width: 32; height: 32
        radius: 8
        z: 100
        color: refreshHover.hovered ? "#33A78BFA" : "#1AA78BFA"
        border.color: root.accentPurple
        border.width: 1
        Behavior on color { ColorAnimation { duration: 140 } }

        HoverHandler { id: refreshHover }

        Text {
            anchors.centerIn: parent
            text: "⟳"
            color: root.accentCyan
            font.pixelSize: 16
            font.weight: Font.Bold

            RotationAnimation on rotation {
                running: lyrics.status === "loading"
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 1000
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.refreshRequested()
        }
    }

    // Loading indicator
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        visible: lyrics.status === "loading" || lyrics.status === "idle"

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72; height: 72
            radius: 36
            color: "transparent"
            border.color: root.accentCyan
            border.width: 2
            opacity: 0.7
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.accentCyan
                shadowBlur: 1.0
            }

            SequentialAnimation on scale {
                running: root.visible && (lyrics.status === "loading" || lyrics.status === "idle")
                loops: Animation.Infinite
                NumberAnimation { to: 1.1; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.92; duration: 900; easing.type: Easing.InOutSine }
            }

            Text {
                anchors.centerIn: parent
                text: "♪"
                color: root.accentCyan
                font.pixelSize: 32
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: lyrics.status === "loading" ? "Fetching lyrics…" : "Waiting…"
            color: root.textDim
            font.pixelSize: 14
        }
    }

    // Not found state
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: lyrics.status === "notfound" || lyrics.status === "error"

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "♪"
            color: root.textMute
            font.pixelSize: 64
            opacity: 0.4
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: lyrics.status === "error" ? "Couldn't reach lyrics service" : "No lyrics found"
            color: root.textDim
            font.pixelSize: 16
            font.weight: Font.Medium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.trackTitle + "  ·  " + root.artistName
            color: root.textMute
            font.pixelSize: 12
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            text: "✎  Add lyrics manually"
            focusPolicy: Qt.NoFocus
            onClicked: root.addLyricsRequested()

            background: Rectangle {
                implicitWidth: 220
                implicitHeight: 42
                radius: 10
                color: addHover.hovered ? "#33A78BFA" : "#1AA78BFA"
                border.color: root.accentPurple
                border.width: 1
            }
            contentItem: Text {
                text: parent.text
                color: root.accentPurple
                font.pixelSize: 13
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            HoverHandler { id: addHover }
        }
    }

    // Lyrics list
    ListView {
        id: lyricsList
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 60
        anchors.bottomMargin: 60
        clip: true
        visible: lyrics.status === "found"
        model: lyrics.lines
        spacing: 12
        boundsBehavior: Flickable.StopAtBounds

        // Scroll to current line
        function scrollToCurrent() {
            if (lyrics.currentLine < 0) return;
            positionViewAtIndex(lyrics.currentLine, ListView.Center);
        }

        Connections {
            target: lyrics
            function onCurrentLineChanged() {
                if (lyrics.currentLine >= 0) {
                    lyricsList.positionViewAtIndex(lyrics.currentLine, ListView.Center);
                }
            }
            function onLinesChanged() {
                // Reset to top when lyrics change
                lyricsList.positionViewAtBeginning();
            }
        }

        // Smooth scroll behavior
        Behavior on contentY {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: lineItem
            required property var modelData
            required property int index

            width: lyricsList.width
            height: {
                var base = Math.max(48, textItem.implicitHeight + 20);
                return isCurrent ? base + 8 : base;
            }

            property bool isCurrent: index === lyrics.currentLine
            property bool isNear: Math.abs(index - lyrics.currentLine) <= 2
            property bool isSynced: lyrics.synced

            // Animate the height so the layout "breathes"
            Behavior on height {
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }

            // Slide the whole line slightly right when it's the current one
            transform: Translate {
                x: lineItem.isCurrent && lineItem.isSynced ? 12 : 0
                Behavior on x {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }
            }

            // Neon accent bar on the left of the current line
            Rectangle {
                id: accentBar
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height * 0.7
                radius: 1.5
                color: root.accentCyan

                opacity: lineItem.isCurrent && lineItem.isSynced ? 1.0 : 0.0
                scale: lineItem.isCurrent && lineItem.isSynced ? 1.0 : 0.3

                Behavior on opacity {
                    NumberAnimation {
                        duration: 340
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.6
                    }
                }

                layer.enabled: lineItem.isCurrent && lineItem.isSynced
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accentCyan
                    shadowBlur: 1.0
                }
            }

            // The text itself
            Text {
                id: textItem
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: accentBar.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                text: modelData.text
                color: {
                    if (!lineItem.isSynced) return root.textDim;
                    if (lineItem.isCurrent) return "#FFFFFF";
                    if (lineItem.isNear) return "#A0A0B8";
                    return root.textMute;
                }
                font.pixelSize: lineItem.isCurrent ? 24 : 17
                font.weight: lineItem.isCurrent ? Font.Bold : Font.Normal
                font.letterSpacing: lineItem.isCurrent ? 0.3 : 0
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                opacity: lineItem.isSynced
                       ? (lineItem.isCurrent ? 1.0 : (lineItem.isNear ? 0.75 : 0.35))
                       : 0.9

                // Scale pop on the current line
                scale: lineItem.isCurrent && lineItem.isSynced ? 1.0 : 0.98
                transformOrigin: Item.Left

                // Bright glow on the current line
                layer.enabled: lineItem.isCurrent && lineItem.isSynced
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accentCyan
                    shadowBlur: 1.2
                }

                Behavior on font.pixelSize {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.3
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 380
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation { duration: 380 }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 420
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: lineItem.isSynced ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: lineItem.isSynced
                onClicked: {
                    var ms = modelData.timeMs;
                    if (ms === undefined) ms = 0;
                    root.seekRequested(ms);
                }
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: lyricsList.count === 0
            text: "No lyrics available"
            color: root.textMute
            font.pixelSize: 14
        }
    }
}
