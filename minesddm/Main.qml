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

    property bool sessionsInitialized: false

    function getSessionName() {
        if (!sessionsInitialized) {
            return "Loading sessions...";
        }
        if (sessions.length === 0 || sessionIndex < 0 || sessionIndex >= sessions.length) {
            return "No sessions found";
        }
        return sessions[sessionIndex].name;
    }

    function getSessionComment() {
        if (!sessionsInitialized) {
            return "Please wait while available desktop sessions are being loaded...";
        }
        if (sessions.length === 0 || sessionIndex < 0 || sessionIndex >= sessions.length) {
            return "No session information available";
        }
        return sessions[sessionIndex].comment;
    }

    function replacePlaceholders(text, placeholders) {
        let result = text;
        for (let key in placeholders) {
            let placeholder = "{" + key + "}"; // Match the placeholder format
            result = result.replace(placeholder, placeholders[key]);
        }
        return result;
    }

    function maskPassword(plainInput) {
        let maskPattern = config.passwordMaskString;
        let result = "";
        for (var i = 0; i < plainInput.length; ++i) {
            result += maskPattern[i % maskPattern.length];
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
                id: passwordTextField

                focus: true
                onAccepted: loginButton.clicked()

                property string actualPasswordEntered: ""
                property string maskedPassword: ""

                onTextChanged: {
                    if (text.length > actualPasswordEntered.length) {
                        actualPasswordEntered = actualPasswordEntered.substring(0, cursorPosition - 1)
                                              + text.charAt(cursorPosition - 1)
                                              + actualPasswordEntered.substring(cursorPosition - 1, actualPasswordEntered.length);
                    } else if (text.length < actualPasswordEntered.length) {
                        actualPasswordEntered = actualPasswordEntered.substring(0, cursorPosition)
                                              + actualPasswordEntered.substring(cursorPosition + 1, actualPasswordEntered.length);
                    }
                    maskedPassword = maskPassword(actualPasswordEntered);
                    if(config.maskPassword === "true"){
                        let tmpCursorPosition = cursorPosition;
                        text = maskedPassword;
                        cursorPosition = tmpCursorPosition;
                    }
                }
            }

            CustomText {
                // these placeholder substitutions are useful for debugging
                text: root.replacePlaceholders(config.passwordBottomLabel, {
                    "maskedPassword": passwordTextField.maskedPassword,
                    "actualPassword": passwordTextField.actualPasswordEntered,
                    "cursorPosition": passwordTextField.cursorPosition
                })
                color: passwordTextField.text || config.passwordBottomLabelAlways ? config.darkText : "transparent"
            }

        }

        // Session selector button
        // Please look at the SessionHandler.qml file to understand what is happening here
        Column {
            spacing: config.labelFieldSpacing

            CustomButton {
                text: root.replacePlaceholders(config.sessionText, {
                    "session": root.getSessionName()
                })
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
                text: root.getSessionComment()
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

            text: config.LoginButtonText
            enabled: usernameTextField.text !== "" && passwordTextField.actualPasswordEntered !== ""
            onCustomClicked: {
                console.log("login button clicked");
                sddm.login(usernameTextField.text, passwordTextField.actualPasswordEntered, root.sessionIndex);
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
        CustomButton {
            text: "->"
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
            passwordTextField.text = "";
            passwordTextField.actualPasswordEntered = "";
            passwordTextField.focus = true;
        }

        target: sddm
    }

}
