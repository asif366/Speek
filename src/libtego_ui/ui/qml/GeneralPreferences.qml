import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Styles 1.2
import im.utility 1.0
import im.ricochet 1.0

ColumnLayout {
    Utility {
           id: utility
        }

    anchors {
        fill: parent
        margins: 8
    }

    RowLayout {
        z: 2
        RowLayout {
            spacing: 0
            Label {
                //: Label for text input where users can specify their username
                text: !styleHelper.isGroupHostMode ? qsTr("Username") : qsTr("Group Name")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }

            Button {
                Layout.alignment: Qt.AlignTop
                tooltip: "Username that gets automatically filled into the \"your username\" field of a contact request. This recommends the contact a username to use for you."

                style: ButtonStyle {
                    background: Rectangle {
                        implicitWidth: 10
                        implicitHeight: 10
                        color: "transparent"
                    }
                    label: Text {
                        text: "N"
                        font.family: iconFont.name
                        font.pixelSize: 10
                        horizontalAlignment: Qt.AlignLeft
                        renderType: Text.QtRendering
                        color: control.hovered ? palette.text : styleHelper.chatIconColor
                    }
                }
            }
        }

        TextField {
            id: usernameText

            text: typeof(uiSettings.data.username) !== "undefined" ? uiSettings.data.username : "Speek User"
            Layout.minimumWidth: 200
            Layout.maximumHeight: 33

            validator: RegExpValidator{regExp: /^[a-zA-Z0-9\-_, ]+$/}

            onTextChanged: {
                if (length > 40) remove(40, length);
                uiSettings.write("username", usernameText.text)
            }

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to select the own username
            Accessible.name: qsTr("Username input field")
            //: Description of what the username text input is for accessibility tech like screen readers
            Accessible.description: qsTr("What the own username should be")
        }
    }

    ColumnLayout {
        z: 2
        visible: styleHelper.isGroupHostMode
        RowLayout {
            spacing: 0
            Label {
                //: Label for text area where users can specify the pinned message for a group
                text: qsTr("Group Pinned Message")
                Accessible.role: Accessible.StaticText
                Accessible.name: text
            }
        }

        TextArea {
            id: groupPinnedMessage

            text: typeof(uiSettings.data.groupPinnedMessage) !== "undefined" ? uiSettings.data.groupPinnedMessage : ""
            Layout.fillWidth: true
            Layout.maximumHeight: 80

            onTextChanged: {
                if (length > 800) remove(800, length);
                uiSettings.write("groupPinnedMessage", groupPinnedMessage.text)
            }

            Accessible.role: Accessible.EditableText
            //: Name of the text input used to change the pinned message of a group
            Accessible.name: qsTr("Group Pinned Message input field")
            //: Description of what the group pinned message input field is for accessibility tech like screen readers
            Accessible.description: qsTr("What the pinned message of the group should be")
        }
    }

    CheckBox {
        visible: !styleHelper.isGroupHostMode
        //: Text description of an option to activate rich text editing by default which allows the input of emojis and images
        text: qsTr("Disable default Rich Text editing")
        checked: uiSettings.data.disableDefaultRichText || false
        onCheckedChanged: {
            uiSettings.write("disableDefaultRichText", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("disableDefaultRichText", checked)
        }
    }

    CheckBox {
        visible: !styleHelper.isGroupHostMode
        //: Text description of an option to minimize to the systemtray
        text: qsTr("Minimize to Systemtray")
        checked: uiSettings.data.minimizeToSystemtray || false
        onCheckedChanged: {
            uiSettings.write("minimizeToSystemtray", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("minimizeToSystemtray", checked)
        }
    }

    CheckBox {
        visible: typeof(uiSettings.data.minimizeToSystemtray) !== "undefined" ? uiSettings.data.minimizeToSystemtray : false
        //: Text description of an option to show a notification in the Systemtray when a new message arrives
        text: qsTr("Show notification in Systemtray when a new message arrives and window is minimized")
        checked: uiSettings.data.showNotificationSystemtray || false
        onCheckedChanged: {
            uiSettings.write("showNotificationSystemtray", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("showNotificationSystemtray", checked)
        }
    }

    CheckBox {
        visible: !styleHelper.isGroupHostMode
        //: Text description of an option to play audio notifications when contacts log in, log out, and send messages
        text: qsTr("Play audio notifications")
        checked: uiSettings.data.playAudioNotification || false
        onCheckedChanged: {
            uiSettings.write("playAudioNotification", checked)
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: text
        Accessible.onPressAction: {
            uiSettings.write("playAudioNotification", checked)
        }
    }
    RowLayout {
        visible: !styleHelper.isGroupHostMode
        Item { width: 16 }

        Label {
            //: Label for a slider used to adjust audio notification volume
            text: qsTr("Volume")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        Slider {
            maximumValue: 1.0
            updateValueWhileDragging: false
            enabled: uiSettings.data.playAudioNotification || false
            value: uiSettings.read("notificationVolume", 0.75)
            onValueChanged: {
                uiSettings.write("notificationVolume", value)
            }

            Accessible.role: Accessible.Slider
            //: Name of the slider used to adjust audio notification volume for accessibility tech like screen readers
            Accessible.name: qsTr("Volume")
            Accessible.onIncreaseAction: {
                value += 0.125 // 8 volume settings
            }
            Accessible.onDecreaseAction: {
                value -= 0.125
            }
        }
    }

    RowLayout {
        z: 2
        Label {
            //: Label for combobox where users can specify the UI language
            text: qsTr("Language")
            Accessible.role: Accessible.StaticText
            Accessible.name: text
        }

        ComboBox {
            id: languageBox
            model: languageModel
            textRole: "nativeName"
            currentIndex: languageModel.rowForLocaleID(uiSettings.data.language)
            Layout.minimumWidth: 200

            LanguagesModel {
                id: languageModel
            }

            onActivated: {
                var localeID = languageModel.localeID(index)
                uiSettings.write("language", localeID)
                restartBubble.displayed = true
                bubbleResetTimer.start()
            }

            Bubble {
                id: restartBubble
                target: languageBox
                text: qsTr("Restart Speek to apply changes")
                displayed: false
                horizontalAlignment: Qt.AlignRight

                Timer {
                    id: bubbleResetTimer
                    interval: 3000
                    onTriggered: restartBubble.displayed = false
                }
            }
            Accessible.role: Accessible.ComboBox
            //: Name of the combobox used to select UI langauge for accessibility tech like screen readers
            Accessible.name: qsTr("Language")
            //: Description of what the language combox is for for accessibility tech like screen readers
            Accessible.description: qsTr("What language Speek will use")
        }
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
