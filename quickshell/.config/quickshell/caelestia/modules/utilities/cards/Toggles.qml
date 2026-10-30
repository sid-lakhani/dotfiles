pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();
        const list = [];
        let hasDarkMode = false;

        for (const item of Config.utilities.quickToggles.values) {
            if (!item.enabled || seenIds.has(item.id))
                continue;

            if (item.id === "vpn" && GlobalConfig.utilities.vpn.selectedProvider.length === 0)
                continue;

            if (item.id === "darkMode") {
                hasDarkMode = true;
            }

            seenIds.add(item.id);
            list.push(item);
        }

        // Add Dark / Light mode toggle if not already explicitly in list
        if (!hasDarkMode) {
            const micIdx = list.findIndex(item => item.id === "mic");
            const insertIdx = micIdx !== -1 ? micIdx + 1 : Math.min(3, list.length);
            list.splice(insertIdx, 0, { id: "darkMode", enabled: true });
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
                    roleValue: "spacer"
                    delegate: Item {
                        property bool fillWidth: true
                        implicitHeight: 1
                    }
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
