pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    FileView {
        id: voiceStateFile
        path: `${Paths.state}/vocalinux_state`
        watchChanges: true
        printErrors: false
    }

    readonly property var quickToggles: {
        const seenIds = new Set();
        const list = [];
        let hasDarkMode = false;
        let hasVoice = false;
        let hasSettings = false;

        for (const item of Config.utilities.quickToggles.values) {
            if (!item.enabled || seenIds.has(item.id))
                continue;

            if (item.id === "vpn" && GlobalConfig.utilities.vpn.selectedProvider.length === 0)
                continue;

            if (item.id === "darkMode")
                hasDarkMode = true;
            if (item.id === "voice")
                hasVoice = true;
            if (item.id === "settings")
                hasSettings = true;

            seenIds.add(item.id);
            list.push(item);
        }

        // Add Dark / Light mode toggle if not already explicitly in list (row 1, 4th item)
        if (!hasDarkMode) {
            const micIdx = list.findIndex(item => item.id === "mic");
            const insertIdx = micIdx !== -1 ? micIdx + 1 : Math.min(3, list.length);
            list.splice(insertIdx, 0, { id: "darkMode", enabled: true });
        }

        // Ensure settings (gear icon) is present at the start of row 2
        if (!hasSettings) {
            const gmIdx = list.findIndex(item => item.id === "gameMode");
            if (gmIdx !== -1)
                list.splice(gmIdx, 0, { id: "settings", enabled: true });
            else
                list.push({ id: "settings", enabled: true });
        }

        // Add Voice dictation toggle if not already explicitly in list (row 2, 4th item)
        if (!hasVoice) {
            list.push({ id: "voice", enabled: true });
        }

        return list;
    }

    readonly property var toggleRows: {
        const rows = [];
        const items = root.quickToggles;
        const perRow = 4;

        for (let i = 0; i < items.length; i += perRow) {
            const chunk = items.slice(i, i + perRow);
            // Pad the trailing row with spacers when there are multiple rows so all buttons match the 4-column width above
            if (chunk.length > 0 && chunk.length < perRow && items.length > perRow) {
                const padded = chunk.slice();
                while (padded.length < perRow) {
                    padded.push({ id: "spacer", enabled: true });
                }
                rows.push(padded);
            } else {
                rows.push(chunk);
            }
        }
        return rows;
    }

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: qsTr("Quick Toggles")
            font: Tokens.font.body.medium
        }

        Repeater {
            model: root.toggleRows

            QuickToggleRow {
                required property var modelData
                model: modelData
            }
        }

        StyledRect {
            id: profilesSlider

            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            implicitHeight: 44

            property string current: {
                const p = PowerProfiles.profile;
                if (p === PowerProfile.PowerSaver)
                    return saver.icon;
                if (p === PowerProfile.Performance)
                    return perf.icon;
                return balance.icon;
            }

            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)
            radius: Tokens.rounding.full

            StyledRect {
                id: sliderIndicator

                anchors.topMargin: Tokens.padding.extraSmall
                anchors.bottomMargin: Tokens.padding.extraSmall
                anchors.leftMargin: Tokens.padding.extraSmall
                anchors.rightMargin: Tokens.padding.extraSmall

                color: Colours.palette.m3primary
                radius: Tokens.rounding.full
                state: profilesSlider.current

                states: [
                    State {
                        name: saver.icon

                        Fill {
                            item: saver
                        }
                    },
                    State {
                        name: balance.icon

                        Fill {
                            item: balance
                        }
                    },
                    State {
                        name: perf.icon

                        Fill {
                            item: perf
                        }
                    }
                ]

                transitions: Transition {
                    AnchorAnim {}
                }
            }

            ProfileBtn {
                id: saver

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width / 3

                profile: PowerProfile.PowerSaver
                profileName: "power-saver"
                icon: "energy_savings_leaf"
            }

            ProfileBtn {
                id: balance

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width / 3

                profile: PowerProfile.Balanced
                profileName: "balanced"
                icon: "balance"
            }

            ProfileBtn {
                id: perf

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width / 3

                profile: PowerProfile.Performance
                profileName: "performance"
                icon: "rocket_launch"
            }
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        checked: GameMode.enabled
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "darkMode"
                    delegate: Toggle {
                        icon: Colours.light ? "light_mode" : "dark_mode"
                        checked: !Colours.light
                        onClicked: Colours.setMode(Colours.light ? "dark" : "light")
                    }
                }
                DelegateChoice {
                    roleValue: "voice"
                    delegate: Toggle {
                        icon: "record_voice_over"
                        checked: voiceStateFile.text().trim() === "recording"
                        onClicked: {
                            Quickshell.execDetached(["/home/sidlakhani/.local/bin/voice-dictate"]);
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "spacer"
                    delegate: Item {
                        property bool fillWidth: true
                        implicitHeight: 1
                    }
                }
            }
        }
    }

    component Fill: AnchorChanges {
        required property Item item

        target: sliderIndicator
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component ProfileBtn: Item {
        id: profBtn

        required property string icon
        required property int profile
        required property string profileName

        implicitWidth: iconWidget.implicitHeight + Tokens.padding.small
        implicitHeight: iconWidget.implicitHeight + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: profilesSlider.current === parent.icon ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: {
                PowerProfiles.profile = parent.profile;
                Quickshell.execDetached(["/home/sidlakhani/.local/bin/power-profile-switch", parent.profileName]);
            }
        }

        MaterialIcon {
            id: iconWidget

            anchors.centerIn: parent

            text: profBtn.icon
            fontStyle: Tokens.font.icon.large
            color: profilesSlider.current === text ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: profilesSlider.current === text ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true
    }
}
