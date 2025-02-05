import QtQuick 2.2
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.2
import im.ricochet 1.0
import Qt.labs.platform 1.1
import "ContactWindow.js" as ContactWindow

ApplicationWindow {
    id: window
    title: !styleHelper.isGroupHostMode ? "Speek.Chat" : "Speek Group Host"
    visibility: Window.AutomaticVisibility

    property alias searchUserText: toolBar.searchUserText
    property alias systray: systray
    property var contactRequestDialogs: []
    property var contactRequestDialogsLength: 0
    property alias contactRequestSelectionDialog: toolBar.contactRequestSelectionDialog
    property var appNotificationsModel: []
    property alias appNotifications: appNotifications

    width: !styleHelper.isGroupHostMode ? 1000 : 500
    height: 600
    minimumHeight: 400
    minimumWidth: uiSettings.data.combinedChatWindow && !styleHelper.isGroupHostMode ? 880 : 480

    onMinimumWidthChanged: width = Math.max(width, minimumWidth)

    onVisibilityChanged: {
        if(visibility == 3 && uiSettings.data.minimizeToSystemtray){
            this.visible = false;
        }
    }

    onClosing: {
        Qt.quit()
    }

    SystemTrayIcon {
        id: systray
        visible: uiSettings.data.minimizeToSystemtray
        icon.source: "qrc:/icons/speek.png"

        onActivated: {
            window.show()
            window.raise()
            window.requestActivate()
        }

        menu: Menu {
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }

    // OS X Menu
    Loader {
        active: Qt.platform.os == 'osx'
        sourceComponent: MenuBar {
            Menu {
                title: "Speek.Chat"
                MenuItem {
                    text: qsTranslate("QCocoaMenuItem", "Preference")
                    onTriggered: toolBar.preferences.trigger()
                }
            }
        }
    }

    Connections {
        target: userIdentity.contacts
        function onUnreadCountChanged(user, unreadCount) {
            if (unreadCount > 0) {
                if (audioNotifications !== null)
                    audioNotifications.message.play()
                var w = window
                if (!uiSettings.data.combinedChatWindow || ContactWindow.windowExists(user))
                    w = ContactWindow.getWindow(user)
                // On OS X, avoid bouncing the dock icon forever
                w.alert(Qt.platform.os == "osx" ? 1000 : 0)
                if(!window.visible && uiSettings.data.showNotificationSystemtray)
                    systray.showMessage(qsTr("New Message"), ("You just received a new message from %1").arg(user.nickname),SystemTrayIcon.Information, 3000)
            }
        }
        function onContactStatusChanged(user, status) {
            if (status === ContactUser.Online && audioNotifications !== null) {
                audioNotifications.contactOnline.play()
            }
        }
    }

    AppNotifications{
        id: appNotifications
        anchors.right: parent.right
        anchors.top: parent.top
        z: 99
        model: appNotificationsModel
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle{
            id: leftColumn
            Layout.preferredWidth: combinedChatView.visible ? 220 : 0
            Layout.fillWidth: !combinedChatView.visible
            Layout.fillHeight: true
            ColumnLayout {
                spacing: 0
                anchors.fill: parent
    
                MainToolBar {
                    id: toolBar
                    // Needed to allow bubble to appear over contact list
                    z: 3
    
                    Accessible.role: Accessible.ToolBar
                    //: Name of the main toolbar for accessibility tech like screen readers
                    Accessible.name: qsTr("Main Toolbar")
                    //: Description of the main toolbar for accessibility tech like screen readers
                    Accessible.description: qsTr("Toolbar with connection status, add contact button, and preferences button")
                }
    
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
    
                    ContactList {
                        id: contactList
                        anchors.fill: parent
                        opacity: offlineLoader.item !== null ? (1 - offlineLoader.item.opacity) : 1
    
                        function onContactActivated(contact, actions) {
                            if (contact.status === ContactUser.RequestPending || contact.status === ContactUser.RequestRejected) {
                                actions.openPreferences()
                            } else if (!uiSettings.data.combinedChatWindow) {
                                actions.openWindow()
                            }
                        }
    
                        Accessible.role: Accessible.Pane
                        //: Name of the pane holding the user's contacts for accessibility tech like screen readers
                        Accessible.name: qsTr("Contact pane")
                    }
    
                    Loader {
                        id: offlineLoader
                        active: torControl.torStatus !== TorControl.TorReady
                        anchors.fill: parent
                        source: Qt.resolvedUrl("OfflineStateItem.qml")
                    }
                }


            }

            MouseArea {
                  enabled: combinedChatView.visible
                  id: mouseAreaRight
                  cursorShape: Qt.SizeHorCursor

                  property int oldMouseX
                  anchors.right: parent.right
                  anchors.top: parent.top
                  width: 6
                  anchors.bottom: parent.bottom
                  hoverEnabled: true

                  onPressed: {
                      oldMouseX = mouseX
                  }

                  onPositionChanged: {
                      if (pressed) {
                          leftColumn.Layout.preferredWidth = leftColumn.Layout.preferredWidth + (mouseX - oldMouseX)
                          if(leftColumn.Layout.preferredWidth > 300)
                              leftColumn.Layout.preferredWidth = 300
                          else if(leftColumn.Layout.preferredWidth < 220)
                              leftColumn.Layout.preferredWidth = 220
                      }
                  }
            }
        }

        Rectangle {
            visible: combinedChatView.visible
            width: 1
            Layout.fillHeight: true
            color: styleHelper.chatBoxBorderColorLeft
        }

        PageView {
            id: combinedChatView
            visible: uiSettings.data.combinedChatWindow && !styleHelper.isGroupHostMode
            Layout.fillWidth: true
            Layout.fillHeight: true

            property QtObject currentContact: (visible && width > 0) ? contactList.selectedContact : null
            onCurrentContactChanged: {
                if (currentContact !== null) {

                    // remove chat page for user when they are deleted
                    if(typeof currentContact.contactDeletedCallbackAdded === 'undefined') {
                        currentContact.contactDeleted.connect(function(user) {
                            remove(user.contactID);
                        });
                        currentContact.contactDeletedCallbackAdded = true;
                    }
                    show(currentContact.contactID, Qt.resolvedUrl("ChatPage.qml"),
                         { 'contact': currentContact });
                } else {
                    currentKey = ""
                }
            }
        }
    }

    property bool inactive: true
    onActiveFocusItemChanged: {
        // Focus current page when window regains focus
        if (activeFocusItem !== null && inactive) {
            inactive = false
            retakeFocus.start()
        } else if (activeFocusItem === null) {
            inactive = true
        }
    }

    Timer {
        id: retakeFocus
        interval: 1
        onTriggered: {
            if (combinedChatView.currentPage !== null)
                combinedChatView.currentPage.forceActiveFocus()
        }
    }

    Action {
        shortcut: StandardKey.Close
        onTriggered: window.close()
    }
}

