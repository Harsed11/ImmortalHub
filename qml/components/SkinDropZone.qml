import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../theme"

DropArea {
    id: dropZone
    anchors.fill: parent
    z: 900

    property bool isHovering: false

    signal filesDropped(var urls)

    onEntered: function(drag) {
        if (drag.hasUrls) {
            isHovering = true
            drag.accept()
        }
    }

    onExited: {
        isHovering = false
    }

    onDropped: function(drop) {
        isHovering = false
        if (drop.hasUrls) {
            var urlList = []
            for (var i = 0; i < drop.urls.length; i++) {
                urlList.push(drop.urls[i])
            }
            dropZone.filesDropped(urlList)
            drop.accept()
        }
    }

    // Visual Overlay
    Rectangle {
        anchors.fill: parent
        color: "#E6060810"
        visible: isHovering
        opacity: isHovering ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 40
            radius: SkinTheme.radiusXLarge
            color: SkinTheme.accentCyanGlow
            border.color: SkinTheme.accentCyan
            border.width: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "📦"
                    font.pixelSize: 64
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "DROP .VPK OR .ZIP FILE HERE"
                    color: SkinTheme.accentCyan
                    font.family: SkinTheme.fontDisplay
                    font.pixelSize: 22
                    font.bold: true
                    font.letterSpacing: 2.0
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "ImmortalHub will automatically unpack, detect category, and register your custom skin."
                    color: SkinTheme.textPrimary
                    font.family: SkinTheme.fontFamily
                    font.pixelSize: 14
                }
            }
        }
    }
}
