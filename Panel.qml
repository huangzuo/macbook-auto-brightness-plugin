import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "hz.auto-brightness"
  ipcTarget: "hz.auto-brightness"

  readonly property var backend: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool autoEnabled: backend ? backend.automatic : false
  readonly property bool manualOverride: backend ? backend.manualOverride : false
  readonly property int lux: backend ? backend.lux : 0
  readonly property int brightness: backend ? backend.brightness : 0
  readonly property int targetBrightness: backend ? backend.targetBrightness : 0
  readonly property int offsetPercent: backend ? backend.offsetPercent : 0
  readonly property int speed: backend ? backend.speed : 2
  readonly property int smoothing: backend ? backend.smoothing : 5
  readonly property bool statusReady: backend ? backend.statusReady : false
  property var persistQueue: []
  property string persistError: ""

  readonly property string statusText: {
    if (!backend) return "STARTING AUTOMATIC CONTROL"
    if (backend.error) return "SENSOR UNAVAILABLE"
    if (!statusReady) return "CHECKING SENSOR"
    if (!autoEnabled) return "AUTOMATIC CONTROL PAUSED"
    if (manualOverride) return "MANUAL OVERRIDE"
    return "TRACKING AMBIENT LIGHT"
  }

  readonly property string lightName: {
    if (lux <= 0) return "Dark"
    if (lux < 20) return "Very dim"
    if (lux < 100) return "Indoor"
    if (lux < 400) return "Bright room"
    if (lux < 1000) return "Daylight"
    return "Strong daylight"
  }

  function persistSetting(key, value) {
    persistQueue.push([key, value])
    runPersistQueue()
  }

  function runPersistQueue() {
    if (persistProc.running || persistQueue.length === 0 || !moduleName) return
    var item = persistQueue.shift()
    persistProc.command = [
      "omarchy-shell", "shell", "setBarWidget", moduleName,
      String(item[0]), JSON.stringify(item[1]), "{}"
    ]
    persistProc.running = true
  }

  function runAction(action, value) {
    if (!backend) return
    if (action === "automatic") persistSetting("automatic", value)
    else if (action === "offset") persistSetting("offset", value)
    else if (action === "speed") persistSetting("speed", value)
    else if (action === "smoothing") persistSetting("smoothing", value)
    else if (action === "resume") backend.restart()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: persistProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var message = String(text || "").trim()
        if (message) root.persistError = message
      }
    }
    onRunningChanged: if (!running) Qt.callLater(root.runPersistQueue)
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.autoEnabled ? "󰃠" : "󰃞"
    active: root.autoEnabled
    tooltipText: root.autoEnabled
      ? "Automatic brightness · " + root.brightness + "% · " + root.lux + " lux"
      : "Automatic brightness paused"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton)
        root.runAction("automatic", !root.autoEnabled)
      else
        root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(590))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroPercent.implicitHeight)

          Text {
            id: heroIcon
            text: root.autoEnabled ? "󰃠" : "󰃞"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroPercent.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Automatic brightness"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.statusText
              color: Qt.darker(root.barForeground, 1.4)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.1
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroPercent
            text: root.brightness + "%"
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          StatCard { width: (parent.width - parent.spacing * 2) / 3; label: "LIGHT"; value: root.lux + " lux"; detail: root.lightName }
          StatCard { width: (parent.width - parent.spacing * 2) / 3; label: "CURRENT"; value: root.brightness + "%"; detail: "Display" }
          StatCard { width: (parent.width - parent.spacing * 2) / 3; label: "TARGET"; value: root.targetBrightness + "%"; detail: root.manualOverride ? "Waiting" : "Automatic" }
        }

        Toggle {
          width: parent.width
          label: "Automatic control"
          description: "Adjust display brightness as the room lighting changes"
          checked: root.autoEnabled
          enabled: root.backend !== null && !persistProc.running
          foreground: root.barForeground
          onClicked: root.runAction("automatic", !root.autoEnabled)
        }

        Button {
          visible: root.manualOverride && root.autoEnabled
          enabled: root.backend !== null
          width: parent.width
          text: "Resume automatic control"
          iconText: "󰑐"
          foreground: root.barForeground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          bordered: true
          onClicked: root.runAction("resume")
        }

        PanelSeparator { foreground: root.barForeground }

        LabeledSlider {
          id: preferenceControl
          title: "BRIGHTNESS PREFERENCE"
          value: root.offsetPercent
          minimum: -20
          maximum: 20
          tickCount: 5
          suffix: "%"
          showPlus: true
          enabled: root.backend !== null
          onCommitted: function(value) { root.runAction("offset", value) }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Dim"; foreground: root.barForeground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true; selected: root.offsetPercent === -10
            enabled: root.backend !== null
            onClicked: root.runAction("offset", -10)
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Balanced"; foreground: root.barForeground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true; selected: root.offsetPercent === 0
            enabled: root.backend !== null
            onClicked: root.runAction("offset", 0)
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Bright"; foreground: root.barForeground; fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true; selected: root.offsetPercent === 10
            enabled: root.backend !== null
            onClicked: root.runAction("offset", 10)
          }
        }

        PanelSeparator { foreground: root.barForeground }

        LabeledSlider {
          id: speedControl
          title: "RESPONSE SPEED"
          value: root.speed
          minimum: 1
          maximum: 5
          tickCount: 5
          suffix: " / 5"
          enabled: root.backend !== null
          onCommitted: function(value) { root.runAction("speed", value) }
        }

        LabeledSlider {
          id: smoothingControl
          title: "SMOOTHING"
          value: root.smoothing
          minimum: 1
          maximum: 10
          tickCount: 10
          suffix: " samples"
          enabled: root.backend !== null
          onCommitted: function(value) { root.runAction("smoothing", value) }
        }
      }
    }
  }

  component StatCard: BorderSurface {
    property string label: ""
    property string value: ""
    property string detail: ""
    implicitHeight: Style.space(72)
    radius: Style.cornerRadius
    color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.07)
    borderSpec: Border.controlSpec("normal", root.barForeground, Color.accent)

    Column {
      anchors.centerIn: parent
      width: parent.width - Style.space(12)
      spacing: Style.space(2)
      Text {
        width: parent.width; text: label; color: Qt.darker(root.barForeground, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption
        font.bold: true; font.letterSpacing: 1; horizontalAlignment: Text.AlignHCenter
      }
      Text {
        width: parent.width; text: value; color: root.barForeground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.subtitle
        font.bold: true; horizontalAlignment: Text.AlignHCenter
      }
      Text {
        width: parent.width; text: detail; color: Qt.darker(root.barForeground, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.caption
        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
      }
    }
  }

  component LabeledSlider: Column {
    id: control
    property string title: ""
    property int value: 0
    property int minimum: 0
    property int maximum: 100
    property int tickCount: 0
    property string suffix: ""
    property bool showPlus: false
    readonly property bool dragging: slider.dragging
    signal previewed(int value)
    signal committed(int value)
    width: parent ? parent.width : 0
    spacing: Style.space(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(controlTitle.implicitHeight, controlValue.implicitHeight)
      PanelSectionHeader {
        id: controlTitle
        text: control.title; foreground: root.barForeground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        id: controlValue
        readonly property int shown: slider.dragging ? Math.round(slider.liveValue) : control.value
        text: (control.showPlus && shown > 0 ? "+" : "") + shown + control.suffix
        color: Qt.darker(root.barForeground, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption; font.bold: true
        anchors.right: parent.right; anchors.rightMargin: Style.space(6); anchors.verticalCenter: parent.verticalCenter
      }
    }

    PanelSlider {
      id: slider
      width: parent.width
      bar: root.bar
      minimum: control.minimum
      maximum: control.maximum
      step: 1
      integer: true
      tickCount: control.tickCount
      value: control.value
      onMoved: function(value) { control.previewed(Math.round(value)) }
      onReleased: function(value) { control.committed(Math.round(value)) }
    }
  }
}
