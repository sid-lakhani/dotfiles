import QtQuick
import qs.components

Flickable {
    id: root

    property bool doneFakeFlick
    property real targetContentY: contentY
    property bool isWheelScrolling: false

    maximumFlickVelocity: 3000

    onMovingChanged: {
        if (moving && smoothScrollAnim.running) {
            smoothScrollAnim.stop();
            isWheelScrolling = false;
        }
    }

    WheelHandler {
        id: wheelHandler
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const dy = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y;
            if (dy === 0)
                return;

            const minY = -root.topMargin;
            const maxY = Math.max(minY, root.contentHeight - root.height + root.bottomMargin);

            if (!root.isWheelScrolling) {
                root.targetContentY = root.contentY;
                root.isWheelScrolling = true;
            }

            const scrollStep = (dy / 120) * 120;
            root.targetContentY = Math.max(minY, Math.min(maxY, root.targetContentY - scrollStep));

            smoothScrollAnim.restart();
            event.accepted = true;
        }
    }

    NumberAnimation {
        id: smoothScrollAnim
        target: root
        property: "contentY"
        to: root.targetContentY
        duration: 200
        easing.type: Easing.OutCubic
        onFinished: {
            root.isWheelScrolling = false;
        }
    }

    rebound: Transition {
        onRunningChanged: {
            if (!running && !root.doneFakeFlick) {
                root.doneFakeFlick = true;
                root.flick(1, 1);
                root.flick(-1, -1);
                Qt.callLater(() => root.cancelFlick());
            }
        }

        Anim {
            properties: "x,y"
        }
    }

    Timer {
        running: root.doneFakeFlick
        interval: 10
        onTriggered: root.doneFakeFlick = false
    }
}
