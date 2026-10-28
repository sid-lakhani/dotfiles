pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services
import qs.utils

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content

    property int selectedTab: 0 // 0: Images, 1: Solids, 2: Live
    property int imagesCount: 0
    property int solidsCount: 0
    property int liveCount: 0

    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly property int numItems: {
        const screen = (QsWindow.window as QsWindow)?.screen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    FileSystemModel {
        id: liveVideos
        path: `${Paths.wallsdir}/live`
        nameFilters: ["*.mp4", "*.mkv", "*.webm", "*.gif"]
    }

    StyledRect {
        id: tabContainer

        z: 10
        anchors.top: parent.top
        anchors.topMargin: Tokens.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter

        implicitHeight: 38
        implicitWidth: tabRow.implicitWidth + 8
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHigh
        border.color: Colours.palette.m3outlineVariant
        border.width: 1

        Row {
            id: tabRow

            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: [
                    { id: 0, text: qsTr("Images"), icon: "image", count: root.imagesCount },
                    { id: 1, text: qsTr("Solids"), icon: "palette", count: root.solidsCount },
                    { id: 2, text: qsTr("Live"), icon: "play_circle", count: root.liveCount }
                ]

                delegate: StyledRect {
                    id: chip

                    required property var modelData

                    readonly property bool isSelected: root.selectedTab === modelData.id

                    implicitHeight: 30
                    implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
                    radius: Tokens.rounding.full
                    color: isSelected ? Colours.palette.m3primary : "transparent"

                    Row {
                        id: chipRow

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.icon
                            color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.text
                            color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.large
                        }

                        StyledRect {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: chip.modelData.count > 0
                            implicitHeight: 18
                            implicitWidth: Math.max(18, countText.implicitWidth + 8)
                            radius: Tokens.rounding.full
                            color: chip.isSelected ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHighest

                            StyledText {
                                id: countText
                                anchors.centerIn: parent
                                text: String(chip.modelData.count)
                                color: chip.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                        }
                    }

                    StateLayer {
                        radius: parent.radius
                        color: chip.isSelected ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                        onClicked: {
                            root.selectedTab = chip.modelData.id;
                        }
                    }

                    Behavior on color {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string rawSearch: root.search.text.split(" ").slice(1).join(" ")

        values: {
            let search = rawSearch.trim();
            const lower = search.toLowerCase();
            if (lower === "live" || lower.startsWith("live ") || lower.startsWith("video ") || lower === "video") {
                if (root.selectedTab !== 2)
                    root.selectedTab = 2;
                search = search.replace(/^(live|video|anim)\s*/i, "");
            } else if (lower === "solids" || lower === "solid" || lower.startsWith("solids ") || lower.startsWith("solid ") || lower.startsWith("pastel ") || lower === "pastel") {
                if (root.selectedTab !== 1)
                    root.selectedTab = 1;
                search = search.replace(/^(solids?|pastel|colou?rs?)\s*/i, "");
            } else if (lower === "images" || lower === "image" || lower.startsWith("images ") || lower.startsWith("image ") || lower.startsWith("img ")) {
                if (root.selectedTab !== 0)
                    root.selectedTab = 0;
                search = search.replace(/^(images?|img)\s*/i, "");
            }

            const staticWalls = Wallpapers.query(search)
                .filter(w => !w.path.includes("/live/") && !w.path.includes("/animated/") && !w.path.includes("/solids/"))
                .map(w => {
                    const base = w.name.replace(/\.[^.]+$/, "");
                    const cleanName = base.replace(/[-_.]/g, " ").replace(/\b\w/g, l => l.toUpperCase());
                    return {
                        name: cleanName,
                        path: w.path,
                        relativePath: w.relativePath
                    };
                });

            const solidWalls = Wallpapers.query(search)
                .filter(w => w.path.includes("/solids/"))
                .map(w => {
                    const base = w.name.replace(/\.[^.]+$/, "");
                    const cleanName = base.replace(/[-_.]/g, " ").replace(/\b\w/g, l => l.toUpperCase());
                    return {
                        name: cleanName,
                        path: w.path,
                        relativePath: w.relativePath
                    };
                });

            const liveDir = `${Paths.wallsdir}/live`;
            const animated = [];

            if (liveVideos.entries) {
                for (let i = 0; i < liveVideos.entries.length; i++) {
                    const entry = liveVideos.entries[i];
                    const isGif = entry.name.endsWith(".gif");
                    const base = entry.name.replace(/\.[^.]+$/, "");
                    const cleanTitle = base
                        .replace(/\.(1920x1080|3840x2160|2560x1440|1080p|4k|800)/gi, "")
                        .replace(/[-_.]/g, " ")
                        .replace(/\b\w/g, l => l.toUpperCase())
                        .trim();
                    const thumbPath = isGif ? entry.path : `${liveDir}/.thumbnails/${base}.jpg`;

                    if (!search || cleanTitle.toLowerCase().includes(search.toLowerCase()) || entry.name.toLowerCase().includes(search.toLowerCase())) {
                        animated.push({
                            name: cleanTitle,
                            path: entry.path,
                            thumbnail: thumbPath
                        });
                    }
                }
            }

            root.imagesCount = staticWalls.length;
            root.solidsCount = solidWalls.length;
            root.liveCount = animated.length;

            if (root.selectedTab === 0)
                return staticWalls;
            if (root.selectedTab === 1)
                return solidWalls;
            if (root.selectedTab === 2)
                return animated;
            return staticWalls;
        }
        onValuesChanged: root.currentIndex = rawSearch ? 0 : values.findIndex(w => w.path === Wallpapers.actualCurrent)
    }

    onSelectedTabChanged: {
        currentIndex = 0;
    }

    Component.onCompleted: currentIndex = Wallpapers.list.findIndex(w => w.path === Wallpapers.actualCurrent)
    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem) {
            const item = (currentItem as WallpaperItem).modelData;
            const target = item?.thumbnail || item?.path;
            if (target)
                Wallpapers.preview(target);
        }
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        screenState: root.screenState
    }

    path: Path {
        startY: (root.height + tabContainer.implicitHeight + tabContainer.anchors.topMargin) / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }
}
