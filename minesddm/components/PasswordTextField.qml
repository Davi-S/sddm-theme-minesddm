import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    // Password mode enumeration
    enum PasswordMode {
        Plain = 0,
        FixedMask = 1,
        RandomMask = 2,
        JitterMask = 3,
        NoEcho = 4
    }
    
    // Password field fallback constants
    readonly property string fallbackPasswordFixedMaskString: "*"
    readonly property string fallbackPasswordRandomMaskChars: "1234567890"
    readonly property int fallbackMaskCharsPerTypedChar: 1
    readonly property int fallbackPasswordMode: PasswordTextField.PasswordMode.Plain
    
    // Password mode string to enum mapping
    function getPasswordModeFromString(modeString) {
        switch(modeString) {
            case "plain": return PasswordTextField.PasswordMode.Plain;
            case "fixedMask": return PasswordTextField.PasswordMode.FixedMask;
            case "randomMask": return PasswordTextField.PasswordMode.RandomMask;
            case "jitterMask": return PasswordTextField.PasswordMode.JitterMask;
            case "noEcho": return PasswordTextField.PasswordMode.NoEcho;
            default: return -1; // Invalid mode
        }
    }
    
    // to prevent running into potentially big problems if the user sets config.passwordMode to an invalid value, we sanitize it here
    readonly property int passwordMode: (function(mode) {
        let enumMode = getPasswordModeFromString(mode);
        if (enumMode !== -1) {
            return enumMode;
        }
        showError("Config error: Invalid passwordMode '" + mode + "'");
        return fallbackPasswordMode;
    })(config.passwordMode)
    
    readonly property int maskCharsPerTypedChar: (function(n) {
        if (passwordMode === PasswordTextField.PasswordMode.Plain || passwordMode === PasswordTextField.PasswordMode.NoEcho) {
            return 1;
        }

        if (n > 0) {
            return n;
        }
        
        showError("Config error: Invalid maskCharsPerTypedChar '" + n + "'");
        return fallbackMaskCharsPerTypedChar;
    })(config.maskCharsPerTypedChar)
    property string actualPasswordEntered: ""
    property bool ignoreChange: false // safety switch to prevent unwanted recursion
    property int textLength: 0 // used to be able to tell whether the change was an addition or a deletion
    property string randomMaskString: ""

    function getPassword() {
        return passwordMode === PasswordTextField.PasswordMode.Plain || passwordMode === PasswordTextField.PasswordMode.NoEcho ? text : actualPasswordEntered;
    }

    // wrapper function that calls the appropriate function based on the passwordMode
    function getMask(plainInput) {
        let outputLength = plainInput.length * maskCharsPerTypedChar;
        if (passwordMode === PasswordTextField.PasswordMode.FixedMask) return getFixedMask(outputLength);
        if (passwordMode === PasswordTextField.PasswordMode.RandomMask || passwordMode === PasswordTextField.PasswordMode.JitterMask) return getRandomMask(outputLength);
        showError("ERROR: Masking failed for passwordMode '" + passwordMode + "'"); // this line should never be reached
        return plainInput;
    }

    function getFixedMask(outputLength) {
        let maskPattern = config.passwordFixedMaskString;
        if (maskPattern === "" || maskPattern === undefined) {
            showError("Config error: Invalid passwordFixedMaskString '" + maskPattern + "'");
            maskPattern = fallbackPasswordFixedMaskString;
        }
        let result = "";
        for (let i = 0; i < outputLength; ++i) {
            result += maskPattern[i % maskPattern.length];
        }
        return result;
    }

    function getRandomMask(outputLength) {
        if (passwordMode === PasswordTextField.PasswordMode.JitterMask) {
            randomMaskString = "";
        }

        while (randomMaskString.length < outputLength) {
            randomMaskString += randomMaskChar();
        }
        // discard deleted tail so it will be newly generated if chars are added again
        randomMaskString = randomMaskString.substring(0, outputLength);
        return randomMaskString;
    }

    function randomMaskChar() {
        let charSet = config.passwordRandomMaskChars;
        if (charSet === "" || charSet === undefined) {
            showError("Config error: Invalid passwordRandomMaskChars '" + charSet + "'");
            charSet = fallbackPasswordRandomMaskChars;
        }
        const index = Math.floor(Math.random() * charSet.length);
        return charSet.charAt(index);
    }

    function setCursorPosition(pos) {
        cursorMonitor.lock = true;
        cursorMonitor.prevCursorPosition = pos;
        cursorPosition = pos;
        cursorMonitor.lock = false;
    }

    echoMode: passwordMode === PasswordTextField.PasswordMode.NoEcho ? TextInput.NoEcho : TextInput.Normal
    
    width: config.inputWidth
    height: config.itemHeight
    color: config.lightText
    placeholderTextColor: config.darkText
    leftPadding: config.inputLeftPadding
    onTextChanged: {
        cursorMonitor.lock = true;
        let prevTextLength = textLength;
        textLength = text.length;
        if (passwordMode !== PasswordTextField.PasswordMode.Plain && passwordMode !== PasswordTextField.PasswordMode.NoEcho && !ignoreChange) {
            let simCursorPos = Math.floor(cursorPosition / maskCharsPerTypedChar); // simulated cursor position of the imaginary cursor in actualPasswordEntered
            if (text.length > prevTextLength) {
                // addition
                // insert the newly typed substring at the correct position into actualPasswordEntered
                let editLength = text.length - prevTextLength;
                let indexSplit = Math.ceil((cursorPosition - editLength + 1) / maskCharsPerTypedChar) - 1;
                actualPasswordEntered = actualPasswordEntered.substring(0, indexSplit) + text.substring(cursorPosition - editLength, cursorPosition) + actualPasswordEntered.substring(indexSplit, actualPasswordEntered.length);
                simCursorPos = indexSplit + editLength;
            } else if (text.length < prevTextLength) {
                // deletion
                // delete the correct substring from actualPasswordEntered
                let editLength = Math.ceil((prevTextLength - text.length) / maskCharsPerTypedChar);
                actualPasswordEntered = actualPasswordEntered.substring(0, simCursorPos) + actualPasswordEntered.substring(simCursorPos + editLength, actualPasswordEntered.length);
            } else {
                // either one or multiple characters were overwritten or something went wrong
                // either way, there is no way to know what actually happened.
                actualPasswordEntered = "";
                ignoreChange = true;
                text = "";
                ignoreChange = false;
            }
            let maskedPassword = getMask(actualPasswordEntered);
            ignoreChange = true;
            text = maskedPassword;
            ignoreChange = false;
            setCursorPosition(simCursorPos * maskCharsPerTypedChar);
        }
        cursorMonitor.lock = false;
    }

    font {
        family: minecraftFont.name
        pixelSize: config.fontPixelSize
    }

    Timer {
        id: cursorMonitor

        property int prevCursorPosition: 0
        property bool lock: false

        interval: 10
        running: passwordMode !== PasswordTextField.PasswordMode.Plain && passwordMode !== PasswordTextField.PasswordMode.NoEcho && maskCharsPerTypedChar > 1
        repeat: true
        onTriggered: {
            const selectionActive = selectionStart !== selectionEnd;
            if (!lock && !selectionActive) {
                let deltaPos = (cursorPosition - prevCursorPosition);
                if (deltaPos === 1 || deltaPos === -1) {
                    // probably caused by arrow keys ==> force move
                    setCursorPosition(prevCursorPosition + maskCharsPerTypedChar * deltaPos);
                }
                
                // set to nearest block border
                setCursorPosition(Math.round(cursorPosition / maskCharsPerTypedChar) * maskCharsPerTypedChar);
                prevCursorPosition = cursorPosition;
            }
        }
    }

    background: TextFieldBackground {
    }

}
