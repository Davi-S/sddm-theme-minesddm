import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import "components"

Rectangle {
    id: root

    // Session properties. Please look at the SessionHandler.qml file to understand hwo these properties work
    property int sessionIndex: sessionModel.lastIndex
    property var sessions: []
    // Define a mapping of actions to their corresponding methods and availability
    property var actionMap: ({
        "Power Off": {
            "enabled": sddm.canPowerOff,
            "method": sddm.powerOff
        },
        "Reboot": {
            "enabled": sddm.canReboot,
            "method": sddm.reboot
        },
        "Suspend": {
            "enabled": sddm.canSuspend,
            "method": sddm.suspend
        },
        "Hibernate": {
            "enabled": sddm.canHibernate,
            "method": sddm.hibernate
        },
        "Hybrid Sleep": {
            "enabled": sddm.canHybridSleep,
            "method": sddm.hybridSleep
        }
    })
    property var actionKeys: Object.keys(root.actionMap)
    property int currentActionIndex: 0

    function replacePlaceholders(text, placeholders) {
        let result = text;
        for (let key in placeholders) {
            let placeholder = "{" + key + "}"; // Match the placeholder format
            result = result.replace(placeholder, placeholders[key]);
        }
        return result;
    }

    height: config.screenHeight || Screen.height
    width: config.screenWidth || Screen.ScreenWidth

    // Load the minecraft font
    FontLoader {
        id: minecraftFont

        source: "resources/MinecraftRegular-Bmg3.otf"
    }

    // This is the background image
    Image {
        source: "images/background.png"
        fillMode: Image.PreserveAspectCrop
        clip: true

        anchors {
            fill: parent
        }

    }

    Column {
        id: loginArea

        spacing: config.itemsSpacing

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: config.topMargin
        }

        // Main title
        CustomText {
            text: config.mainTitleText
            color: config.lightText

            anchors {
                horizontalCenter: parent.horizontalCenter
            }

        }

        // Spacer Rectangle between title and input fields
        Rectangle {
            width: parent.width
            height: config.itemsSpacing * 0.5
            color: "transparent" // Invisible spacer
        }

        // Username field
        Column {
            spacing: config.labelFieldSpacing

            CustomText {
                text: config.usernameTopLabel
            }

            UsernameTextField {
                id: usernameTextField

                text: userModel.lastUser
                onAccepted: loginButton.clicked()
            }

            CustomText {
                text: root.replacePlaceholders(config.usernameBottomLabel, {
                    "username": usernameTextField.text
                })
                color: usernameTextField.text || config.usernameBottomLabelAlways ? config.darkText : "transparent"
            }

        }

        // Password field
        Column {
            spacing: config.labelFieldSpacing

            CustomText {
                text: config.passwordTopLabel
            }

            PasswordTextField {
                id: passswordTextField

                focus: true
                onAccepted: loginButton.clicked()
            }

            CustomText {
                text: config.passwordBottomLabel
                color: passswordTextField.text || config.passwordBottomLabelAlways ? config.darkText : "transparent"
            }

        }

        // Session selector button
        // Please look at the SessionHandler.qml file to understand what is happening here
        Column {
            spacing: config.labelFieldSpacing

            CustomButton {
                text: "Session: " + root.sessions[root.sessionIndex].name
                onCustomClicked: {
                    root.sessionIndex = (root.sessionIndex + 1) % sessionModel.count;
                }

                anchors {
                    horizontalCenter: parent.horizontalCenter
                }

                SessionHandler {
                    // Please look at the SessionHandler.qml file to understand what is happening here

                }

            }

            CustomText {
                text: root.sessions[root.sessionIndex].comment
                wrapMode: Text.Wrap
                width: config.inputWidth
            }

        }

    }

    Row {
        spacing: config.itemsSpacing

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: config.bottomMargin
            // Offset to ignore the size of the small button for centering
            horizontalCenterOffset: config.itemHeight
        }

        // Login button
        CustomButton {
            id: loginButton

            text: "Login"
            enabled: usernameTextField.text !== "" && passswordTextField.text !== ""
            onCustomClicked: {
                console.log("login button clicked");
                sddm.login(usernameTextField.text, passswordTextField.text, root.sessionIndex);
            }
        }

        // Do Action button
        CustomButton {
            text: root.actionKeys[root.currentActionIndex]
            onCustomClicked: {
                var action = root.actionMap[root.actionKeys[root.currentActionIndex]];
                if (action.enabled)
                    action.method();

            }
        }

        // Action selector button
        CustomButtonSmall {
            text: "->"
            width: config.itemHeight
            onCustomClicked: {
                root.currentActionIndex = (root.currentActionIndex + 1) % root.actionKeys.length;
            }
        }

    }

    Connections {
        function onLoginFailed() {
            passswordTextField.text = "";
            passswordTextField.focus = true;
        }

        target: sddm
    }

}
