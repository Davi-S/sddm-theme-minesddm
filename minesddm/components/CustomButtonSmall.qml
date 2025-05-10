import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: customSmallButton

    signal customClicked()

    width: config.smallButtonWidth
    height: config.itemHeight
    enabled: true
    hoverEnabled: true
    onClicked: {
        customSmallButton.customClicked();
    }
    states: [
        State {
            name: "hovered"
            when: customSmallButton.hovered

            PropertyChanges {
                target: customSmallButtonBackground
                source: "../images/selected_small_button_background.png"
            }

            PropertyChanges {
                target: customSmallButtonShadowText
                color: config.selectedShadowText
            }

            PropertyChanges {
                target: customSmallButtonContentText
                color: config.selectedText
            }

        },
        State {
            name: "disabled"
            when: !customSmallButton.enabled

            PropertyChanges {
                target: customSmallButtonBackground
                source: "../images/disabled_small_button_background.png"
            }

            PropertyChanges {
                target: customSmallButtonShadowText
                opacity: 0
            }

            PropertyChanges {
                target: customSmallButtonContentText
                color: config.darkText
            }

        }
    ]

    Text {
        id: customSmallButtonShadowText

        text: customSmallButton.text
        color: config.shadowText
        z: -1

        anchors {
            centerIn: customSmallButton
            horizontalCenterOffset: config.horizontalShadowOffset
            verticalCenterOffset: config.verticalShadowOffset
        }

        font {
            family: minecraftFont.name
            pixelSize: config.fontPixelSize
        }

    }

    contentItem: Text {
        id: customSmallButtonContentText

        text: customSmallButton.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: config.lightText

        font {
            family: minecraftFont.name
            pixelSize: config.fontPixelSize
        }

    }

    background: Image {
        id: customSmallButtonBackground

        source: "../images/small_button_background.png"
    }

}
