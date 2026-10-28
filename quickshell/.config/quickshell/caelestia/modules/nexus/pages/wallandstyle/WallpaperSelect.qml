pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpapers")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Browse")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: qsTr("Select an image")
                    filterLabel: qsTr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Quickshell.shellPath("assets/wallpaper.webp")
            text: qsTr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(Quickshell.shellPath("assets/wallpaper.webp"));
                root.nState.closeSubPage();
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Images")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: localWalls.count > 0

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                id: localWalls

                model: {
                    const walls = Wallpapers.list;
                    const list = [];
                    for (const w of walls) {
                        if (w.path.includes("/live/") || w.path.includes("/animated/") || w.path.includes("/solids/"))
                            continue;
                        list.push(w);
                    }
                    list.sort((a, b) => a.name.localeCompare(b.name));
                    while (list.length < Config.nexus.wallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property FileSystemEntry modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    readonly property string baseName: modelData ? modelData.name.replace(/\.[^.]+$/, "") : ""
                    readonly property string cleanTitle: baseName.replace(/[-_.]/g, " ").replace(/\b\w/g, l => l.toUpperCase())

                    Layout.fillWidth: true
                    source: String(modelData?.path ?? "")
                    text: cleanTitle || modelData?.name || ""
                    onClicked: {
                        Wallpapers.setWallpaper(modelData.path);
                        root.nState.closeSubPage();
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Solids")
            font: Tokens.font.title.small
        }

        FileSystemModel {
            id: solidsModel
            path: `${Paths.wallsdir}/solids`
            filter: FileSystemModel.Images
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: solidsModel.entries

                WallItem {
                    required property FileSystemEntry modelData

                    readonly property string baseName: modelData ? modelData.name.replace(/\.[^.]+$/, "") : ""
                    readonly property string cleanTitle: baseName.replace(/[-_.]/g, " ").replace(/\b\w/g, l => l.toUpperCase())

                    Layout.fillWidth: true
                    source: String(modelData?.path ?? "")
                    text: cleanTitle
                    onClicked: {
                        Wallpapers.setWallpaper(modelData.path);
                        root.nState.closeSubPage();
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: qsTr("Live")
            font: Tokens.font.title.small
        }

        FileSystemModel {
            id: liveModel
            path: `${Paths.wallsdir}/live`
            nameFilters: ["*.mp4", "*.mkv", "*.webm", "*.gif"]
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: liveModel.entries

                WallItem {
                    required property FileSystemEntry modelData

                    readonly property bool isGif: modelData ? modelData.name.endsWith(".gif") : false
                    readonly property string baseName: modelData ? modelData.name.replace(/\.[^.]+$/, "") : ""
                    readonly property string cleanTitle: baseName
                        .replace(/\.(1920x1080|3840x2160|2560x1440|1080p|4k|800)/gi, "")
                        .replace(/[-_.]/g, " ")
                        .replace(/\b\w/g, l => l.toUpperCase())
                        .trim()

                    Layout.fillWidth: true
                    source: isGif ? (modelData?.path ?? "") : `${Paths.wallsdir}/live/.thumbnails/${baseName}.jpg`
                    text: cleanTitle
                    onClicked: {
                        Wallpapers.commitLive(
                            isGif ? (modelData?.path ?? "") : `${Paths.wallsdir}/live/.thumbnails/${baseName}.jpg`,
                            modelData.path,
                            isGif
                        );
                        root.nState.closeSubPage();
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: localWalls.count === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No local wallpapers found")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }
}
