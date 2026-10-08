pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root
    required property PopoutState popouts
    property string selectedKind: Proxy.kind
    implicitWidth: 330
    spacing: Tokens.spacing.medium
    Component.onCompleted: Proxy.refresh()

    RowLayout {
        Layout.fillWidth: true
        MaterialIcon { text: "settings_ethernet"; color: Colours.palette.m3primary }
        StyledText { Layout.fillWidth: true; text: "Proxy"; font: Tokens.font.body.builders.medium.weight(Font.Medium).build() }
        StyledSwitch {
            checked: Proxy.enabled
            enabled: !Proxy.busy
            onToggled: Proxy.toggle(checked)
        }
    }
    StyledText {
        Layout.fillWidth: true
        text: Proxy.automatic ? "Automatic configuration" : Proxy.enabled ? "System proxy enabled" : "Direct connection"
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }
    RowLayout {
        Layout.fillWidth: true
        IconTextButton {
            Layout.fillWidth: true
            text: "HTTP / HTTPS"; icon: "language"
            isToggle: true; checked: root.selectedKind === "http"
            onClicked: root.selectedKind = "http"
        }
        IconTextButton {
            Layout.fillWidth: true
            text: "SOCKS"; icon: "hub"
            isToggle: true; checked: root.selectedKind === "socks"
            onClicked: root.selectedKind = "socks"
        }
    }
    StyledTextField {
        id: hostname
        Layout.fillWidth: true
        placeholderText: "Proxy hostname"
        text: Proxy.host
        leadingIcon: "dns"
        verticalPadding: Tokens.padding.medium
        onAccepted: proxyPort.forceActiveFocus()
    }
    StyledTextField {
        id: proxyPort
        Layout.fillWidth: true
        placeholderText: "Proxy port"
        text: String(Proxy.port)
        leadingIcon: "tag"
        inputMethodHints: Qt.ImhDigitsOnly
        validator: IntValidator { bottom: 1; top: 65535 }
        verticalPadding: Tokens.padding.medium
        onAccepted: Proxy.save(hostname.text, text, root.selectedKind, true)
    }
    StyledText {
        Layout.fillWidth: true
        visible: Proxy.error.length > 0
        text: Proxy.error
        color: Colours.palette.m3error
        wrapMode: Text.Wrap
        font: Tokens.font.body.small
    }
    IconTextButton {
        Layout.fillWidth: true
        text: Proxy.busy ? "Applying…" : "Save and enable"
        icon: "check"
        enabled: !Proxy.busy && hostname.text.trim().length > 0 && proxyPort.acceptableInput
        onClicked: Proxy.save(hostname.text, proxyPort.text, root.selectedKind, true)
    }
    IconTextButton {
        Layout.fillWidth: true
        text: "Test connection"
        icon: "network_check"
        enabled: !Proxy.busy && Proxy.host.length > 0
        onClicked: Proxy.test()
    }
    StyledText {
        Layout.fillWidth: true
        visible: Proxy.browserRestartRequired || Proxy.testMessage.length > 0
        text: Proxy.browserRestartRequired ? "Close and reopen Brave once to activate proxy switching." : Proxy.testMessage
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurfaceVariant
        wrapMode: Text.Wrap
    }
    StyledText {
        Layout.fillWidth: true
        text: "Applies to apps that use the system proxy."
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurfaceVariant
        wrapMode: Text.Wrap
    }
}
