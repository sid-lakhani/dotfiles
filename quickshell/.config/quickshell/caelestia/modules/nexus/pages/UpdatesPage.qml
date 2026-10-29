import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property int total: 0
    property int repoCount: 0
    property int aurCount: 0
    property string lastChecked: ""
    property var packages: []
    property bool checking: false

    readonly property var repoPackages: {
        const pkgs = root.packages;
        if (!Array.isArray(pkgs))
            return [];
        return pkgs.filter(p => {
            if (!p)
                return false;
            return p.type !== "aur" && p.source !== "aur" && !p.aur && p.repo !== "aur";
        });
    }

    readonly property var aurPackages: {
        const pkgs = root.packages;
        if (!Array.isArray(pkgs))
            return [];
        return pkgs.filter(p => {
            if (!p)
                return false;
            return p.type === "aur" || p.source === "aur" || !!p.aur || p.repo === "aur";
        });
    }

    title: qsTr("Updates")

    function checkNow() {
        root.checking = true;
        checkProc.running = true;
    }

    function upgrade() {
        Quickshell.execDetached(["/home/sidlakhani/.local/bin/check-updates", "upgrade"]);
    }

    function parseResult(jsonText) {
        if (!jsonText || !jsonText.trim())
            return;
        try {
            let str = jsonText.trim();
            const firstBrace = str.indexOf("{");
            const lastBrace = str.lastIndexOf("}");
            if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
                str = str.substring(firstBrace, lastBrace + 1);
            }
            const data = JSON.parse(str);
            let pkgs = [];
            if (Array.isArray(data.packages)) {
                pkgs = data.packages;
            } else if (Array.isArray(data.repo) || Array.isArray(data.aur)) {
                const r = (data.repo || []).map(p => typeof p === "string" ? { name: p, type: "repo" } : Object.assign({ type: "repo" }, p));
                const a = (data.aur || []).map(p => typeof p === "string" ? { name: p, type: "aur" } : Object.assign({ type: "aur" }, p));
                pkgs = r.concat(a);
            }

            root.packages = pkgs;

            const repoList = pkgs.filter(p => p && p.type !== "aur" && p.source !== "aur" && !p.aur && p.repo !== "aur");
            const aurList = pkgs.filter(p => p && (p.type === "aur" || p.source === "aur" || !!p.aur || p.repo === "aur"));

            root.repoCount = data.repoCount ?? (data.repo_count ?? repoList.length);
            root.aurCount = data.aurCount ?? (data.aur_count ?? aurList.length);
            root.total = data.total ?? (root.repoCount + root.aurCount);

            if (data.lastChecked || data.last_checked) {
                root.lastChecked = data.lastChecked ?? data.last_checked;
            } else if (data.timestamp) {
                root.lastChecked = new Date(data.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            } else {
                root.lastChecked = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            }
        } catch (e) {
            console.warn("Failed to parse updates JSON:", e);
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: cacheProc

            command: ["/home/sidlakhani/.local/bin/check-updates", "cache"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: root.parseResult(text)
            }
        }

        Process {
            id: checkProc

            command: ["/home/sidlakhani/.local/bin/check-updates", "status"]
            stdout: StdioCollector {
                onStreamFinished: {
                    root.checking = false;
                    root.parseResult(text);
                }
            }
            onExited: root.checking = false
        }

        // Hero card
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: heroLayout.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: heroLayout

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.total > 0 ? "system_update" : "check_circle"
                    color: root.total > 0 ? Colours.palette.m3primary : Colours.palette.m3success
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.8).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.total > 0
                        ? (root.total === 1 ? qsTr("1 update available") : qsTr("%1 updates available").arg(root.total))
                        : qsTr("Your system is up to date")
                    font: Tokens.font.headline.builders.small.width(105).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.checking
                        ? qsTr("Checking for updates…")
                        : (root.lastChecked ? qsTr("Last checked at %1").arg(root.lastChecked) : qsTr("Never checked"))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.medium

                    ButtonBase {
                        id: checkBtn

                        isRound: true
                        shapeMorph: true
                        type: ButtonBase.Tonal
                        inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                        inactiveOnColour: Colours.palette.m3onSurface
                        disabled: root.checking
                        onClicked: root.checkNow()

                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.medium
                        implicitWidth: checkBtnLayout.implicitWidth + horizontalPadding * 2
                        implicitHeight: checkBtnLayout.implicitHeight + verticalPadding * 2

                        RowLayout {
                            id: checkBtnLayout

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

                            Loader {
                                Layout.alignment: Qt.AlignVCenter
                                active: true
                                sourceComponent: root.checking ? checkLoadingComp : checkIconComp
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.topMargin: 1
                                text: qsTr("Check for updates")
                                color: checkBtn.onColour
                                font: checkBtn.font
                            }
                        }

                        Component {
                            id: checkLoadingComp

                            LoadingIndicator {
                                implicitSize: Math.round(Tokens.font.body.medium.pointSize * 1.3)
                                color: checkBtn.onColour
                            }
                        }

                        Component {
                            id: checkIconComp

                            MaterialIcon {
                                text: "refresh"
                                color: checkBtn.onColour
                                fontStyle: Tokens.font.icon.small
                            }
                        }
                    }

                    ButtonBase {
                        id: upgradeBtn

                        visible: root.total > 0
                        isRound: true
                        shapeMorph: true
                        type: ButtonBase.Filled
                        inactiveColour: Colours.palette.m3primary
                        inactiveOnColour: Colours.palette.m3onPrimary
                        onClicked: root.upgrade()

                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.medium
                        implicitWidth: upgradeBtnLayout.implicitWidth + horizontalPadding * 2
                        implicitHeight: upgradeBtnLayout.implicitHeight + verticalPadding * 2

                        RowLayout {
                            id: upgradeBtnLayout

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                Layout.alignment: Qt.AlignVCenter
                                text: "system_update"
                                color: upgradeBtn.onColour
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.topMargin: 1
                                text: qsTr("Update now")
                                color: upgradeBtn.onColour
                                font: upgradeBtn.font
                            }
                        }
                    }
                }
            }
        }

        // Official Repositories
        SectionHeader {
            visible: root.repoCount > 0
            text: qsTr("Official Repositories (%1)").arg(root.repoCount)
        }

        Repeater {
            model: root.repoPackages

            ConnectedRect {
                id: repoRow

                required property var modelData
                required property int index

                readonly property var pkg: modelData ?? ({})
                readonly property string pkgName: pkg.name ?? pkg.package ?? (typeof pkg === "string" ? pkg : "")
                readonly property string oldVer: pkg.oldVersion ?? pkg.old_version ?? pkg.old ?? ""
                readonly property string newVer: pkg.newVersion ?? pkg.new_version ?? pkg.new ?? pkg.version ?? ""
                readonly property string repoTag: pkg.repo ? pkg.repo.toUpperCase() : "REPO"

                Layout.fillWidth: true
                first: index === 0
                last: index === root.repoPackages.length - 1
                implicitHeight: repoRowLayout.implicitHeight + repoRowLayout.anchors.margins * 2

                RowLayout {
                    id: repoRowLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        StyledText {
                            Layout.fillWidth: true
                            text: repoRow.pkgName
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: Tokens.spacing.extraSmall
                            visible: repoRow.oldVer !== "" || repoRow.newVer !== ""

                            StyledText {
                                visible: repoRow.oldVer !== ""
                                text: repoRow.oldVer
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.medium
                            }

                            MaterialIcon {
                                visible: repoRow.oldVer !== "" && repoRow.newVer !== ""
                                text: "arrow_forward"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                visible: repoRow.newVer !== ""
                                text: repoRow.newVer
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    // Pill badge
                    StyledRect {
                        Layout.alignment: Qt.AlignVCenter
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainerHigh
                        implicitWidth: repoBadgeLabel.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: repoBadgeLabel.implicitHeight + Tokens.padding.extraSmall * 2

                        StyledText {
                            id: repoBadgeLabel

                            anchors.centerIn: parent
                            text: repoRow.repoTag
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }

        // AUR Packages
        SectionHeader {
            visible: root.aurCount > 0
            text: qsTr("AUR Packages (%1)").arg(root.aurCount)
        }

        Repeater {
            model: root.aurPackages

            ConnectedRect {
                id: aurRow

                required property var modelData
                required property int index

                readonly property var pkg: modelData ?? ({})
                readonly property string pkgName: pkg.name ?? pkg.package ?? (typeof pkg === "string" ? pkg : "")
                readonly property string oldVer: pkg.oldVersion ?? pkg.old_version ?? pkg.old ?? ""
                readonly property string newVer: pkg.newVersion ?? pkg.new_version ?? pkg.new ?? pkg.version ?? ""

                Layout.fillWidth: true
                first: index === 0
                last: index === root.aurPackages.length - 1
                implicitHeight: aurRowLayout.implicitHeight + aurRowLayout.anchors.margins * 2

                RowLayout {
                    id: aurRowLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        StyledText {
                            Layout.fillWidth: true
                            text: aurRow.pkgName
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: Tokens.spacing.extraSmall
                            visible: aurRow.oldVer !== "" || aurRow.newVer !== ""

                            StyledText {
                                visible: aurRow.oldVer !== ""
                                text: aurRow.oldVer
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.medium
                            }

                            MaterialIcon {
                                visible: aurRow.oldVer !== "" && aurRow.newVer !== ""
                                text: "arrow_forward"
                                color: Colours.palette.m3outline
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                visible: aurRow.newVer !== ""
                                text: aurRow.newVer
                                color: Colours.palette.m3secondary
                                font: Tokens.font.label.medium
                            }
                        }
                    }

                    // Pill badge
                    StyledRect {
                        Layout.alignment: Qt.AlignVCenter
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3secondaryContainer
                        implicitWidth: aurBadgeLabel.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: aurBadgeLabel.implicitHeight + Tokens.padding.extraSmall * 2

                        StyledText {
                            id: aurBadgeLabel

                            anchors.centerIn: parent
                            text: "AUR"
                            color: Colours.palette.m3onSecondaryContainer
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }
    }
}
