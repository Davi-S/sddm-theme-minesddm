import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import "components"

Rectangle {
    id: root

    // Define a mapping of actions to their corresponding methods and availability
    property var actionMap: ({
        "Power Off": {
            "text": config.textPowerOffButton,
            "enabled": sddm.canPowerOff,
            "method": sddm.powerOff
        },
        "Reboot": {
            "text": config.textRebootButton,
            "enabled": sddm.canReboot,
            "method": sddm.reboot
        },
        "Suspend": {
            "text": config.textSuspendButton,
            "enabled": sddm.canSuspend,
            "method": sddm.suspend
        },
        "Hibernate": {
            "text": config.textHibernateButton,
            "enabled": sddm.canHibernate,
            "method": sddm.hibernate
        },
        "Hybrid Sleep": {
            "text": config.textHybridSleepButton,
            "enabled": sddm.canHybridSleep,
            "method": sddm.hybridSleep
        }
    })
    property var actionKeys: Object.keys(root.actionMap)
    property int currentActionIndex: 0

    function showError(errorMessage) {
        console.error(errorMessage);
        errorLabel.text += errorMessage + "\n";
    }

    height: config.screenHeight || Screen.height
    width: config.screenWidth || Screen.width

    SessionHandler {
        id: sessionHandler
    }

    function getUsernameList() {
    var usernames = [];
    for (var i = 0; i < userModel.count; i++) {
        usernames.push(userModel.data(userModel.index(i, 0), 257));
    }
    return usernames.join(", ");
}

    Formatter {
        id: formatter

        placeholderMap: new Map([
            ["{username}", usernameTextField.text],
            ["{password}", passwordTextField.getPassword()],
            ["{usernameList}", getUsernameList()],
            ["{maskedPassword}", passwordTextField.displayText],
            ["{actionIndex}", `${root.currentActionIndex}`],
            ["{nextActionIndex}", `${(root.currentActionIndex + 1) % root.actionKeys.length}`],
            ["{sessionName}", sessionHandler.getSessionName()],
            ["{sessionComment}", sessionHandler.getSessionComment()],
            ["{sessionIndex}", `${sessionHandler.sessionIndex}`],
            ["{sessionsCount}", `${sessionModel.count}`],
            ["{sessionInitialized}", sessionHandler.sessions.count > sessionHandler.sessionIndex ? "true" : ""]
        ])
    }

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

    Label {
        id: errorLabel

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        text: ""
        color: "#00ffff"
        font.pixelSize: 16
        visible: text.length > 0
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
            text: formatter.formatString(config.mainTitleText)
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
                text: formatter.formatString(config.usernameTopLabel)
            }

            UsernameTextField {
                id: usernameTextField

                placeholderText: formatter.formatString(config.usernamePlaceholder)
                text: userModel.lastUser
                onAccepted: loginButton.clicked()
            }

            CustomText {
                text: formatter.formatString(config.usernameBottomLabel)
                color: config.darkText
            }

        }

        // Password field
        Column {
            spacing: config.labelFieldSpacing

            CustomText {
                text: formatter.formatString(config.passwordTopLabel)
            }

            PasswordTextField {
                id: passwordTextField

                placeholderText: formatter.formatString(config.passwordPlaceholder)
                focus: true
                onAccepted: loginButton.clicked()
            }

            CustomText {
                id: passwordBottomLabel
                text: formatter.formatString(config.passwordBottomLabel)
                color: config.darkText
            }

        }

        // Session selector button
        // Please look at the SessionHandler.qml file to understand what is happening here
        Column {
            spacing: config.labelFieldSpacing

            CustomButton {
                text: formatter.formatString(config.textSessionButton)
                onCustomClicked: {
                    sessionHandler.sessionIndex = (sessionHandler.sessionIndex + 1) % sessionModel.count;
                }

                anchors {
                    horizontalCenter: parent.horizontalCenter
                }

            }

            CustomText {
                text: formatter.formatString(config.sessionButtonBottomLabel)
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

            text: formatter.formatString(config.textLoginButton)
            enabled: usernameTextField.text !== "" && passwordTextField.getPassword() !== ""
            onCustomClicked: {
                console.log("login button clicked");
                let password = passwordTextField.getPassword();
                // console.log("trying to log in with username = '" + usernameTextField.text + "', password = '" + password + "'"); // only for debugging
                passwordBottomLabel.text = formatter.formatString(config.passwordBottomLabel); // Reverts the login failed text back to the original
                sddm.login(usernameTextField.text, password, sessionHandler.sessionIndex);
            }
        }

        // Do Action button
        CustomButton {
            text: formatter.formatString(root.actionMap[root.actionKeys[root.currentActionIndex]].text)
            enabled: root.actionMap[root.actionKeys[root.currentActionIndex]].enabled
            onCustomClicked: {
                var actionKey = root.actionKeys[root.currentActionIndex];
                var action = root.actionMap[actionKey];
                console.log(actionKey + " button clicked");
                action.method();
            }
        }

        // Action selector button
        CustomButton {
            text: formatter.formatString(config.textCycleButton)
            width: config.itemHeight
            onCustomClicked: {
                root.currentActionIndex = (root.currentActionIndex + 1) % root.actionKeys.length;
            }
            // Override the default images for this specific button instance
            backgroundSource: "../images/small_button_background.png"
            hoveredBackgroundSource: "../images/selected_small_button_background.png"
            disabledBackgroundSource: "../images/disabled_small_button_background.png"
        }

    }

    Connections {
        function onLoginFailed() {
            passwordTextField.ignoreChange = true;
            passwordTextField.text = "";
            passwordTextField.ignoreChange = false;
            passwordTextField.actualPasswordEntered = "";
            passwordTextField.focus = true;
            passwordBottomLabel.text = formatter.formatString(config.passwordBottomLabelFailed);
        }

        target: sddm
    }

}
