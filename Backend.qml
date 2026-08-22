import QtQuick
import Quickshell.Io

Item {
  id: root
  visible: false

  // Injected by omarchy-shell's singleton service loader.
  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest ? String(manifest.id) : "hz.auto-brightness"
  property bool automatic: true
  property int offsetPercent: 0
  property int speed: 2
  property int smoothing: 5
  property bool manualOverride: false
  property int lux: 0
  property int brightness: 0
  property int targetBrightness: 0
  property bool statusReady: false
  property string error: ""
  property bool settingsReady: false

  function clamp(value, minimum, maximum, fallback) {
    var number = Math.round(Number(value))
    if (!isFinite(number)) number = fallback
    return Math.max(minimum, Math.min(maximum, number))
  }

  function currentSettings() {
    var config = shell ? shell.barConfig : null
    var layout = config && config.layout ? config.layout : null
    if (!layout) return ({})

    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var entries = layout[sections[s]]
      if (!Array.isArray(entries)) continue
      for (var i = 0; i < entries.length; i++) {
        var entry = entries[i]
        var id = typeof entry === "object" && entry !== null ? entry.id : entry
        if (String(id || "") === pluginId)
          return typeof entry === "object" && entry !== null ? entry : ({})
      }
    }
    return ({})
  }

  function applySettings() {
    if (!shell) return
    var settings = currentSettings()
    var nextAutomatic = settings.automatic === undefined ? true : settings.automatic === true
    var nextOffset = clamp(settings.offset, -20, 20, 0)
    var nextSpeed = clamp(settings.speed, 1, 5, 2)
    var nextSmoothing = clamp(settings.smoothing, 1, 10, 5)
    var tuningChanged = settingsReady &&
      (nextOffset !== offsetPercent || nextSpeed !== speed || nextSmoothing !== smoothing)

    automatic = nextAutomatic
    offsetPercent = nextOffset
    speed = nextSpeed
    smoothing = nextSmoothing
    settingsReady = true

    if (!automatic) {
      restartTimer.stop()
      autoProcess.running = false
    } else if (tuningChanged || !autoProcess.running) {
      restart()
    }
  }

  function restart() {
    if (!automatic || !settingsReady) return
    statusReady = false
    manualOverride = false
    error = ""
    if (autoProcess.running) autoProcess.running = false
    restartTimer.restart()
  }

  function applyState(raw) {
    try {
      var state = JSON.parse(String(raw || "{}"))
      lux = Number(state.lux || 0)
      brightness = Number(state.brightness || 0)
      targetBrightness = Number(state.target || 0)
      manualOverride = state.manualOverride === true
      statusReady = true
      error = ""
    } catch (parseError) {
      error = "Invalid automatic-brightness status"
    }
  }

  onShellChanged: if (shell) Qt.callLater(applySettings)

  Connections {
    target: root.shell
    function onBarConfigChanged() { root.applySettings() }
  }

  Timer {
    id: restartTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (!root.automatic || !root.settingsReady) return
      autoProcess.command = [
        Qt.resolvedUrl("bin/auto-brightness").toString().replace(/^file:\/\//, ""),
        String(root.offsetPercent),
        String(root.speed),
        String(root.smoothing)
      ]
      autoProcess.running = true
    }
  }

  Process {
    id: autoProcess
    stdout: SplitParser { onRead: function(line) { root.applyState(line) } }
    stderr: SplitParser {
      onRead: function(line) {
        var message = String(line || "").trim()
        if (message) root.error = message
      }
    }
    onRunningChanged: {
      if (!running && root.automatic && root.settingsReady && !restartTimer.running)
        restartTimer.restart()
    }
  }

  IpcHandler {
    target: "hz.auto-brightness-backend"

    function status(): string {
      return JSON.stringify({
        enabled: root.automatic,
        lux: root.lux,
        brightness: root.brightness,
        target: root.targetBrightness,
        manualOverride: root.manualOverride,
        offset: root.offsetPercent,
        speed: root.speed,
        smoothing: root.smoothing,
        ready: root.statusReady,
        error: root.error
      })
    }

    function resume(): void { root.restart() }
  }
}
