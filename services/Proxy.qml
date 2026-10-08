pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool enabled: false
    property bool automatic: false
    property string kind: "http"
    property string host: ""
    property int port: 8080
    property string error: ""
    property string testMessage: ""
    property bool browserRestartRequired: false
    readonly property bool busy: operation.running
    property var pending: ({action: "status"})

    function run(request: var): void {
        if (operation.running)
            return;
        pending = request;
        error = "";
        operation.running = true;
    }

    function refresh(): void { run({action: "status"}); }
    function test(): void { run({action: "test"}); }
    function toggle(value: bool): void { run({action: "toggle", enabled: value}); }
    function save(hostname: string, proxyPort: string, type: string, active: bool): void {
        run({action: "save", host: hostname, port: proxyPort, kind: type, enabled: active});
    }

    Component.onCompleted: refresh()

    Process {
        id: operation
        command: ["/usr/bin/python3", `${Quickshell.env("HOME")}/.local/share/caelestia-ubuntu/bin/proxy-control.py`]
        environment: ({XDG_CONFIG_HOME: `${Quickshell.env("HOME")}/.config`})
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(root.pending) + "\n");
            stdinEnabled = false;
        }
        onRunningChanged: { if (!running) stdinEnabled = true; }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!data.ok) { root.error = data.error; return; }
                    root.enabled = data.enabled;
                    root.automatic = data.automatic;
                    root.kind = data.kind;
                    root.host = data.host;
                    root.port = data.port;
                    root.browserRestartRequired = data.browserRestartRequired;
                    if (data.testMessage !== undefined) root.testMessage = data.testMessage;
                } catch (_) {
                    root.error = "Proxy settings are unavailable.";
                }
            }
        }
    }

    // One sleeping settings subscription; no periodic connections or probes.
    Process {
        running: true
        command: ["dconf", "watch", "/system/proxy/"]
        environment: ({XDG_CONFIG_HOME: `${Quickshell.env("HOME")}/.config`})
        stdout: SplitParser {
            onRead: _ => changed.restart()
        }
    }
    Timer {
        id: changed
        interval: 200
        onTriggered: {
            if (root.busy) restart();
            else root.refresh();
        }
    }
}
