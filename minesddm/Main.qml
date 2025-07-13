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

    property bool sessionsInitialized: false

    function getSessionName() {
        if (!sessionsInitialized) {
            return config.sessionTextOnLoad;
        }
        if (sessions.length === 0 || sessionIndex < 0 || sessionIndex >= sessions.length) {
            return config.sessionTextOnFailure;
        }
        return root.replacePlaceholders(config.sessionText, {
                    "sessionname": sessions[sessionIndex].name,
                    "sessioncomment": sessions[sessionIndex].comment
               });
    }

    function getSessionComment() {
        if (!sessionsInitialized) {
            return config.sessionCommentOnLoad;
        }
        if (sessions.length === 0 || sessionIndex < 0 || sessionIndex >= sessions.length) {
            return config.sessionCommentOnFailure;
        }
        return root.replacePlaceholders(config.sessionComment, {
                    "sessionname": sessions[sessionIndex].name,
                    "sessioncomment": sessions[sessionIndex].comment
               });
    }

    function replacePlaceholders(text, placeholders) {
        let result = text;
        for (let key in placeholders) {
            let placeholder = "{" + key + "}"; // Match the placeholder format
            result = result.replace(placeholder, placeholders[key]);
        }
        return result;
    }

    property string randomMaskString: ""

    function maskPassword(plainInput) {
        if(passwordTextField.passwordMode === "fixedMask") {
            let maskPattern = config.passwordFixedMaskString;
            if (maskPattern === "" || maskPattern === undefined) {
                maskPattern = "*"; // fallback
            }
            let result = "";
            for (var i = 0; i < plainInput.length; ++i) {
                result += maskPattern[i % maskPattern.length];
            }
            return result;
        }
        else if(["randomMask", "jitterMask"].includes(passwordTextField.passwordMode)) {
            if(passwordTextField.passwordMode === "jitterMask") {
                randomMaskString = "";
            }
            while(plainInput.length > randomMaskString.length) {
                randomMaskString += randomMaskChar();
            }
            // dicard deleted tail so it will be newly generated if chars are added again
            randomMaskString = randomMaskString.substring(0, plainInput.length);
            return randomMaskString.substring(0, plainInput.length);
        }
    }

    function randomMaskChar() {
        let charSet = config.passwordRandomMaskChars;
        if(charSet === "" || charSet === undefined) {
            charSet = "1234567890"; // fallback
        }
        const index = Math.floor(Math.random() * charSet.length)
        return charSet.charAt(index);
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
                text: usernameTextField.text === "" ? config.usernameBottomLabelIfEmpty :
                        root.replacePlaceholders(config.usernameBottomLabel, {
                            "username": usernameTextField.text
                        })
                color: config.darkText
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

                // to prevent running into potentially big problems if the user sets config.passwordMode to an invalid value, we sanitize it here
                readonly property string passwordMode: (
                    config.passwordMode === "plain" ? "plain" :
                    config.passwordMode === "noEcho" ? "plain" : // treat it like plain here. The desired effect is achieved by setting the echoMode (see PasswordTextField.qml).
                    config.passwordMode === "fixedMask" ? "fixedMask" :
                    config.passwordMode === "randomMask" ? "randomMask" :
                    config.passwordMode === "jitterMask" ? "jitterMask" :
                    "plain" // default to this mode if config.passwordMode is an invalid value
                )

                property string actualPasswordEntered: ""
                property string maskedPassword: ""
                property bool ignoreChange: false   // safety switch to prevent unwanted recursion

                onTextChanged: {
                    if(passwordMode !== "plain" && !ignoreChange){
                        // careful, there is the recursive case of text.length === actualPasswordEntered.length
                        if (text.length === actualPasswordEntered.length + 1) { // if a character was added
                            // insert the newly typed character at the correct position into actualPasswordEntered
                            actualPasswordEntered = actualPasswordEntered.substring(0, cursorPosition - 1)
                                                    + text.charAt(cursorPosition - 1)
                                                    + actualPasswordEntered.substring(cursorPosition - 1, actualPasswordEntered.length);
                        } else if (text.length === actualPasswordEntered.length - 1) { // if a single character was deleted
                            // delete the correct char from actualPasswordEntered
                            actualPasswordEntered = actualPasswordEntered.substring(0, cursorPosition)
                                                    + actualPasswordEntered.substring(cursorPosition + 1, actualPasswordEntered.length);
                        } else if(text.length !== actualPasswordEntered.length) { // either multiple characters were deleted at the same time or something went wrong
                            actualPasswordEntered = "";
                            ignoreChange = true;
                            text = "";
                            ignoreChange = false;
                        }
                        maskedPassword = maskPassword(actualPasswordEntered);
                        ignoreChange = true;
                        let tmpCursorPosition = cursorPosition;
                        text = maskedPassword;
                        cursorPosition = tmpCursorPosition;
                        ignoreChange = false;
                    }
                }

                function getPassword() {
                    return passwordMode === "plain" ? text : actualPasswordEntered;
                }


            }

            CustomText {
                text: passwordTextField.text === "" ? config.passwordBottomLabelIfEmpty :
                        root.replacePlaceholders(config.passwordBottomLabel, {
                            "username": usernameTextField.text,
                            "password": passwordTextField.text,      // I don't know why anyone would use that, but why not provide the option
                             // the following placeholder substitutions are useful for debugging:
                            "maskedPassword": passwordTextField.maskedPassword,
                            "actualPassword": passwordTextField.actualPasswordEntered,
                            "cursorPosition": passwordTextField.cursorPosition
                        })
                color: config.darkText
            }

        }

        // Session selector button
        // Please look at the SessionHandler.qml file to understand what is happening here
        Column {
            spacing: config.labelFieldSpacing

            CustomButton {
                text: root.getSessionName()
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

            text: config.textLoginButton
            enabled: usernameTextField.text !== "" && passwordTextField.getPassword() !== ""
            onCustomClicked: {
                console.log("login button clicked");
                let password = passwordTextField.getPassword();
                // console.log("trying to log in with username = '" + usernameTextField.text + "', password = '" + password + "'"); // only for debugging
                sddm.login(usernameTextField.text, password, root.sessionIndex);
            }
        }

        // Do Action button
        CustomButton {
            text: root.actionMap[root.actionKeys[root.currentActionIndex]].text
            enabled: root.actionMap[root.actionKeys[root.currentActionIndex]].enabled
            onCustomClicked: {
                var actionKey = root.actionKeys[root.currentActionIndex]
                var action = root.actionMap[actionKey];
                console.log(actionKey + " button clicked");
                action.method();
            }
        }

        // Action selector button
        CustomButton {
            text: config.textCycleButton
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
        }

        target: sddm
    }

}
