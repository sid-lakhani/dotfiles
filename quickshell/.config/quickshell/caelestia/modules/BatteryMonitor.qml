import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => a.level - b.level)
    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (!UPower.onBattery) {
            root.lastPercentage = p;
            return;
        }

        if (root.lastPercentage >= 0) {
            for (const level of root.warnLevels) {
                if (p <= level.level && root.lastPercentage > level.level) {
                    Toaster.toast(level.title ?? qsTr("Battery warning"), level.message ?? qsTr("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(qsTr("Hibernating in 5 seconds"), qsTr("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (UPower.onBattery) {
                PowerProfiles.profile = PowerProfile.PowerSaver;
                Quickshell.execDetached(["/home/sidlakhani/.local/bin/power-profile-switch", "power-saver"]);
                Toaster.toast(qsTr("Battery Discharging"), qsTr("Switched to Power Saver (CPU eco, dGPU sleep)"), "energy_savings_leaf");
                root.handleBatteryWarnings();
            } else {
                PowerProfiles.profile = PowerProfile.Performance;
                Quickshell.execDetached(["/home/sidlakhani/.local/bin/power-profile-switch", "performance"]);
                Toaster.toast(qsTr("Charger Connected"), qsTr("Switched to Performance Mode (RTX 3050 unleashed)"), "rocket_launch");
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: SessionManager.hibernate()
    }
}
