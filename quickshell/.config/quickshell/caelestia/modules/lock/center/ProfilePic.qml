pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    implicitWidth: Math.round(centerWidth * 0.66)
    implicitHeight: implicitWidth

    StyledClippingRect {
        id: shape

        anchors.fill: parent
        radius: Tokens.rounding.large
        color: root.bgColour
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.4)
        border.width: 1

        MaterialIcon {
            anchors.centerIn: parent

            text: "person"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size(root.centerWidth / 4).build()
            visible: pfp.status !== Image.Ready
        }

        CachingImage {
            id: pfp

            anchors.fill: parent
            path: `${Paths.home}/.face`
        }
    }
}
