/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"
import "../js/functions.js" as Functions
import "../js/twemoji.js" as Emoji

Flickable {
    id: messageOverlayFlickable
    anchors.fill: parent
    boundsBehavior: Flickable.StopAtBounds
    contentHeight: messageContentColumn.height
    clip: true

    property var overlayMessage;
    property bool showHeader: true
    readonly property var userInformation: tdLibWrapper.getUserInformation(overlayMessage.sender_user_id);
    readonly property bool isOwnMessage: tdLibWrapper.getUserInformation().id === overlayMessage.sender_user_id;
    signal requestClose;

    function getOriginalAuthor(forwardInformation, fontSize) {
        if (forwardInformation.origin["@type"] === "messageForwardOriginChannel") {
            var otherChatInformation = tdLibWrapper.getChat(forwardInformation.origin.chat_id);
            return Emoji.emojify(otherChatInformation.title, fontSize);
        } else if (forwardInformation.origin["@type"] === "messageForwardOriginUser") {
            var otherUserInformation = tdLibWrapper.getUserInformation(forwardInformation.origin.sender_user_id);
            return Emoji.emojify(Functions.getUserName(otherUserInformation), fontSize);
        } else {
            return Emoji.emojify(forwardInformation.origin.sender_name, fontSize);
        }
    }

    Component.onCompleted: {
        delegateComponentLoadingTimer.start();
    }

    Timer {
        id: delegateComponentLoadingTimer
        interval: 500
        repeat: false
        running: false
        onTriggered: {
            if (typeof overlayMessage.content !== "undefined") {
//                if (messageListItem.extraContentComponentName !== "") {
//                    extraContentLoader.setSource(
//                                "../components/" +messageListItem.extraContentComponentName +".qml",
//                                {
//                                    messageListItem: messageListItem
//                                })
//                } else {
                    if (typeof overlayMessage.content.web_page !== "undefined") {
                        overlayWebPagePreviewLoader.active = true;
                    }
//                }
            }
        }
    }

    Rectangle {
        id: messageContentBackground
        color: (Theme.colorScheme === Theme.LightOnDark) ? Theme.darkSecondaryColor : Theme.lightSecondaryColor
        width: parent.width
        height: messageContentColumn.height >= messageOverlayFlickable.height ? messageContentColumn.height : messageOverlayFlickable.height
        MouseArea {
            anchors.fill: parent
            onClicked: {
                messageOverlayFlickable.requestClose();
            }
        }
    }

    Column {
        id: messageContentColumn
        spacing: Theme.paddingMedium
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - ( 2 * Theme.horizontalPageMargin )

        Row {
            visible: messageOverlayFlickable.showHeader
            width: parent.width
            spacing: Theme.paddingMedium
            ProfileThumbnail {
                id: overlayMessagePictureThumbnail
                photoData: (typeof messageOverlayFlickable.userInformation.profile_photo !== "undefined") ? messageOverlayFlickable.userInformation.profile_photo.small : ({})
                replacementStringHint: overlayMessageUserText.text
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
            }
            Text {
                id: overlayMessageUserText

                width: parent.width - overlayMessagePictureThumbnail.width
                anchors.verticalCenter: parent.verticalCenter
                text: messageOverlayFlickable.isOwnMessage ? qsTr("You") : Emoji.emojify(Functions.getUserName(messageOverlayFlickable.userInformation), font.pixelSize)
                font.pixelSize: Theme.fontSizeExtraLarge
                font.weight: Font.ExtraBold
                color: Theme.primaryColor
                maximumLineCount: 1
                elide: Text.ElideRight
                textFormat: Text.StyledText
            }
        }

        Text {
            id: overlayForwardedInfoText
            width: parent.width
            visible: typeof overlayMessage.forward_info !== "undefined"
            font.pixelSize: Theme.fontSizeSmall
            font.italic: true
            textFormat: Text.StyledText
            color: Theme.secondaryColor
            wrapMode: Text.Wrap
            text: visible ? qsTr("This message was forwarded. Original author: %1").arg(getOriginalAuthor(overlayMessage.forward_info, font.pixelSize)) : ""
        }

        Text {
            id: overlayMessageText
            width: parent.width
            text: Emoji.emojify(Functions.getMessageText(overlayMessage, false, messageOverlayFlickable.isOwnMessage), font.pixelSize)
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            onLinkActivated: {
                Functions.handleLink(link);
            }
            linkColor: Theme.highlightColor
            visible: (text !== "")
        }

        Loader {
            id: overlayWebPagePreviewLoader
            active: false
            asynchronous: true
            width: parent.width

            sourceComponent: Component {
                id: webPagePreviewComponent
                WebPagePreview {
                    id: webPagePreview

                    onImplicitHeightChanged: {
                        webPagePreviewLoader.height = webPagePreview.implicitHeight;
                    }

                    webPageData: overlayMessage.content.web_page
                    largerFontSize: true
                    width: parent.width
                }
            }
        }

        Label {
            id: separatorLabel
            width: parent.width
            font.pixelSize: Theme.fontSizeSmall
        }

    }

    VerticalScrollDecorator {}
}
