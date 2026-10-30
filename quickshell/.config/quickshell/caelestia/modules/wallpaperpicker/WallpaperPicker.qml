import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.utils

Scope {
    id: root

    property bool open: false
    property int selectedTab: 0 // 0: Images, 1: Live

    readonly property string thumbsDir: `${Paths.home}/.cache/wallpaper-thumbs`

    FontLoader {
        id: titleFont
        source: "file:///home/sidlakhani/.local/share/fonts/ClashDisplay-Bold.ttf"
    }

    FontLoader {
        id: syneFont
        source: "file:///home/sidlakhani/.local/share/fonts/Syne.ttf"
    }

    FontLoader {
        id: orbitronFont
        source: "file:///home/sidlakhani/.local/share/fonts/Orbitron.ttf"
    }

    function originalOf(thumbName: string, isLive: bool): string {
        const cleanName = String(thumbName).replace(/\.jpg$/, "");
        return isLive
            ? `${Paths.wallsdir}/live/${cleanName}`
            : `${Paths.wallsdir}/images/${cleanName}`;
    }

    function apply(thumbName: string, isLive: bool): void {
        const orig = root.originalOf(thumbName, isLive);
        Quickshell.execDetached([
            "/usr/bin/bash",
            "-c",
            "cd /home/sidlakhani && exec /home/sidlakhani/.local/bin/wallpaper set \"$1\"",
            "wallpaper",
            orig
        ]);
        root.open = false;
    }

    Process {
        id: thumbsProc
        command: ["/home/sidlakhani/.local/bin/wall-thumbs"]
    }

    function refreshThumbs(): void {
        if (!thumbsProc.running)
            thumbsProc.running = true;
    }

    Component.onCompleted: root.refreshThumbs()

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "wallpaperPicker"
        description: "Toggle 3D wallpaper picker"
        onPressed: root.open = !root.open
    }

    IpcHandler {
        target: "wallpaperPicker"

        function toggle(): void {
            root.open = !root.open;
        }

        function openPicker(): void {
            root.open = true;
        }

        function closePicker(): void {
            root.open = false;
        }
    }

    FileSystemModel {
        id: imagesThumbModel
        path: `${root.thumbsDir}/images`
        nameFilters: ["*.jpg"]
        watchChanges: true
    }

    FileSystemModel {
        id: liveThumbModel
        path: `${root.thumbsDir}/live`
        nameFilters: ["*.jpg"]
        watchChanges: true
    }

    readonly property var currentList: root.selectedTab === 0 ? imagesThumbModel.entries : liveThumbModel.entries
    readonly property int imagesCount: imagesThumbModel.entries ? imagesThumbModel.entries.length : 0
    readonly property int liveCount: liveThumbModel.entries ? liveThumbModel.entries.length : 0

    onSelectedTabChanged: {
        carousel.currentIndex = 0;
    }

    PanelWindow {
        id: win

        screen: ShellState.focusedScreen
        visible: root.open || stage.opacity > 0
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusiveZone: 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:wallpaper"

        HyprlandFocusGrab {
            windows: [win]
            active: root.open
            onCleared: root.open = false
        }

        Item {
            id: stage

            anchors.fill: parent
            focus: true
            opacity: root.open ? 1 : 0
            scale: root.open ? 1.0 : 0.94
            transformOrigin: Item.Center

            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? 220 : 130
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: root.open ? 240 : 130
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }

            Connections {
                target: root
                function onOpenChanged(): void {
                    if (!root.open)
                        return;
                    stage.forceActiveFocus();
                    root.refreshThumbs();
                }
            }

            Keys.onEscapePressed: root.open = false
            Keys.onLeftPressed: carousel.decrementCurrentIndex()
            Keys.onRightPressed: carousel.incrementCurrentIndex()
            Keys.onReturnPressed: carousel.applyCurrent()
            Keys.onEnterPressed: carousel.applyCurrent()
            Keys.onTabPressed: (event) => {
                root.selectedTab = (root.selectedTab === 0 ? 1 : 0);
                event.accepted = true;
            }
            Keys.onBacktabPressed: (event) => {
                root.selectedTab = (root.selectedTab === 0 ? 1 : 0);
                event.accepted = true;
            }

            WheelHandler {
                property real accumulator: 0

                onWheel: (e) => {
                    accumulator += (e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x);
                    if (accumulator <= -60) {
                        carousel.incrementCurrentIndex();
                        accumulator = 0;
                    } else if (accumulator >= 60) {
                        carousel.decrementCurrentIndex();
                        accumulator = 0;
                    }
                }
            }

            // Subtle dark overlay (~28%)
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.0, 0.0, 0.0, 0.28)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }
            }

            // High-Craft Glass Segmented Control Deck (Top)
            Item {
                id: headerDeck

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 36
                implicitHeight: 52
                implicitWidth: tabTrack.implicitWidth

                // Main Pill Track
                StyledRect {
                    id: tabTrack

                    anchors.fill: parent
                    radius: 26
                    color: Qt.rgba(0.07, 0.07, 0.10, 0.88)
                    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.14)
                    border.width: 1

                    // Subtle glass top-edge hairline highlight
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 32
                        height: 1
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
                    }

                    // Smooth Sliding Elevated Active Pill
                    StyledRect {
                        id: tabPill

                        y: 4
                        height: parent.height - 8
                        radius: 22
                        color: Colours.palette.m3surfaceContainerHighest
                        border.width: 1.5
                        border.color: root.selectedTab === 1 ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        readonly property Item targetItem: root.selectedTab === 0 ? imagesTabItem : liveTabItem
                        x: targetItem ? (tabRow.x + targetItem.x) : 4
                        width: targetItem ? targetItem.width : 130

                        Behavior on x {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.15
                            }
                        }
                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Row {
                        id: tabRow

                        anchors.centerIn: parent
                        spacing: 8

                        // Tab 0: Images
                        Item {
                            id: imagesTabItem

                            implicitHeight: 44
                            implicitWidth: imagesContentRow.implicitWidth + 32

                            Row {
                                id: imagesContentRow

                                anchors.centerIn: parent
                                spacing: 9

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "photo_library"
                                    color: root.selectedTab === 0 ? Colours.palette.m3primary : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("Images")
                                    color: root.selectedTab === 0 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    font.family: titleFont.name ? titleFont.name : "Clash Display"
                                    font.pixelSize: 14
                                    font.weight: root.selectedTab === 0 ? Font.Bold : Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                StyledRect {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.imagesCount > 0
                                    implicitHeight: 22
                                    implicitWidth: Math.max(22, imgCountText.implicitWidth + 12)
                                    radius: 11
                                    color: root.selectedTab === 0
                                        ? Colours.palette.m3primaryContainer
                                        : Colours.tPalette.m3surfaceContainerHigh

                                    StyledText {
                                        id: imgCountText
                                        anchors.centerIn: parent
                                        text: String(root.imagesCount)
                                        color: root.selectedTab === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedTab = 0;
                                    stage.forceActiveFocus();
                                }
                            }
                        }

                        // Tab 1: Live
                        Item {
                            id: liveTabItem

                            implicitHeight: 44
                            implicitWidth: liveContentRow.implicitWidth + 32

                            Row {
                                id: liveContentRow

                                anchors.centerIn: parent
                                spacing: 9

                                MaterialIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "movie"
                                    color: root.selectedTab === 1 ? Colours.palette.m3primary : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: qsTr("Live")
                                    color: root.selectedTab === 1 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                    font.family: titleFont.name ? titleFont.name : "Clash Display"
                                    font.pixelSize: 14
                                    font.weight: root.selectedTab === 1 ? Font.Bold : Font.DemiBold
                                    font.letterSpacing: 0.8
                                }

                                StyledRect {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.liveCount > 0
                                    implicitHeight: 22
                                    implicitWidth: Math.max(22, liveCountText.implicitWidth + 12)
                                    radius: 11
                                    color: root.selectedTab === 1
                                        ? Colours.palette.m3primaryContainer
                                        : Colours.tPalette.m3surfaceContainerHigh

                                    StyledText {
                                        id: liveCountText
                                        anchors.centerIn: parent
                                        text: String(root.liveCount)
                                        color: root.selectedTab === 1 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedTab = 1;
                                    stage.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // 3D Coverflow Carousel
            ListView {
                id: carousel

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -28
                }
                height: 400
                orientation: ListView.Horizontal
                model: root.currentList

                property real iw: 680
                property real ih: 382
                property real skew: -0.32
                property real bw: 2
                property real slotW: 340
                property real sideBase: 0.58
                readonly property real imgW: iw + ih * Math.abs(skew) + 12

                spacing: 0
                clip: false
                cacheBuffer: 2500
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - slotW) / 2
                preferredHighlightEnd: (width + slotW) / 2
                highlightMoveDuration: 340
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds
                maximumFlickVelocity: 5000

                function applyCurrent(): void {
                    if (!root.currentList || currentIndex < 0 || currentIndex >= root.currentList.length)
                        return;
                    const item = root.currentList[currentIndex];
                    if (item)
                        root.apply(item.name, root.selectedTab === 1);
                }

                delegate: Item {
                    id: slot

                    required property var modelData
                    required property int index

                    width: carousel.slotW
                    height: carousel.height

                    readonly property real d: (x + width / 2 - (carousel.contentX + carousel.width / 2)) / carousel.slotW
                    readonly property real ad: Math.abs(d)
                    readonly property real sc: ad <= 1
                        ? carousel.sideBase + (1 - carousel.sideBase) * Math.pow(1 - ad, 1.35)
                        : carousel.sideBase * Math.pow(0.86, ad - 1)

                    z: Math.round(100 - ad * 10)
                    opacity: Math.max(0, Math.min(1, 1.15 - 0.35 * ad))

                    Item {
                        id: card

                        anchors.centerIn: parent
                        width: carousel.iw
                        height: carousel.ih
                        scale: slot.sc
                        transformOrigin: Item.Center

                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(
                                1, carousel.skew, 0, -carousel.skew * carousel.ih / 2,
                                0, 1, 0, 0,
                                0, 0, 1, 0,
                                0, 0, 0, 1
                            )
                        }

                        // Card frame
                        Rectangle {
                            anchors.fill: parent
                            color: Colours.palette.m3surfaceContainerLowest
                            border.width: slot.ad < 0.5 ? 2 : 1
                            border.color: slot.ad < 0.5 ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                            radius: 6
                        }

                        // Clipped inner image with inverse shear
                        Item {
                            anchors.fill: parent
                            anchors.margins: carousel.bw
                            clip: true

                            Image {
                                anchors.centerIn: parent
                                width: carousel.imgW
                                height: carousel.ih
                                fillMode: Image.PreserveAspectCrop
                                source: slot.modelData ? (`file://${slot.modelData.path}`) : ""
                                asynchronous: true
                                cache: true
                                mipmap: true
                                sourceSize: Qt.size(carousel.imgW, carousel.ih)

                                transform: Matrix4x4 {
                                    matrix: Qt.matrix4x4(
                                        1, -carousel.skew, 0, carousel.skew * carousel.ih / 2,
                                        0, 1, 0, 0,
                                        0, 0, 1, 0,
                                        0, 0, 0, 1
                                    )
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (slot.ad < 0.5)
                                    carousel.applyCurrent();
                                else
                                    carousel.currentIndex = slot.index;
                            }
                        }
                    }
                }
            }

            // High-Craft Cinematic Title & Info Deck
            Row {
                anchors.top: carousel.bottom
                anchors.topMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                readonly property var focusedItem: (root.currentList && carousel.currentIndex >= 0 && carousel.currentIndex < root.currentList.length)
                    ? root.currentList[carousel.currentIndex]
                    : null

                readonly property string rawName: focusedItem ? focusedItem.name.replace(/\.jpg$/, "") : ""
                readonly property string cleanTitle: rawName
                    .replace(/\.[^.]+$/, "")
                    .replace(/\.(1920x1080|3840x2160|2560x1440|1080p|4k|800)/gi, "")
                    .replace(/[-_.]/g, " ")
                    .replace(/\b\w/g, l => l.toUpperCase())
                    .trim()

                // Bold Cinematic Hero Title (Clash Display / Syne)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.cleanTitle || ""
                    color: Colours.palette.m3onSurface
                    font.family: titleFont.name ? titleFont.name : (syneFont.name ? syneFont.name : "Clash Display")
                    font.pixelSize: 32
                    font.weight: Font.Black
                    font.letterSpacing: 1.4
                }

                // Subtle bullet separator
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "•"
                    color: Qt.rgba(Colours.palette.m3onSurface.r, Colours.palette.m3onSurface.g, Colours.palette.m3onSurface.b, 0.45)
                    font.pixelSize: 18
                }

                // White Number Counter: "01 / 08"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${String(carousel.currentIndex + 1).padStart(2, "0")} / ${String(root.currentList ? root.currentList.length : 0).padStart(2, "0")}`
                    color: Colours.palette.m3onSurface
                    font.family: titleFont.name ? titleFont.name : (syneFont.name ? syneFont.name : "Clash Display")
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }
            }

            // Empty state
            StyledText {
                anchors.centerIn: parent
                visible: !root.currentList || root.currentList.length === 0
                text: qsTr("No wallpapers found")
                color: Colours.palette.m3outline
                font: Tokens.font.title.small
            }
        }
    }
}
