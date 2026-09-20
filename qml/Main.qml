import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.settings 1.1
import Void

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
    property string currentPage: "library"
    property var albumList: []
    property var artistList: []
    property var albumDetail: null
    property var albumTracks: []
    property var artistDetail: null
    property var artistTracks: []

    onCurrentPageChanged: {
        if (currentPage === "albums") albumList = buildAlbumList();
        else if (currentPage === "artists") artistList = buildArtistList();
    }



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
        property alias currentPage: root.currentPage
        property alias currentCategory: root.currentCategory
    }
    property string visualizerMode: "bars"
    property bool showLyrics: false
    property bool showLyricsDialog: false
    property real vizTick: 0

    // Single global animation driving every bar
    NumberAnimation on vizTick {
        running: playback.playing
        loops: Animation.Infinite
        from: 0
        to: 6283
        duration: 9000
        easing.type: Easing.Linear
    }

    // Auto-load from DB, then auto-scan only if empty
    Component.onCompleted: {
        // 1. Load previously saved library from SQLite (instant)
        library.loadFromDb();

        // 2. Only auto-scan if the DB was empty
        if (library.trackCount === 0 && !hasAutoScanned) {
            hasAutoScanned = true;
            console.log("VOID: empty library — auto-scanning ~/Music...");
            library.scanDefaultMusicFolder();
        }

        // 3. Load the queue (without auto-playing) and restore last session
        Qt.callLater(function() {
            playback.loadQueueOnly(library.tracks());
            playback.restoreLastSession();
        });
    }

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
                            { name: "Library",   icon: "♫", page: "library" },
                            { name: "Albums",    icon: "◉", page: "albums" },
                            { name: "Artists",   icon: "◐", page: "artists" },
                            { name: "Playlists", icon: "▤", page: "playlists" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            property bool isActive: modelData.page === root.currentPage
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 10
                            color: "transparent"
                            border.color: isActive ? "#6622D3EE" : "transparent"
                            border.width: 1

                            Rectangle {
                                visible: isActive
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
                                    root.albumDetail = null;
                                    root.albumTracks = [];
                                    root.artistDetail = null;
                                    root.artistTracks = [];
                                    if (index === 0) { root.currentCategory = ""; root.currentPage = "library"; }
                                    else if (index === 1) root.currentPage = "albums";
                                    else if (index === 2) root.currentPage = "artists";
                                    else if (index === 3) root.currentPage = "playlists";
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Text {
                                    text: modelData.icon
                                    color: isActive ? "#FFFFFF" : (navHover.hovered ? accentCyan : textDim)
                                    font.pixelSize: 16
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    text: modelData.name
                                    color: isActive ? "#FFFFFF" : (navHover.hovered ? textPrimary : textDim)
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
                        text: "Made by Amine SALHI
    VOID  v1.0.0"
                        color: "#2E2E3A"
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ============ LIBRARY CONTENT ============
            ColumnLayout {
                visible: root.currentPage === "library"
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
                                        if (root.currentCategory === "") return library.trackCount + " tracks in library";
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

                                    // Category badges (up to 3 shown) — neon style
                                    Repeater {
                                        model: root.getCategories(filePath).slice(0, 3)
                                        delegate: Rectangle {
                                            id: badge
                                            required property var modelData

                                            // Find the category color
                                            property string catColor: {
                                                for (var i = 0; i < root.categoryList.length; i++) {
                                                    if (root.categoryList[i].name === modelData)
                                                        return root.categoryList[i].color;
                                                }
                                                return "#8A8AA0";
                                            }

                                            width: badgeLabel.implicitWidth + 18
                                            height: 20
                                            radius: 10

                                            // Neon fill — category color at 25% alpha (AARRGGBB)
                                            color: "#40" + badge.catColor.substring(1)

                                            // Neon border — full category color
                                            border.color: badge.catColor
                                            border.width: 1

                                            // Glow
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                shadowEnabled: true
                                                shadowColor: badge.catColor
                                                shadowBlur: 0.6
                                            }

                                            Text {
                                                id: badgeLabel
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: badge.catColor
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.3
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


            // ============ ALBUMS PAGE ============
            ColumnLayout {
                    id: albumsGrid
                    opacity: root.albumDetail === null ? 1 : 0
                    scale: root.albumDetail === null ? 1 : 0.94
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                visible: root.currentPage === "albums" && root.albumDetail === null

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        spacing: 14
                        Rectangle {
                            width: 3; height: 44
                            Layout.alignment: Qt.AlignVCenter
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: accentCyan }
                                GradientStop { position: 1.0; color: accentPurple }
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Albums"; color: textPrimary; font.pixelSize: 26; font.weight: Font.Bold }
                            Text { text: root.albumList.length + " albums"; color: textDim; font.pixelSize: 12 }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                GridView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    Layout.topMargin: 12
                    Layout.bottomMargin: 24
                    clip: true
                    cellWidth: 200
                    cellHeight: 256
                    model: root.albumList
                    delegate: Item {
                        required property var modelData
                        width: 200
                        height: 256
                        Rectangle {
                            anchors.centerIn: parent
                            width: 184
                            height: 240
                            radius: 14
                            color: "#1A1A28"
                            border.width: 2
                            border.color: "#22D3EE"

                            SequentialAnimation on border.color {
                                running: true
                                loops: Animation.Infinite
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                                ColorAnimation { to: "#A78BFA"; duration: 2600 }
                                ColorAnimation { to: "#E879F9"; duration: 2600 }
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 138
                                    radius: 10
                                    color: bgPanel
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
                                            GradientStop { position: 0.0; color: cyanLine }
                                            GradientStop { position: 1.0; color: purpleLine }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "♪"
                                        color: "#FFFFFF"
                                        font.pixelSize: 40
                                        visible: modelData.coverUrl === ""
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.album
                                    color: textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.artist
                                    color: textDim
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.count + " track" + (modelData.count === 1 ? "" : "s")
                                    color: textMute
                                    font.pixelSize: 10
                                }
                            }
                            MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openAlbum(modelData.album, modelData.artist)
                        }
                        }
                    }
                }
            }

            // ============ ALBUM DETAIL (transition view) ============
            // ============ ALBUM DETAIL (overlay) ============
            Item {
                id: albumDetailHost
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentPage === "albums" && root.albumDetail !== null
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: "#0A0A14"
                    opacity: parent.visible ? 0.92 : 0
                }

                AlbumDetail {
                    id: albumDetailView
                    anchors.fill: parent
                    anchors.margins: 0

                    opacity: (root.currentPage === "albums" && root.albumDetail !== null) ? 1 : 0
                    scale:   (root.currentPage === "albums" && root.albumDetail !== null) ? 1 : 0.94

                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                    albumName:  root.albumDetail ? root.albumDetail.album : ""
                    artistName: root.albumDetail ? root.albumDetail.artist : ""
                    coverUrl:   (root.albumTracks && root.albumTracks.length > 0)
                                 ? root.albumTracks[0].coverUrl : ""
                    tracks:     root.albumTracks ? root.albumTracks : []

                    accentCyan:   root.accentCyan
                    accentPurple: root.accentPurple
                    accentPink:   root.accentPink
                    textPrimary:  root.textPrimary
                    textDim:      root.textDim
                    textMute:     root.textMute
                    bgPanel:      root.bgPanel
                    bgDeep:       root.bgDeep

                    onBack: root.closeAlbum()

                    onOpenNowPlaying: root.showNowPlaying = true

                    onPlayTrack: function(trackIndex) {
                        if (trackIndex >= 0 && trackIndex < root.albumTracks.length) {
                            playback.setQueue(library.tracks(), root.albumTracks[trackIndex].index);
                        }
                    }
                }
            }

            // ============ ARTIST DETAIL (overlay) ============
            Item {
                id: artistDetailHost
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentPage === "artists" && root.artistDetail !== null
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: "#0A0A14"
                    opacity: parent.visible ? 0.92 : 0
                }

                ArtistDetail {
                    id: artistDetailView
                    anchors.fill: parent

                    opacity: (root.currentPage === "artists" && root.artistDetail !== null) ? 1 : 0
                    scale:   (root.currentPage === "artists" && root.artistDetail !== null) ? 1 : 0.94

                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                    artistName: root.artistDetail ? root.artistDetail.name : ""
                    avatarUrl:  {
                        if (!root.artistDetail) return "";
                        for (var i = 0; i < root.artistList.length; i++) {
                            if (root.artistList[i].name === root.artistDetail.name)
                                return root.artistList[i].coverUrl || "";
                        }
                        return "";
                    }
                    artistImageUrl: root.artistDetail
                                    ? (artistImages.get(root.artistDetail.name) || "")
                                    : ""
                    tracks:     root.artistTracks ? root.artistTracks : []

                    accentCyan:   root.accentCyan
                    accentPurple: root.accentPurple
                    accentPink:   root.accentPink
                    textPrimary:  root.textPrimary
                    textDim:      root.textDim
                    textMute:     root.textMute
                    bgPanel:      root.bgPanel
                    bgDeep:       root.bgDeep

                    onBack: root.closeArtist()
                    onOpenNowPlaying: root.showNowPlaying = true

                    onPlayTrack: function(trackIndex) {
                        if (trackIndex >= 0 && trackIndex < root.artistTracks.length) {
                            playback.setQueue(library.tracks(), root.artistTracks[trackIndex].index);
                        }
                    }
                }
            }

            // ============ ARTISTS PAGE ============
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                visible: root.currentPage === "artists" && root.artistDetail === null
                opacity: root.artistDetail === null ? 1 : 0
                scale: root.artistDetail === null ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        spacing: 14
                        Rectangle {
                            width: 3; height: 44
                            Layout.alignment: Qt.AlignVCenter
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: accentCyan }
                                GradientStop { position: 1.0; color: accentPurple }
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Artists"; color: textPrimary; font.pixelSize: 26; font.weight: Font.Bold }
                            Text { text: root.artistList.length + " artists"; color: textDim; font.pixelSize: 12 }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                GridView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    Layout.topMargin: 12
                    Layout.bottomMargin: 24
                    clip: true
                    cellWidth: 200
                    cellHeight: 230
                    model: root.artistList
                    delegate: Item {
                        required property var modelData
                        width: 200
                        height: 230
                        Rectangle {
                            anchors.centerIn: parent
                            width: 184
                            height: 214
                            radius: 14
                            color: "#1A1A28"
                            border.width: 2
                            border.color: "#22D3EE"

                            SequentialAnimation on border.color {
                                running: true
                                loops: Animation.Infinite
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                                ColorAnimation { to: "#A78BFA"; duration: 2600 }
                                ColorAnimation { to: "#E879F9"; duration: 2600 }
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 116
                                    Layout.alignment: Qt.AlignHCenter

                                    Rectangle {
                                        id: artistAvatarCircle
                                        anchors.centerIn: parent
                                        width: 96; height: 96
                                        radius: 48
                                        color: bgPanel
                                        border.color: accentCyan
                                        border.width: 2

                                        // Image with circular mask
                                        Image {
                                            id: avatarImg
                                            anchors.fill: parent
                                            anchors.margins: -28
                                            source: (modelData.artistImageUrl && modelData.artistImageUrl !== "")
                                                    ? modelData.artistImageUrl
                                                    : modelData.coverUrl
                                            fillMode: Image.PreserveAspectCrop
                                            visible: source !== ""
                                            asynchronous: true
                                            sourceSize.width: 256
                                            sourceSize.height: 256
                                            mipmap: true
                                            smooth: true
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskEnabled: true
                                                maskSource: artistAvatarMaskItem
                                            }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            visible: avatarImg.source === "" || avatarImg.source === undefined
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: cyanLine }
                                                GradientStop { position: 1.0; color: purpleLine }
                                            }
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name.charAt(0).toUpperCase()
                                            color: "#FFFFFF"
                                            font.pixelSize: 40
                                            font.weight: Font.Bold
                                            visible: avatarImg.source === "" || avatarImg.source === undefined
                                        }

                                        // Circular mask
                                        Item {
                                            id: artistAvatarMaskItem
                                            anchors.fill: parent
                                            visible: false
                                            layer.enabled: true
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 48
                                                color: "white"
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.count + " track" + (modelData.count === 1 ? "" : "s")
                                    color: textMute
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openArtist(modelData.name)
                            }
                        }
                    }
                }
            }

            // ============ PLAYLISTS PAGE ============
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                visible: root.currentPage === "playlists"

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 28
                        spacing: 14
                        Rectangle {
                            width: 3; height: 44
                            Layout.alignment: Qt.AlignVCenter
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: accentCyan }
                                GradientStop { position: 1.0; color: accentPurple }
                            }
                        }
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Playlists"; color: textPrimary; font.pixelSize: 26; font.weight: Font.Bold }
                            Text { text: root.categoryList.length + " playlists"; color: textDim; font.pixelSize: 12 }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                GridView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    Layout.topMargin: 12
                    Layout.bottomMargin: 24
                    clip: true
                    cellWidth: 200
                    cellHeight: 190
                    model: root.categoryList
                    delegate: Item {
                        required property var modelData
                        width: 200
                        height: 190
                        Rectangle {
                            anchors.centerIn: parent
                            width: 184
                            height: 174
                            radius: 14
                            color: "#1A1A28"
                            border.width: 2
                            border.color: "#22D3EE"

                            SequentialAnimation on border.color {
                                running: true
                                loops: Animation.Infinite
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                                ColorAnimation { to: "#A78BFA"; duration: 2600 }
                                ColorAnimation { to: "#E879F9"; duration: 2600 }
                                ColorAnimation { to: "#22D3EE"; duration: 2600 }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 90
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 70; height: 70
                                        radius: 35
                                        color: modelData.color + "33"
                                        border.color: modelData.color
                                        border.width: 2
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.charAt(0).toUpperCase()
                                        color: modelData.color
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: textPrimary
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.countInCategory(modelData.name) + " track" + (root.countInCategory(modelData.name) === 1 ? "" : "s")
                                    color: textMute
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentPage = "library";
                                    root.currentCategory = modelData.name;
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

                        Item {
                            id: bottomBarInner
                            anchors.fill: parent
                            anchors.margins: 4

                            Repeater {
                                model: 20
                                delegate: Item {
                                    required property int index

                                    property real barW: (bottomBarInner.width - 19 * 3) / 20
                                    x: index * (barW + 3)
                                    y: 0
                                    width: barW
                                    height: bottomBarInner.height

                                    property real energy: {
                                        var amps = playback.analyzer ? playback.analyzer.amplitudes : null;
                                        if (!amps || amps.length === 0) return 0;
                                        var i = Math.min(Math.floor(index * (amps.length / 20)), amps.length - 1);
                                        return amps[i] || 0;
                                    }

                                    property real displayH: Math.max(3,
                                        bottomBarInner.height * Math.min(1.0, energy * 1.0))

                                    // Neon palette: cyan → purple → magenta
                                    property real baseHue: 180 + (index / 19.0) * 130
                                    property real hueOffset: 0
                                    NumberAnimation on hueOffset {
                                        running: playback.playing
                                        loops: Animation.Infinite
                                        from: -10
                                        to: 10
                                        duration: 2800 + (index % 6) * 200
                                    }
                                    property real finalHue: baseHue + hueOffset

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        height: parent.displayH
                                        radius: 1.5

                                        gradient: Gradient {
                                            GradientStop {
                                                position: 0.0
                                                color: Qt.hsla(finalHue / 360, 0.85, 0.6, 1.0)
                                            }
                                            GradientStop {
                                                position: 1.0
                                                color: Qt.hsla(((finalHue + 40) % 360) / 360, 0.85, 0.5, 1.0)
                                            }
                                        }

                                        Behavior on height {
                                            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                                        }

                                        layer.enabled: true
                            layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowColor: Qt.hsla(finalHue / 360, 0.9, 0.6, 1.0)
                                            shadowBlur: 0.5
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 3
                            visible: false

                            Repeater {
                                model: 16
                                delegate: Item {
                                    required property int index

                                    // Manual positioning — no Row, no circular sizing
                                    property real barW: (parent.width - 15 * 3) / 16
                                    x: index * (barW + 3)
                                    width: barW
                                    height: parent.height

                                    property real baseH: 0.15 + ((index * 7) % 5) * 0.06
                                    property real amp:   0.35 + ((index * 11) % 4) * 0.12
                                    property real speed: 0.7 + ((index * 13) % 5) * 0.25
                                    property real phase: (index * 0.83) % 6.283

                                    // Pure function of vizTick — always animates
                                    property real energy: 0.5 + 0.5 * Math.sin(root.vizTick * 0.01 * speed + phase)
                                    property real barH: parent.height * (baseH + amp * energy)
                                    property real baseHue: 180 + (index / 15.0) * 130

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: parent.barH
                                        radius: 2
                                        color: Qt.hsla(parent.baseHue / 360, 0.85, 0.6, 1.0)

                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowColor: Qt.hsla(parent.baseHue / 360, 0.9, 0.6, 1.0)
                                            shadowBlur: 0.5
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
                    Rectangle {
                        id: lyricsToggleBtn
                        width: 38; height: 38
                        radius: 10
                        color: root.showLyrics ? "#33A78BFA"
                             : (lyricsToggleHover.hovered ? "#1AFFFFFF" : "#0DFFFFFF")
                        border.color: root.showLyrics ? accentPurple : "#26FFFFFF"
                        border.width: 1
                        HoverHandler { id: lyricsToggleHover }
                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            color: root.showLyrics ? accentCyan : textDim
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showLyrics = !root.showLyrics
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: nowPlayingCenter
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.showLyrics ? -(root.width * 0.20) : 0
            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
            }
            width: Math.min(parent.width - 80, 700)
            spacing: 28

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 360
                Layout.preferredHeight: 360

                Item {
                    anchors.fill: parent
                    visible: visualizerMode === "disc"

                    // Outer ring — pulses with average bass energy
                    // Ripple ring 1 — expanding wave, resets on each kick
                    // ========== WAVY RING (undulating outline) ==========
                    Canvas {
                        id: wavyRing
                        anchors.centerIn: parent
                        width: 460
                        height: 460
                        antialiasing: true

                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Cooperative

                        property real phase: 0

                        // Real-time audio energy — bass + overall
                        property real bassEnergy: {
                            var a = playback.analyzer ? playback.analyzer.amplitudes : null;
                            if (!a || a.length === 0) return 0;
                            var s = 0;
                            for (var i = 0; i < 8 && i < a.length; i++) s += a[i];
                            return s / 8;
                        }

                        property real peakEnergy: playback.analyzer ? playback.analyzer.peakEnergy : 0

                        // Smoothly follow the bass — attack fast, release slow
                        property real drive: 0
                        onBassEnergyChanged: {
                            if (bassEnergy > drive) drive = bassEnergy;      // instant attack
                            else drive = drive * 0.85 + bassEnergy * 0.15;   // smooth release
                        }

                        Timer {
                            interval: 33
                            running: playback.playing && root.showNowPlaying
                            repeat: true
                            onTriggered: {
                                wavyRing.phase += 0.25;
                                wavyRing.requestPaint();
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var cx = width / 2;
                            var cy = height / 2;

                            // Base radius pulses with bass — 138 (quiet) to 175 (loud)
                            var baseR = 138 + drive * 40;

                            // Wave amplitude scales with energy too
                            var waveAmp = 8 + drive * 30;

                            var steps = 48;

                            // ---- Outer magenta halo ----
                            ctx.beginPath();
                            ctx.lineWidth = 2 + drive * 3;
                            ctx.strokeStyle = "rgba(232, 121, 249, " + (0.35 + drive * 0.65) + ")";
                            for (var k = 0; k <= steps; k++) {
                                var a3 = (k / steps) * Math.PI * 2;
                                var r3 = baseR + 18
                                       + Math.sin(a3 * 3 + phase * 0.9) * waveAmp * 0.7
                                       + Math.sin(a3 * 6 - phase * 1.3) * waveAmp * 0.4;
                                var x3 = cx + Math.cos(a3) * r3;
                                var y3 = cy + Math.sin(a3) * r3;
                                if (k === 0) ctx.moveTo(x3, y3);
                                else ctx.lineTo(x3, y3);
                            }
                            ctx.closePath();
                            ctx.stroke();

                            // ---- Cyan main wave ----
                            ctx.beginPath();
                            ctx.lineWidth = 3 + drive * 2;
                            ctx.strokeStyle = "rgba(34, 211, 238, " + (0.55 + drive * 0.45) + ")";
                            for (var i = 0; i <= steps; i++) {
                                var a = (i / steps) * Math.PI * 2;
                                var r = baseR
                                      + Math.sin(a * 4 + phase * 1.2) * waveAmp
                                      + Math.sin(a * 7 - phase * 1.6) * waveAmp * 0.5;
                                var x = cx + Math.cos(a) * r;
                                var y = cy + Math.sin(a) * r;
                                if (i === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.closePath();
                            ctx.stroke();

                            // ---- Purple inner ripple ----
                            ctx.beginPath();
                            ctx.lineWidth = 2 + drive;
                            ctx.strokeStyle = "rgba(167, 139, 250, " + (0.5 + drive * 0.5) + ")";
                            for (var j = 0; j <= steps; j++) {
                                var a2 = (j / steps) * Math.PI * 2;
                                var r2 = baseR - 14
                                       + Math.sin(a2 * 5 - phase * 1.4) * waveAmp * 0.6
                                       + Math.sin(a2 * 9 + phase * 1.9) * waveAmp * 0.35;
                                var x2 = cx + Math.cos(a2) * r2;
                                var y2 = cy + Math.sin(a2) * r2;
                                if (j === 0) ctx.moveTo(x2, y2);
                                else ctx.lineTo(x2, y2);
                            }
                            ctx.closePath();
                            ctx.stroke();
                        }
                    }

                    Rectangle {
                        id: bigVinyl
                        anchors.centerIn: parent
                        width: 290; height: 290
                        radius: 145
                        color: "#0B0B14"
                        border.color: "#1E1E2A"
                        border.width: 1

                        // Subtle pulse with bass
                        property real bassPulse: {
                            var a = playback.analyzer ? playback.analyzer.amplitudes : null;
                            if (!a || a.length === 0) return 0;
                            var s = 0;
                            for (var i = 0; i < 8 && i < a.length; i++) s += a[i];
                            return s / 8;
                        }
                        scale: playback.playing ? (1.0 + bassPulse * 0.06) : 1.0
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

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

                    // The bar area (inset from edges)
                    Item {
                        id: barsInner
                        anchors.fill: parent
                        anchors.leftMargin: 30
                        anchors.rightMargin: 30
                        anchors.topMargin: 60
                        anchors.bottomMargin: 60

                        Repeater {
                            model: 48
                            delegate: Item {
                                required property int index

                                property real barW: (barsInner.width - 47 * 3) / 48
                                x: index * (barW + 3)
                                y: 0
                                width: barW
                                height: barsInner.height

                                // Raw FFT energy for this bar
                                property real energy: {
                                    var amps = playback.analyzer ? playback.analyzer.amplitudes : null;
                                    if (!amps || amps.length === 0) return 0;
                                    var i = Math.min(Math.floor(index * (amps.length / 48)), amps.length - 1);
                                    return amps[i] || 0;
                                }

                                // Amplify so bars actually move
                                property real displayH: Math.max(3,
                                    barsInner.height * Math.min(1.0, energy * 1.0))

                                // Neon palette: cyan → purple → magenta across width
                                property real baseHue: 180 + (index / 47.0) * 130
                                property real hueOffset: 0
                                NumberAnimation on hueOffset {
                                    running: playback.playing
                                    loops: Animation.Infinite
                                    from: -10
                                    to: 10
                                    duration: 3000 + (index % 8) * 200
                                }
                                property real finalHue: baseHue + hueOffset

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: parent.displayH
                                    radius: 2

                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: Qt.hsla(finalHue / 360, 0.85, 0.62, 1.0)
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: Qt.hsla(((finalHue + 40) % 360) / 360, 0.85, 0.5, 1.0)
                                        }
                                    }

                                    Behavior on height {
                                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                                    }

                                    // MultiEffect only while playing — cuts idle cost by 48x
                                    layer.enabled: playback.playing
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.hsla(finalHue / 360, 0.9, 0.6, 1.0)
                                        shadowBlur: 0.7
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

        // ============================================
        //  LYRICS PANEL (slides in from right)
        // ============================================
        LyricsPanel {
            id: lyricsPanel

            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.verticalCenter: parent.verticalCenter

            width: Math.min(parent.width * 0.42, 520)
            height: parent.height - 220

            opacity: root.showLyrics ? 1 : 0
            x: root.showLyrics ? 0 : 80
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

            artistName: playback.artist
            trackTitle: playback.title
            albumName: playback.album
            durationSec: Math.floor(playback.duration / 1000)
            currentPositionMs: playback.position
            filePath: playback.filePath

            accentCyan:   root.accentCyan
            accentPurple: root.accentPurple
            textPrimary:  root.textPrimary
            textDim:      root.textDim
            textMute:     root.textMute

            onSeekRequested: function(timeMs) {
                playback.seek(timeMs);
            }

            onAddLyricsRequested: {
                root.showLyricsDialog = true;
            }

            onRefreshRequested: {
                var fp = "";
                if (playback.currentIndex >= 0) {
                    var tracks = library.tracks();
                    if (playback.currentIndex < tracks.length)
                        fp = tracks[playback.currentIndex].filePath;
                }
                if (fp !== "") {
                    console.log("VOID: refresh requested for", fp);
                    lyrics.forceFetch(fp, playback.artist, playback.title,
                                      playback.album,
                                      Math.floor(playback.duration / 1000));
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

    // Refresh artist list when new artist images arrive
    Connections {
        target: artistImages
        function onImageReady(artistName, imageUrl) {
            // Update the artist list in-place
            var list = root.artistList.slice();
            var changed = false;
            for (var i = 0; i < list.length; i++) {
                if (list[i].name === artistName) {
                    var copy = Object.assign({}, list[i]);
                    copy.artistImageUrl = imageUrl;
                    list[i] = copy;
                    changed = true;
                }
            }
            if (changed) root.artistList = list;
        }
    }

    function openArtist(artistName) {
        var list = [];
        for (var i = 0; i < trackModel.rowCount(); i++) {
            var idx = trackModel.index(i, 0);
            var art = trackModel.data(idx, 259);
            if (!art) art = "Unknown Artist";
            if (art !== artistName) continue;
            list.push({
                index: i,
                title:        trackModel.data(idx, 258),
                artist:       art,
                album:        trackModel.data(idx, 260),
                durationText: trackModel.data(idx, 264),
                coverUrl:     trackModel.data(idx, 266),
                filePath:     trackModel.data(idx, 257)
            });
        }
        root.artistTracks = list;
        root.artistDetail = { name: artistName };
        console.log("VOID: openArtist:", artistName, "→", list.length, "tracks");
    }

    function closeArtist() {
        root.artistDetail = null;
        root.artistTracks = [];
    }

    function openAlbum(albumName, artistName) {
        var list = [];
        for (var i = 0; i < trackModel.rowCount(); i++) {
            var idx = trackModel.index(i, 0);
            var alb = trackModel.data(idx, 260);
            var art = trackModel.data(idx, 259);
            if (alb === albumName && art === artistName) {
                list.push({
                    index: i,
                    title:        trackModel.data(idx, 258),
                    artist:       art,
                    album:        alb,
                    durationText: trackModel.data(idx, 264),
                    coverUrl:     trackModel.data(idx, 266),
                    filePath:     trackModel.data(idx, 257),
                    trackNumber:  trackModel.data(idx, 268)
                });
            }
        }
        list.sort(function(a, b) {
            return (a.trackNumber || 0) - (b.trackNumber || 0);
        });
        root.albumTracks = list;
        root.albumDetail = { album: albumName, artist: artistName };
        console.log("VOID: openAlbum:", albumName, "→", list.length, "tracks");
        for (var d = 0; d < Math.min(list.length, 3); d++) {
            console.log("  [" + d + "]", list[d].title, "cover:", list[d].coverUrl);
        }
    }

    function closeAlbum() {
        root.albumDetail = null;
        root.albumTracks = [];
    }

    // ============================================
    //  LYRICS SYNC DIALOG
    // ============================================
    LyricsSyncDialog {
        id: lyricsSyncDialog

        anchors.fill: parent
        visible: root.showLyricsDialog
        opacity: visible ? 1 : 0
        z: 200

        Behavior on opacity { NumberAnimation { duration: 220 } }

        trackTitle: playback.title
        artistName: playback.artist

        accentCyan:   root.accentCyan
        accentPurple: root.accentPurple
        textPrimary:  root.textPrimary
        textDim:      root.textDim
        textMute:     root.textMute
        bgPanel:      root.bgPanel

        onCloseRequested: root.showLyricsDialog = false

        onSaveRequested: function(lrcText, isSynced) {
            var fp = "";
            if (playback.currentIndex >= 0) {
                var tracks = library.tracks();
                if (playback.currentIndex < tracks.length)
                    fp = tracks[playback.currentIndex].filePath;
            }
            if (fp === "") {
                console.log("VOID: cannot save lyrics — no file path");
                return;
            }
            library.saveCustomLyrics(fp, lrcText, isSynced);
            console.log("VOID: saved custom lyrics for", fp);

            // Reload lyrics panel with the new content
            lyrics.loadCustomText(lrcText, isSynced);

            root.showLyricsDialog = false;
        }
    }

    function countInCategory(categoryName) {
        var count = 0;
        for (var path in trackCategories) {
            if (hasCategory(path, categoryName)) count++;
        }
        return count;
    }

    function buildAlbumList() {
        var groups = {};
        for (var i = 0; i < trackModel.rowCount(); i++) {
            var idx = trackModel.index(i, 0);
            var albumName  = trackModel.data(idx, 260);
            var artistName = trackModel.data(idx, 259);
            var coverUrl   = trackModel.data(idx, 266);
            if (!albumName) albumName = "Unknown Album";
            if (!artistName) artistName = "Unknown Artist";
            var key = albumName + "||" + artistName;
            if (groups[key] === undefined) {
                groups[key] = {
                    album: albumName,
                    artist: artistName,
                    coverUrl: coverUrl || "",
                    count: 0
                };
            }
            groups[key].count++;
        }
        var list = [];
        for (var k in groups) list.push(groups[k]);
        return list;
    }

    function buildArtistList() {
        var groups = {};
        for (var i = 0; i < trackModel.rowCount(); i++) {
            var idx = trackModel.index(i, 0);
            var artistName = trackModel.data(idx, 259);
            var coverUrl   = trackModel.data(idx, 266);
            if (!artistName) artistName = "Unknown Artist";
            if (groups[artistName] === undefined) {
                groups[artistName] = {
                    name: artistName,
                    count: 0,
                    coverUrl: coverUrl || "",
                    artistImageUrl: artistImages.get(artistName) || ""
                };
            } else if (groups[artistName].coverUrl === "" && coverUrl) {
                groups[artistName].coverUrl = coverUrl;
            }
            groups[artistName].count++;
        }
        var list = [];
        for (var k in groups) list.push(groups[k]);
        return list;
    }

    function fmt(ms) {
        if (!ms || ms < 0) return "0:00";
        const s = Math.floor(ms / 1000);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}