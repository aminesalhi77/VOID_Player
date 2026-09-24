import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    signal addLyricsRequested()
    signal refreshRequested()
    signal seekRequested(int timeMs)

    property string artistName: ""
    property string trackTitle: ""
    property string albumName: ""
    property int durationSec: 0
    property int currentPositionMs: 0
    property string filePath: ""

    property color accentCyan:   "#22D3EE"
    property color accentPurple: "#A78BFA"
    property color textPrimary:  "#F2F2F7"
    property color textDim:      "#8A8AA0"
    property color textMute:     "#55556A"

    // ============ HELPERS ============
    function getLineColor(synced, current, near) {
        if (!synced) return root.textDim;
        if (current) return root.textPrimary;
        if (near) return "#B0B0C0";
        return root.textMute;
    }

    // ============ AUTO TRIGGER on track change ============
    onFilePathChanged: {
        if (filePath !== "") {
            lyrics.clear();
            trackChangeDebounce.restart();
        }
    }

    Timer {
        id: trackChangeDebounce
        interval: 40
        repeat: false
        onTriggered: loadLyricsForTrack()
    }

    // Poll position every 200ms → drives the highlight.
    // More reliable than Connections on context properties.
    Timer {
        id: positionPoller
        interval: 200
        repeat: true
        running: playback.currentIndex >= 0
        onTriggered: {
            lyrics.setPosition(playback.position);
        }
    }

    Connections {
        target: playback
        function onTrackChanged() {
            lyrics.clear();
            trackChangeDebounce.restart();
        }
    }

    // ============ ACTIONS ============
    function loadLyricsForTrack() {
        var fp = playback.filePath;
        if (fp === "") return;

        if (library.hasCustomLyrics(fp)) {
            var txt = library.loadCustomLyrics(fp);
            var synced = library.customLyricsSynced(fp);
            lyrics.loadCustomText(txt, synced);
            return;
        }

        lyrics.fetchForFile(fp,
                             playback.artist,
                             playback.title,
                             playback.album,
                             Math.floor(playback.duration / 1000));
    }

    function saveLyricsToCache() {
        var fp = playback.filePath;
        if (fp === "") return;
        if (lyrics.lines.length === 0) return;

        var text = "";
        for (var i = 0; i < lyrics.lines.length; i++) {
            var l = lyrics.lines[i];
            if (lyrics.synced && l.timeMs > 0) {
                var s = l.timeMs / 1000.0;
                var m = Math.floor(s / 60);
                var sec = s - m * 60;
                var minStr = (m < 10 ? "0" : "") + m;
                var secStr = (sec < 10 ? "0" : "") + sec.toFixed(2);
                text += "[" + minStr + ":" + secStr + "] " + l.text + "\n";
            } else {
                text += l.text + "\n";
            }
        }
        var src = lyrics.source === "" ? "manual" : lyrics.source;
        library.saveCachedLyrics(fp, text, lyrics.synced, src);
    }

    // ============ TOP-RIGHT BUTTONS ============
    RowLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        spacing: 6
        z: 100

        // ---- Save to DB (C) ----
        Rectangle {
            id: saveBtn
            width: 34; height: 34
            radius: 17
            color: saveHover.hovered ? "#33A78BFA" : "#1AA78BFA"
            border.color: root.accentCyan
            border.width: 1
            Behavior on color { ColorAnimation { duration: 180 } }

            HoverHandler { id: saveHover }

            Text {
                anchors.centerIn: parent
                text: "C"
                color: root.accentCyan
                font.pixelSize: 16
                font.weight: Font.Bold
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    saveBtn.scale = 1.2;
                    saveFlash.start();
                    root.saveLyricsToCache();
                }
            }

            SequentialAnimation {
                id: saveFlash
                PropertyAnimation {
                    target: saveBtn; property: "scale"
                    to: 1.0; duration: 200
                    easing.type: Easing.OutBack
                }
            }
        }

        // ---- Refresh (⟳) ----
        Rectangle {
            id: refreshBtn
            width: 34; height: 34
            radius: 17
            color: refreshHover.hovered ? "#33A78BFA" : "#1AA78BFA"
            border.color: root.accentPurple
            border.width: 1
            Behavior on color { ColorAnimation { duration: 180 } }

            HoverHandler { id: refreshHover }

            Text {
                id: refreshIcon
                anchors.centerIn: parent
                text: "⟳"
                color: root.accentCyan
                font.pixelSize: 18
                font.weight: Font.Bold
            }

            RotationAnimation on rotation {
                id: refreshSpin
                running: false
                from: 0; to: 360
                duration: 700
                easing.type: Easing.OutCubic
                onStopped: refreshIcon.rotation = 0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    refreshSpin.start();
                    root.refreshRequested();
                }
            }
        }
    }

    // ============ LOADING STATE ============
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
                running: root.visible
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

    // ============ NOT FOUND STATE ============
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

    // ============ LYRICS LIST ============
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

        Connections {
            target: lyrics
            function onCurrentLineChanged() {
                if (lyrics.currentLine >= 0) {
                    lyricsList.positionViewAtIndex(lyrics.currentLine, ListView.Center);
                }
            }
            function onLinesChanged() {
                lyricsList.positionViewAtBeginning();
            }
        }

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
            height: Math.max(40, textItem.implicitHeight + 16)

            property bool isCurrent: index === lyrics.currentLine
            property bool isNear: Math.abs(index - lyrics.currentLine) <= 2
            property bool isSynced: lyrics.synced

            // Soft glow behind the current line
            Rectangle {
                anchors.fill: parent
                anchors.margins: -12
                visible: lineItem.isCurrent && lineItem.isSynced
                radius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#2522D3EE" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 48
                }
            }

            Text {
                id: textItem
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                text: modelData.text
                color: lineItem.isSynced
                       ? (lineItem.isCurrent ? root.textPrimary
                          : (lineItem.isNear ? "#B0B0C0" : root.textMute))
                       : root.textDim
                font.pixelSize: lineItem.isCurrent ? 22 : 17
                font.weight: lineItem.isCurrent ? Font.Bold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: lineItem.isSynced
                         ? (lineItem.isCurrent ? 1.0
                            : (lineItem.isNear ? 0.85 : 0.55))
                         : 0.9

                Behavior on font.pixelSize { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on opacity { NumberAnimation { duration: 220 } }

                layer.enabled: lineItem.isCurrent && lineItem.isSynced
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accentCyan
                    shadowBlur: 2.0
                    shadowVerticalOffset: 0
                    shadowHorizontalOffset: 0
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
    }
}
