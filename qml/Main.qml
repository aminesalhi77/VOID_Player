import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.settings 1.1

Window {
    id: root
    width: 1400
    height: 850
    minimumWidth: 1000
    minimumHeight: 640
    visible: true
    title: "VOID"
    color: "#05060D"

    readonly property color bgVoid:      "#05060D"
    readonly property color bgDeep:      "#0A0A14"
    readonly property color bgPanel:     "#12121F"
    readonly property color textPrimary: "#F2F2F7"
    readonly property color textDim:     "#8A8AA0"
    readonly property color textMute:    "#55556A"
    readonly property color accentCyan:  "#22D3EE"
    readonly property color accentPurple:"#A78BFA"
    readonly property color accentPink:  "#E879F9"
    readonly property color cyanLine:    "#3322D3EE"
    readonly property color purpleLine:  "#33A78BFA"
    readonly property color greySoft:    "#1AFFFFFF"

    property bool showNowPlaying: false
    property string searchText: ""
    property int lastClickedIndex: -1
    property string currentCategory: ""

    // Category store: filePath -> categoryName
    property var trackCategories: ({})

    // Preset categories (matches sidebar)
    readonly property var categoryList: [
        { name: "Favorites",   color: "#E879F9" },
        { name: "Chill Vibes", color: "#22D3EE" },
        { name: "Workout",     color: "#A78BFA" },
        { name: "Anime OST",   color: "#F472B6" },
        { name: "Gaming",      color: "#3B82F6" },
        { name: "Late Night",  color: "#8B5CF6" }
    ]

    // Get all categories for a track (returns array)
    function getCategories(path) {
        var val = trackCategories[path];
        if (!val) return [];
        if (Array.isArray(val)) return val;
        return [val];
    }

    // Check if a track has a specific category
    function hasCategory(path, category) {
        return getCategories(path).indexOf(category) >= 0;
    }

    // Toggle a category on a track (add if missing, remove if present)
    function toggleCategory(path, category) {
        var copy = Object.assign({}, trackCategories);
        var list = getCategories(path).slice();
        var idx = list.indexOf(category);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            list.push(category);
        }
        if (list.length === 0) {
            delete copy[path];
        } else {
            copy[path] = list;
        }
        trackCategories = copy;
        categorySettings.categoriesJson = JSON.stringify(copy);
    }

    Settings {
        id: categorySettings
        category: "void-categories"
        property string categoriesJson: "{}"
        Component.onCompleted: {
            try {
                trackCategories = JSON.parse(categoriesJson);
            } catch (e) {
                trackCategories = {};
            }
        }
    }

    Settings {
        id: prefs
        category: "void"
        property alias visualizerMode: root.visualizerMode
    }
    property string visualizerMode: "bars"

    // ============ BACKGROUND ============
    Image {
        anchors.fill: parent
        source: "assets/background/bg.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0.55
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#B30A0A18" }
            GradientStop { position: 0.5; color: "#CC06060F" }
            GradientStop { position: 1.0; color: "#E605060D" }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -180
        width: 900
        height: 420
        radius: 210
        color: accentPurple
        opacity: 0.06
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 96 }
    }

    // =================================================================
    //  MAIN LAYOUT
    // =================================================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: !showNowPlaying

        // ============================================================
        //  TOP BAR
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#990A0A14"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                RowLayout {
                    spacing: 10
                    Layout.preferredWidth: 200

                    Row {
                        spacing: 3
                        Layout.alignment: Qt.AlignVCenter
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                width: 3
                                radius: 1.5
                                color: accentCyan
                                height: 8 + (index % 3) * 5

                                SequentialAnimation on height {
                                    running: playback.playing
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 6 + (index % 3) * 10
                                        duration: 500 + index * 120
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 8 + (index % 3) * 5
                                        duration: 500 + index * 120
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "VOID"
                        color: textPrimary
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        font.letterSpacing: 10
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 600
                    Layout.preferredHeight: 38
                    radius: 10
                    color: "#66000000"
                    border.color: searchFocus.activeFocus ? "#6622D3EE" : "#26A78BFA"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text { text: "⌕"; color: textDim; font.pixelSize: 18 }

                        TextField {
                            id: searchFocus
                            Layout.fillWidth: true
                            placeholderText: "Search in library..."
                            placeholderTextColor: textMute
                            color: textPrimary
                            font.pixelSize: 13
                            background: Rectangle { color: "transparent" }
                            selectByMouse: true
                            onTextChanged: root.searchText = text
                        }

                        Rectangle {
                            visible: searchFocus.text !== ""
                            width: 20; height: 20
                            radius: 10
                            color: clearHover.hovered ? "#33A78BFA" : "transparent"
                            HoverHandler { id: clearHover }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: clearHover.hovered ? "#FFFFFF" : textDim
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchFocus.text = "";
                                    root.searchText = "";
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 6

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: moonHover.hovered ? greySoft : "transparent"
                        HoverHandler { id: moonHover }
                        Text { anchors.centerIn: parent; text: "☾"; color: textDim; font.pixelSize: 16 }
                    }

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: gearHover.hovered ? greySoft : "transparent"
                        HoverHandler { id: gearHover }
                        Text { anchors.centerIn: parent; text: "⚙"; color: textDim; font.pixelSize: 16 }
                    }

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: minHover.hovered ? greySoft : "transparent"
                        HoverHandler { id: minHover }
                        Text { anchors.centerIn: parent; text: "—"; color: textDim; font.pixelSize: 14 }
                        MouseArea { anchors.fill: parent; onClicked: root.showMinimized() }
                    }

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: maxHover.hovered ? greySoft : "transparent"
                        HoverHandler { id: maxHover }
                        Text { anchors.centerIn: parent; text: "☐"; color: textDim; font.pixelSize: 14 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.visibility === Window.Maximized) root.showNormal()
                                else root.showMaximized()
                            }
                        }
                    }

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: closeHover.hovered ? "#40E879F9" : "transparent"
                        HoverHandler { id: closeHover }
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeHover.hovered ? accentPink : textDim
                            font.pixelSize: 14
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.close() }
                    }
                }
            }
        }

        // ============================================================
        //  MAIN CONTENT
        // ============================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ============ SIDEBAR — WITH BG IMAGE ============
            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: "#0A0A14"

                // BG image (blurred)
                Image {
                    anchors.fill: parent
                    source: "assets/background/bg.png"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: 0.75
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 0.4
                        blurMax: 24
                    }
                }

                // Dark tint overlay (semi-transparent so image shows through)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#B30A0A18" }
                        GradientStop { position: 1.0; color: "#D906060F" }
                    }
                }

                // Right edge neon line
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#6622D3EE" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 20
                    anchors.bottomMargin: 12
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 4

                    Repeater {
                        model: [
                            { name: "Library",   icon: "♫" },
                            { name: "Albums",    icon: "◉" },
                            { name: "Artists",   icon: "◐" },
                            { name: "Playlists", icon: "▤" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: index === 0 ? "transparent" : (navHover.hovered ? greySoft : "transparent")
                            border.color: index === 0 ? "#6622D3EE" : "transparent"
                            border.width: 1

                            Rectangle {
                                visible: index === 0
                                anchors.fill: parent
                                radius: 10
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#40A78BFA" }
                                    GradientStop { position: 1.0; color: "#4022D3EE" }
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: "#33A78BFA"
                                    shadowBlur: 0.6
                                }
                            }

                            HoverHandler { id: navHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (index === 0) root.currentCategory = "";
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: modelData.icon
                                    color: (index === 0 && root.currentCategory === "") ? "#FFFFFF" : (navHover.hovered ? accentCyan : textDim)
                                    font.pixelSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: index === 0 ? "#FFFFFF" : (navHover.hovered ? textPrimary : textDim)
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 22
                        Layout.bottomMargin: 6
                        Layout.leftMargin: 4

                        Text {
                            text: "MY PLAYLISTS"
                            color: textMute
                            font.pixelSize: 10
                            font.letterSpacing: 2
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text { text: "+"; color: textMute; font.pixelSize: 14 }
                    }

                    Repeater {
                        model: [
                            { name: "Favorites",   icon: "♥",   color: "#E879F9" },
                            { name: "Chill Vibes", icon: "▮▮▮", color: "#22D3EE" },
                            { name: "Workout",     icon: "◮",   color: "#A78BFA" },
                            { name: "Anime OST",   icon: "☆",   color: "#F472B6" },
                            { name: "Gaming",      icon: "◘",   color: "#3B82F6" },
                            { name: "Late Night",  icon: "☾",   color: "#8B5CF6" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 8
                            color: {
                                if (root.currentCategory === modelData.name) return "#33A78BFA";
                                if (plHover.hovered) return greySoft;
                                return "transparent";
                            }
                            border.color: root.currentCategory === modelData.name ? "#66A78BFA" : "transparent"
                            border.width: 1

                            HoverHandler { id: plHover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentCategory = (root.currentCategory === modelData.name)
                                        ? "" : modelData.name;
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: modelData.color
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: plHover.hovered ? textPrimary : textDim
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: root.countInCategory(modelData.name)
                                    color: textMute
                                    font.pixelSize: 11
                                    font.family: "JetBrains Mono"
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "VOID  v1.0.0"
                        color: "#2E2E3A"
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ============ LIBRARY CONTENT ============
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        spacing: 16

                        RowLayout {
                            spacing: 14

                            Rectangle {
                                width: 3
                                height: 44
                                radius: 1.5
                                Layout.alignment: Qt.AlignVCenter
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: accentCyan }
                                    GradientStop { position: 1.0; color: accentPurple }
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: accentCyan
                                    shadowBlur: 1.0
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: root.currentCategory === "" ? "Library" : root.currentCategory
                                    color: textPrimary
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: {
                                        if (root.currentCategory === "") return library.count() + " tracks in library";
                                        var n = root.countInCategory(root.currentCategory);
                                        return n + " track" + (n === 1 ? "" : "s") + " in this category";
                                    }
                                    color: textDim
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "⌂  Scan Music Folder"
                            enabled: !library.scanning
                            focusPolicy: Qt.NoFocus
                            onClicked: library.scanDefaultMusicFolder()

                            background: Rectangle {
                                implicitWidth: 200
                                implicitHeight: 38
                                radius: 10
                                color: parent.hovered ? "#33A78BFA" : "#15A78BFA"
                                border.color: "#66A78BFA"
                                border.width: 1
                            }
                            contentItem: Text {
                                text: parent.text
                                color: accentPurple
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "⊕  Add Custom Folder"
                            enabled: !library.scanning
                            focusPolicy: Qt.NoFocus
                            onClicked: library.pickFolderAndScan()

                            background: Rectangle {
                                implicitWidth: 210
                                implicitHeight: 38
                                radius: 10
                                color: parent.hovered ? cyanLine : "#1522D3EE"
                                border.color: "#6622D3EE"
                                border.width: 1
                            }
                            contentItem: Text {
                                text: parent.text
                                color: accentCyan
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            width: 38; height: 38; radius: 10
                            color: vHover.hovered ? greySoft : "transparent"
                            border.color: "#26A78BFA"
                            border.width: 1
                            HoverHandler { id: vHover }
                            Text {
                                anchors.centerIn: parent
                                text: "▮▮▮"
                                color: accentCyan
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    Layout.preferredHeight: 34
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 16

                        Text { text: "#"; color: textMute; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 30 }
                        Text { text: "Title ⌃"; color: textDim; font.pixelSize: 11; font.weight: Font.Bold; Layout.fillWidth: true }
                        Text { text: "Artist"; color: textMute; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 200 }
                        Text { text: "Album"; color: textMute; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 200 }
                        Text { text: "Duration"; color: textMute; font.pixelSize: 11; font.weight: Font.Bold; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight }
                        Item { Layout.preferredWidth: 30 }
                    }
                }

                ListView {
                    id: trackList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    Layout.bottomMargin: 12
                    clip: true
                    model: trackModel
                    spacing: 4
                    highlight: null
                    highlightFollowsCurrentItem: false

                    delegate: Rectangle {
                        id: rowDelegate
                        required property var index
                        required property string title
                        required property string artist
                        required property string album
                        required property string coverUrl
                        required property string durationText
                        required property string filePath

                        width: trackList.width
                        property bool matchesSearch: {
                            if (root.searchText === "") return true;
                            var q = root.searchText.toLowerCase();
                            return title.toLowerCase().indexOf(q) >= 0
                                || artist.toLowerCase().indexOf(q) >= 0
                                || album.toLowerCase().indexOf(q) >= 0;
                        }
                        property bool matchesCategory: root.currentCategory === "" || root.hasCategory(filePath, root.currentCategory)
                        height: (matchesSearch && matchesCategory) ? 52 : 0
                        visible: matchesSearch && matchesCategory
                        radius: 10
                        color: {
                            if (playback.currentIndex === index) return "#3322D3EE";
                            if (rowHover.hovered) return "#1AFFFFFF";
                            return "transparent";
                        }
                        border.color: playback.currentIndex === index ? "#6622D3EE" : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 140 } }

                        HoverHandler { id: rowHover }

                        // Main click area
                        MouseArea {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.lastClickedIndex === index && playback.currentIndex === index) {
                                    // Same track clicked again → open Now Playing
                                    root.showNowPlaying = true;
                                } else {
                                    playback.setQueue(library.tracks(), index);
                                    root.lastClickedIndex = index;
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 16

                            Text {
                                text: (index + 1)
                                color: textMute
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                Layout.preferredWidth: 30
                            }

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 8
                                color: bgPanel
                                clip: true
                                border.color: "#1AFFFFFF"
                                border.width: 1

                                Image {
                                    anchors.fill: parent
                                    source: coverUrl
                                    fillMode: Image.PreserveAspectCrop
                                    visible: coverUrl !== ""
                                    asynchronous: true
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "♪"
                                    color: accentCyan
                                    font.pixelSize: 16
                                    visible: coverUrl === ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Layout.fillWidth: true

                                    Text {
                                        text: title
                                        color: playback.currentIndex === index ? "#FFFFFF" : textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Category badges (up to 3 shown)
                                    Repeater {
                                        model: root.getCategories(filePath).slice(0, 3)
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: badgeLabel.implicitWidth + 14
                                            height: 18
                                            radius: 9
                                            color: {
                                                for (var i = 0; i < root.categoryList.length; i++) {
                                                    if (root.categoryList[i].name === modelData)
                                                        return root.categoryList[i].color + "33";
                                                }
                                                return "#1AFFFFFF";
                                            }
                                            border.color: {
                                                for (var i = 0; i < root.categoryList.length; i++) {
                                                    if (root.categoryList[i].name === modelData)
                                                        return root.categoryList[i].color;
                                                }
                                                return "#26FFFFFF";
                                            }
                                            border.width: 1

                                            Text {
                                                id: badgeLabel
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: "#FFFFFF"
                                                font.pixelSize: 9
                                                font.weight: Font.Medium
                                            }
                                        }
                                    }

                                    Text {
                                        visible: root.getCategories(filePath).length > 3
                                        text: "+" + (root.getCategories(filePath).length - 3)
                                        color: textMute
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    text: artist + " · " + album
                                    color: textDim
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Text {
                                text: durationText
                                color: textDim
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                Layout.preferredWidth: 60
                                horizontalAlignment: Text.AlignRight
                            }

                            // ⋯ More button
                            Rectangle {
                                id: moreBtn
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 6
                                color: moreHover.hovered ? "#26FFFFFF" : "transparent"
                                HoverHandler { id: moreHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: "⋯"
                                    color: moreHover.hovered ? accentCyan : textMute
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        categoryMenu.currentPath = filePath;
                                        categoryMenu.popup(moreBtn, 0, 0);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =================================================================
        //  BOTTOM PLAYER
        // =================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            color: "#CC0A0A14"
            border.color: "#3322D3EE"
            border.width: 1
            visible: playback.currentIndex >= 0

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: "#66A78BFA" }
                    GradientStop { position: 0.5; color: "#9922D3EE" }
                    GradientStop { position: 0.7; color: "#66E879F9" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 20

                Item {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 82
                            Layout.preferredHeight: 82
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: bgPanel
                            clip: true
                            border.color: "#33A78BFA"
                            border.width: 1
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: accentPurple
                                shadowBlur: 0.5
                            }

                            Image {
                                anchors.fill: parent
                                source: playback.coverUrl
                                fillMode: Image.PreserveAspectCrop
                                visible: playback.coverUrl !== ""
                                asynchronous: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: playback.coverUrl === ""
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: cyanLine }
                                    GradientStop { position: 1.0; color: purpleLine }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "♪"
                                color: accentCyan
                                font.pixelSize: 36
                                visible: playback.coverUrl === ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: playback.title !== "" ? playback.title : "Nothing playing"
                                color: textPrimary
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: playback.artist !== "" ? playback.artist : "Unknown Artist"
                                color: textDim
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: playback.album !== "" ? playback.album : "Unknown Album"
                                color: textMute
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showNowPlaying = true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: fmt(playback.position)
                            color: textDim
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                        }

                        Slider {
                            id: bottomSeek
                            Layout.fillWidth: true
                            from: 0
                            to: Math.max(playback.duration, 1)
                            value: playback.position
                            focusPolicy: Qt.NoFocus
                            onMoved: playback.seek(value)

                            background: Rectangle {
                                x: bottomSeek.leftPadding
                                y: bottomSeek.topPadding + bottomSeek.availableHeight / 2 - height / 2
                                width: bottomSeek.availableWidth
                                height: 4
                                radius: 2
                                color: "#1AFFFFFF"

                                Rectangle {
                                    width: bottomSeek.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: accentPurple }
                                        GradientStop { position: 1.0; color: accentCyan }
                                    }
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: accentCyan
                                        shadowBlur: 0.5
                                    }
                                }
                            }

                            handle: Rectangle {
                                x: bottomSeek.leftPadding + bottomSeek.visualPosition
                                   * (bottomSeek.availableWidth - width)
                                y: bottomSeek.topPadding + bottomSeek.availableHeight / 2 - height / 2
                                width: 10; height: 10
                                radius: 5
                                color: "#FFFFFF"
                                visible: bottomSeek.hovered || bottomSeek.pressed
                            }
                        }

                        Text {
                            text: fmt(playback.duration)
                            color: textDim
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 22

                        Button {
                            text: "⇄"
                            focusPolicy: Qt.NoFocus
                            background: Rectangle { color: "transparent"; radius: 20 }
                            contentItem: Text {
                                text: parent.text; color: textDim; font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "⏮"
                            focusPolicy: Qt.NoFocus
                            onClicked: playback.previous()
                            background: Rectangle { color: "transparent"; radius: 20 }
                            contentItem: Text {
                                text: parent.text; color: textPrimary; font.pixelSize: 22
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: playback.playing ? "⏸" : "▶"
                            focusPolicy: Qt.NoFocus
                            onClicked: playback.playPause()
                            Layout.preferredWidth: 54
                            Layout.preferredHeight: 54

                            background: Rectangle {
                                radius: 27
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#4022D3EE" }
                                    GradientStop { position: 1.0; color: "#40A78BFA" }
                                }
                                border.color: accentCyan
                                border.width: 2
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: accentCyan
                                    shadowBlur: 1.0
                                }
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 24
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "⏭"
                            focusPolicy: Qt.NoFocus
                            onClicked: playback.next()
                            background: Rectangle { color: "transparent"; radius: 20 }
                            contentItem: Text {
                                text: parent.text; color: textPrimary; font.pixelSize: 22
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "⟳"
                            focusPolicy: Qt.NoFocus
                            background: Rectangle { color: "transparent"; radius: 20 }
                            contentItem: Text {
                                text: parent.text; color: textDim; font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: 280
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 52; height: 22
                        radius: 11
                        color: "#1A22D3EE"
                        border.color: "#6622D3EE"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Hi-Fi"
                            color: accentCyan
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }

                    Item {
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 86
                        Layout.alignment: Qt.AlignVCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: 24
                                delegate: Item {
                                    required property int index
                                    width: 4
                                    height: 86

                                    property real baseH: 4 + (index % 5) * 3
                                    property real maxH:  30 + (index % 7) * 6
                                    property int  dur:   280 + (index % 5) * 80

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: baseH
                                        radius: 2
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: accentPurple }
                                            GradientStop { position: 1.0; color: accentCyan }
                                        }
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowColor: accentCyan
                                            shadowBlur: 0.6
                                        }

                                        SequentialAnimation on height {
                                            running: playback.playing
                                            loops: Animation.Infinite
                                            NumberAnimation {
                                                to: maxH
                                                duration: dur
                                                easing.type: Easing.InOutSine
                                            }
                                            NumberAnimation {
                                                to: baseH
                                                duration: dur + 100
                                                easing.type: Easing.InOutSine
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 86
                        Layout.alignment: Qt.AlignVCenter

                        Slider {
                            id: vvol
                            anchors.centerIn: parent
                            orientation: Qt.Vertical
                            from: 0; to: 100
                            value: playback.volume
                            focusPolicy: Qt.NoFocus
                            onMoved: playback.setVolume(value)
                            implicitWidth: 24
                            implicitHeight: 86

                            background: Rectangle {
                                x: vvol.leftPadding + vvol.availableWidth / 2 - width / 2
                                y: vvol.topPadding
                                width: 4
                                height: vvol.availableHeight
                                radius: 2
                                color: "#1AFFFFFF"

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: (1.0 - vvol.visualPosition) * parent.height
                                    radius: 2
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: accentCyan }
                                        GradientStop { position: 1.0; color: accentPurple }
                                    }
                                }
                            }

                            handle: Rectangle {
                                x: vvol.leftPadding + vvol.availableWidth / 2 - width / 2
                                y: vvol.topPadding + vvol.visualPosition * (vvol.availableHeight - height)
                                width: 12; height: 12
                                radius: 6
                                color: "#FFFFFF"
                                border.color: accentCyan
                                border.width: 1
                                visible: vvol.hovered || vvol.pressed
                            }
                        }
                    }
                }
            }
        }
    }

    // =================================================================
    //  CATEGORY MENU (popup on ⋯)
    // =================================================================
    Menu {
        id: categoryMenu
        property string currentPath: ""

        background: Rectangle {
            implicitWidth: 200
            color: "#E60E0E16"
            border.color: "#6622D3EE"
            border.width: 1
            radius: 12

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#3322D3EE"
                shadowBlur: 0.6
            }
        }

        MenuItem {
            contentItem: Text {
                text: "  Choose category"
                color: "#8A8AA0"
                font.pixelSize: 10
                font.letterSpacing: 1.5
                font.weight: Font.Bold
            }
            enabled: false
            background: Item {}
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: "#26FFFFFF"
                anchors.margins: 8
            }
        }

        // "Remove from category" (only shows if already has category)
        MenuItem {
            visible: categoryMenu.currentPath !== "" &&
                     root.getCategory(categoryMenu.currentPath) !== ""
            contentItem: Text {
                text: "  ✕  Remove from category"
                color: "#F87171"
                font.pixelSize: 12
                leftPadding: 8
            }
            background: Rectangle {
                color: parent.hovered ? "#1AF87171" : "transparent"
                radius: 6
            }
            onTriggered: {
                var copy = Object.assign({}, root.trackCategories);
                delete copy[categoryMenu.currentPath];
                root.trackCategories = copy;
                categorySettings.categoriesJson = JSON.stringify(copy);
            }
        }

        // Category options
        Repeater {
            model: root.categoryList
            delegate: MenuItem {
                required property var modelData
                contentItem: RowLayout {
                    spacing: 10
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: root.hasCategory(categoryMenu.currentPath, modelData.name) ? "✓" : ""
                        color: modelData.color
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        Layout.preferredWidth: 12
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: modelData.color
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: modelData.name
                        color: root.hasCategory(categoryMenu.currentPath, modelData.name)
                            ? modelData.color
                            : "#8A8AA0"
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                background: Rectangle {
                    color: parent.hovered ? "#1AFFFFFF" : "transparent"
                    radius: 6
                }
                onTriggered: {
                    root.toggleCategory(categoryMenu.currentPath, modelData.name);
                }
            }
        }
    }

    // =================================================================
    //  NOW PLAYING VIEW
    // =================================================================
    Item {
        id: nowPlayingView
        anchors.fill: parent
        visible: showNowPlaying
        opacity: showNowPlaying ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Image {
            anchors.fill: parent
            source: "assets/background/vortex.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.35
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
        }

        Rectangle {
            anchors.fill: parent
            color: bgVoid
            opacity: 0.72
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 12

                Button {
                    text: "← Back"
                    focusPolicy: Qt.NoFocus
                    onClicked: showNowPlaying = false

                    background: Rectangle {
                        implicitWidth: 88
                        implicitHeight: 34
                        radius: 10
                        color: backHover.hovered ? "#26FFFFFF" : "#1AFFFFFF"
                        border.color: "#33A78BFA"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    HoverHandler { id: backHover }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "NOW PLAYING"
                    color: textMute
                    font.pixelSize: 10
                    font.letterSpacing: 4
                    font.weight: Font.Medium
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4

                    Rectangle {
                        width: 38; height: 38
                        radius: 10
                        color: visualizerMode === "disc" ? "#33A78BFA"
                             : (discHover.hovered ? "#1AFFFFFF" : "#0DFFFFFF")
                        border.color: visualizerMode === "disc" ? accentPurple : "#26FFFFFF"
                        border.width: 1
                        HoverHandler { id: discHover }
                        Text {
                            anchors.centerIn: parent
                            text: "◉"
                            color: visualizerMode === "disc" ? accentCyan : textDim
                            font.pixelSize: 16
                        }
                        MouseArea { anchors.fill: parent; onClicked: visualizerMode = "disc" }
                    }

                    Rectangle {
                        width: 38; height: 38
                        radius: 10
                        color: visualizerMode === "bars" ? "#3322D3EE"
                             : (barsHover.hovered ? "#1AFFFFFF" : "#0DFFFFFF")
                        border.color: visualizerMode === "bars" ? accentCyan : "#26FFFFFF"
                        border.width: 1
                        HoverHandler { id: barsHover }
                        Text {
                            anchors.centerIn: parent
                            text: "▮▮▮"
                            color: visualizerMode === "bars" ? accentCyan : textDim
                            font.pixelSize: 12
                        }
                        MouseArea { anchors.fill: parent; onClicked: visualizerMode = "bars" }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 700)
            spacing: 28

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 360
                Layout.preferredHeight: 360

                Item {
                    anchors.fill: parent
                    visible: visualizerMode === "disc"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 320; height: 320
                        radius: 160
                        color: "transparent"
                        border.color: accentCyan
                        border.width: 2
                        opacity: playback.playing ? 0.9 : 0.3
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: accentCyan
                            shadowBlur: 1.0
                        }
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                    }

                    Rectangle {
                        id: bigVinyl
                        anchors.centerIn: parent
                        width: 290; height: 290
                        radius: 145
                        color: "#0B0B14"
                        border.color: "#1E1E2A"
                        border.width: 1

                        Repeater {
                            model: 6
                            delegate: Rectangle {
                                anchors.centerIn: parent
                                width: bigVinyl.width - (index * 26)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: "#0DFFFFFF"
                                border.width: 1
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 200; height: 200
                            source: playback.coverUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: playback.coverUrl !== ""
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: bigMask
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 200; height: 200
                            radius: 100
                            visible: playback.coverUrl === ""
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: cyanLine }
                                GradientStop { position: 1.0; color: purpleLine }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            color: "#FFFFFF"
                            font.pixelSize: 72
                            visible: playback.coverUrl === ""
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            radius: 8
                            color: "#000000"
                            border.color: "#333344"
                            border.width: 1
                        }

                        RotationAnimation on rotation {
                            running: playback.playing && visualizerMode === "disc"
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 9000
                        }
                    }

                    Item {
                        id: bigMask
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true
                        Rectangle {
                            anchors.centerIn: parent
                            width: 200; height: 200
                            radius: 100
                            color: "white"
                        }
                    }
                }

                Item {
                    id: barsContainer
                    anchors.fill: parent
                    visible: visualizerMode === "bars"

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        height: parent.height * 0.5
                        radius: 20
                        color: accentCyan
                        opacity: playback.playing ? 0.08 : 0.03
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0 }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Repeater {
                            model: 32
                            delegate: Item {
                                required property int index
                                width: 6
                                height: barsContainer.height

                                property real baseH: 0.15 + (index % 5) * 0.08
                                property real amp:   0.25 + (index % 3) * 0.15
                                property int  dur:   280 + (index % 7) * 60

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: parent.height * baseH
                                    radius: 3
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: accentPurple }
                                        GradientStop { position: 1.0; color: accentCyan }
                                    }
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: accentCyan
                                        shadowBlur: 0.7
                                    }

                                    SequentialAnimation on height {
                                        running: playback.playing
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: barsContainer.height * (baseH + amp)
                                            duration: dur
                                            easing.type: Easing.InOutSine
                                        }
                                        NumberAnimation {
                                            to: barsContainer.height * baseH
                                            duration: dur + 80
                                            easing.type: Easing.InOutSine
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: playback.title !== "" ? playback.title : "Nothing playing"
                    color: textPrimary
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: playback.artist
                    color: accentCyan
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    Layout.fillWidth: true
                    text: playback.album
                    color: textDim
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: fmt(playback.position)
                        color: textMute
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                    }

                    Slider {
                        id: npSeek
                        Layout.fillWidth: true
                        from: 0
                        to: Math.max(playback.duration, 1)
                        value: playback.position
                        focusPolicy: Qt.NoFocus
                        onMoved: playback.seek(value)

                        background: Rectangle {
                            x: npSeek.leftPadding
                            y: npSeek.topPadding + npSeek.availableHeight / 2 - height / 2
                            width: npSeek.availableWidth
                            height: 4
                            radius: 2
                            color: "#1AFFFFFF"
                            Rectangle {
                                width: npSeek.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: accentCyan }
                                    GradientStop { position: 1.0; color: accentPurple }
                                }
                            }
                        }

                        handle: Rectangle {
                            x: npSeek.leftPadding + npSeek.visualPosition
                               * (npSeek.availableWidth - width)
                            y: npSeek.topPadding + npSeek.availableHeight / 2 - height / 2
                            width: 14; height: 14
                            radius: 7
                            color: accentCyan
                            visible: npSeek.hovered || npSeek.pressed
                        }
                    }

                    Text {
                        text: fmt(playback.duration)
                        color: textMute
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 22

                    Button {
                        text: "⏮"
                        focusPolicy: Qt.NoFocus
                        onClicked: playback.previous()
                        background: Rectangle { color: "transparent"; radius: 24 }
                        contentItem: Text {
                            text: parent.text; color: textPrimary; font.pixelSize: 26
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "−10"
                        focusPolicy: Qt.NoFocus
                        onClicked: playback.skipBackward10()
                        background: Rectangle { color: "transparent"; radius: 24 }
                        contentItem: Text {
                            text: parent.text; color: textDim
                            font.pixelSize: 14; font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: playback.playing ? "⏸" : "▶"
                        focusPolicy: Qt.NoFocus
                        onClicked: playback.playPause()
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 68

                        background: Rectangle {
                            radius: 34
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#4022D3EE" }
                                GradientStop { position: 1.0; color: "#40A78BFA" }
                            }
                            border.color: accentCyan
                            border.width: 2
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: accentCyan
                                shadowBlur: 1.0
                            }
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 30
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "+10"
                        focusPolicy: Qt.NoFocus
                        onClicked: playback.skipForward10()
                        background: Rectangle { color: "transparent"; radius: 24 }
                        contentItem: Text {
                            text: parent.text; color: textDim
                            font.pixelSize: 14; font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "⏭"
                        focusPolicy: Qt.NoFocus
                        onClicked: playback.next()
                        background: Rectangle { color: "transparent"; radius: 24 }
                        contentItem: Text {
                            text: parent.text; color: textPrimary; font.pixelSize: 26
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        Item {
            id: npVolumeWidget
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 28
            anchors.bottomMargin: 28
            width: 48
            height: 48
            z: 100

            Rectangle {
                id: npVolumePanel
                anchors.bottom: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 10
                width: 44
                height: 170
                radius: 14
                color: "#E60E0E16"
                border.color: "#6622D3EE"
                border.width: 1

                opacity: npVolHover.hovered || npVolSlider.hovered || npVolSlider.pressed ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: accentCyan
                    shadowBlur: 0.8
                }

                Slider {
                    id: npVolSlider
                    anchors.centerIn: parent
                    orientation: Qt.Vertical
                    from: 0
                    to: 100
                    value: playback.volume
                    focusPolicy: Qt.NoFocus
                    onMoved: playback.setVolume(value)
                    implicitWidth: 24
                    implicitHeight: parent.height - 24

                    background: Rectangle {
                        x: npVolSlider.leftPadding + npVolSlider.availableWidth / 2 - width / 2
                        y: npVolSlider.topPadding
                        width: 4
                        height: npVolSlider.availableHeight
                        radius: 2
                        color: "#1AFFFFFF"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: (1.0 - npVolSlider.visualPosition) * parent.height
                            radius: 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: accentCyan }
                                GradientStop { position: 1.0; color: accentPurple }
                            }
                        }
                    }

                    handle: Rectangle {
                        x: npVolSlider.leftPadding + npVolSlider.availableWidth / 2 - width / 2
                        y: npVolSlider.topPadding + npVolSlider.visualPosition
                           * (npVolSlider.availableHeight - height)
                        width: 12
                        height: 12
                        radius: 6
                        color: "#FFFFFF"
                        border.color: accentCyan
                        border.width: 1
                        visible: npVolSlider.hovered || npVolSlider.pressed
                    }
                }
            }

            Rectangle {
                id: npVolButton
                anchors.fill: parent
                radius: 24
                color: npVolHover.hovered ? "#26222D3A" : "#CC0E0E16"
                border.color: npVolHover.hovered ? accentCyan : "#6622D3EE"
                border.width: 1

                HoverHandler { id: npVolHover }
                Behavior on color { ColorAnimation { duration: 150 } }

                layer.enabled: npVolHover.hovered
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: accentCyan
                    shadowBlur: 0.8
                }

                Text {
                    anchors.centerIn: parent
                    text: playback.volume === 0 ? "🔇"
                        : playback.volume < 40 ? "🔈"
                        : playback.volume < 75 ? "🔉"
                        : "🔊"
                    font.pixelSize: 20
                }
            }
        }
    }

    function countInCategory(categoryName) {
        var count = 0;
        for (var path in trackCategories) {
            if (hasCategory(path, categoryName)) count++;
        }
        return count;
    }

    function fmt(ms) {
        if (!ms || ms < 0) return "0:00";
        const s = Math.floor(ms / 1000);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}