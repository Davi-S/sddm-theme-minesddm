import QtQuick 2.15
import QtQuick.Controls 2.15

TextField {
    echoMode: TextInput.Normal
    width: config.inputWidth
    height: config.itemHeight
    color: config.lightText
    placeholderText: config.passwordPlaceholder
    placeholderTextColor: config.darkText
    leftPadding: config.inputLeftPadding

    font {
        family: minecraftFont.name
        pixelSize: config.fontPixelSize
    }

    background: TextFieldBackground {
    }

}
