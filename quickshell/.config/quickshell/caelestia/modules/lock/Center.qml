import "center"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Tokens.spacing.medium

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.medium
        centerScale: root.centerScale
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.large * root.centerScale
        Layout.bottomMargin: Tokens.spacing.medium * root.centerScale
        centerWidth: root.centerWidth
    }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.large * root.centerScale
        spacing: Tokens.spacing.medium

        ActionButton {
            icon: Config.session.icons.logout
            command: Config.session.commands.logout
        }

        ActionButton {
            icon: Config.session.icons.shutdown
            command: Config.session.commands.shutdown
        }

        ActionButton {
            icon: Config.session.icons.hibernate
            command: Config.session.commands.hibernate
        }

        ActionButton {
            icon: Config.session.icons.reboot
            command: Config.session.commands.reboot
        }
    }

    component ActionButton: IconButton {
        id: button

        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Math.round(46 * root.centerScale)
        implicitHeight: implicitWidth

        inactiveColour: Colours.palette.m3surfaceContainerHigh
        inactiveOnColour: Colours.palette.m3onSurface
        activeColour: Colours.palette.m3secondaryContainer
        activeOnColour: Colours.palette.m3onSecondaryContainer

        radius: pressed ? Tokens.rounding.small : Tokens.rounding.large
        font: Tokens.font.icon.builders.medium.scale(1.15).build()

        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
        border.width: 1

        onClicked: exec()
    }
}
