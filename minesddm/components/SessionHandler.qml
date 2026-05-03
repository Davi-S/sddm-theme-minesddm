import QtQml.Models 2.15
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Item {
    id: sessionHandler

    property ListModel sessions: ListModel {}
    property int sessionIndex: 0

    function isValidIndex() {
        return sessionIndex >= 0 && sessionIndex < sessions.count;
    }

    function getSessionName() {
        return isValidIndex() ? sessions.get(sessionIndex).name : "";
    }

    function getSessionComment() {
        return isValidIndex() ? sessions.get(sessionIndex).comment : "";
    }

    Instantiator {
        model: sessionModel

        delegate: QtObject {
            Component.onCompleted: {
                sessions.append({
                    "name": model.name,
                    "comment": model.comment
                });
            }
        }
    }

    Component.onCompleted: {
        if (sessions.count > 0) {
            if (sessionModel.lastIndex > -1 && sessionModel.lastIndex < sessions.count) {
                sessionIndex = sessionModel.lastIndex;
            } else {
                sessionIndex = 0;
            }
        }
    }
}

