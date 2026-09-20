import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    signal closeRequested()
    signal saveRequested(string lrcText, bool isSynced)

    property string trackTitle: ""
    property string artistName: ""

    property color accentCyan:   "#22D3EE"
    property color accentPurple: "#A78BFA"
    property color textPrimary:  "#F2F2F7"
    property color textDim:      "#8A8AA0"
    property color textMute:     "#55556A"
    property color bgPanel:      "#12121F"

    property var rawLines: []
    property var timestamps: []

    function parseInput(text) {
        var out = [];
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var t = lines[i].trim();
            if (t.length === 0) continue;
            var m = t.match(/^\[\d+:\d+(?:\.\d+)?\]\s*(.*)$/);
            if (m) t = m[1];
            if (t.length === 0) continue;
            out.push(t);
        }
        return out;
    }

    function formatTime(ms) {
        if (ms < 0) return "--:--";
        var s = Math.floor(ms / 1000);
        var m = Math.floor(s / 60);
        var ss = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    function stampedCount() {
        var n = 0;
        for (var i = 0; i < timestamps.length; i++) {
            if (timestamps[i] >= 0) n++;
        }
        return n;
    }

    function nextLineIndex() {
        for (var i = 0; i < timestamps.length; i++) {
            if (timestamps[i] < 0) return i;
        }
        return -1;
    }

    function buildLRC() {
        var out = [];
        for (var i = 0; i < rawLines.length; i++) {
            var ts = timestamps[i];
            if (ts === undefined || ts < 0) continue;
            var s = ts / 1000;
            var m = Math.floor(s / 60);
            var sec = s - m * 60;
            var secStr = (sec < 10 ? "0" : "") + sec.toFixed(2);
            var minStr = (m < 10 ? "0" : "") + m;
            out.push("[" + minStr + ":" + secStr + "] " + rawLines[i]);
        }
        return out.join("\n");
    }

    function stampCurrent() {
        var n = nextLineIndex();
        if (n < 0) return;
        var copy = timestamps.slice();
        copy[n] = playback.position;
        timestamps = copy;
    }

    // Dim overlay
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"

        MouseArea { anchors.fill: parent }
    }

    // Card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 900)
        height: Math.min(parent.height - 80, 620)
        radius: 20
        color: "#0D0D16"
        border.color: root.accentCyan
        border.width: 2
        focus: true

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.accentCyan
            shadowBlur: 1.0
        }

        Keys.onSpacePressed: root.stampCurrent()
        Keys.onEscapePressed: root.closeRequested()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Sync lyrics"
                    color: root.textPrimary
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    text: root.trackTitle + "  -  " + root.artistName
                    color: root.textDim
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 32; height: 32
                    radius: 8
                    color: closeHover.hovered ? "#33F87171" : "#1AF87171"
                    border.color: "#66F87171"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                    HoverHandler { id: closeHover }
                    Text {
                        anchors.centerIn: parent
                        text: "X"
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

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                // LEFT: paste area
                ColumnLayout {
                    Layout.preferredWidth: 340
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        text: "PASTE LYRICS"
                        color: root.textMute
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12
                        color: root.bgPanel
                        border.color: editor.activeFocus ? root.accentCyan : "#2A2A3A"
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            TextArea {
                                id: editor
                                placeholderText: "Paste lyrics here, one line per row..."
                                placeholderTextColor: root.textMute
                                color: root.textPrimary
                                font.pixelSize: 13
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                background: null

                                onTextChanged: {
                                    root.rawLines = root.parseInput(text);
                                    var ts = [];
                                    for (var i = 0; i < root.rawLines.length; i++) ts.push(-1);
                                    root.timestamps = ts;
                                }
                            }
                        }
                    }

                    Text {
                        text: root.rawLines.length + " lines detected"
                        color: root.textMute
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                    }
                }

                // RIGHT: sync pad
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Text {
                        text: "TAP ALONG"
                        color: root.textMute
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        radius: 14
                        color: root.bgPanel
                        border.color: root.accentCyan
                        border.width: 2

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.accentCyan
                            shadowBlur: 0.7
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 24
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var n = root.nextLineIndex();
                                    if (n < 0) return "All lines synced";
                                    return root.rawLines[n] || "Paste lyrics first";
                                }
                                color: root.textPrimary
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.stampedCount() + " / " + root.rawLines.length + " stamped"
                                color: root.textMute
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Big tap button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        radius: 20
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: playback.playing ? "#40A78BFA" : "#1A22D3EE" }
                            GradientStop { position: 1.0; color: playback.playing ? "#4022D3EE" : "#1A2A3A" }
                        }
                        border.color: root.accentCyan
                        border.width: 3

                        layer.enabled: playback.playing
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.accentCyan
                            shadowBlur: 1.0
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "PRESS SPACE"
                                color: "#FFFFFF"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                font.letterSpacing: 3
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "when the next line starts"
                                color: "#CCFFFFFF"
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stampCurrent()
                        }
                    }

                    // Controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: playback.playing ? "Pause" : "Play"
                            focusPolicy: Qt.NoFocus
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 40
                            onClicked: playback.playPause()
                            background: Rectangle {
                                radius: 10
                                color: parent.hovered ? "#33A78BFA" : "#1AA78BFA"
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
                        }

                        Text {
                            text: "Pos: " + root.formatTime(playback.position)
                            color: root.textDim
                            font.pixelSize: 12
                            font.family: "JetBrains Mono"
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "Undo"
                            focusPolicy: Qt.NoFocus
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 40
                            onClicked: {
                                for (var i = root.timestamps.length - 1; i >= 0; i--) {
                                    if (root.timestamps[i] >= 0) {
                                        var copy = root.timestamps.slice();
                                        copy[i] = -1;
                                        root.timestamps = copy;
                                        return;
                                    }
                                }
                            }
                            background: Rectangle {
                                radius: 10
                                color: parent.hovered ? "#26FFFFFF" : "#1AFFFFFF"
                                border.color: "#33FFFFFF"
                                border.width: 1
                            }
                            contentItem: Text {
                                text: parent.text
                                color: root.textPrimary
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "Save"
                            focusPolicy: Qt.NoFocus
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 40
                            enabled: root.rawLines.length > 0
                            onClicked: {
                                var lrc = root.buildLRC();
                                var anySynced = root.stampedCount() > 0;
                                root.saveRequested(lrc, anySynced);
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
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
