import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "theme"
import "components"
import "views"
import "overlay"

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 820
    minimumWidth: 1040
    minimumHeight: 680
    title: "ImmortalHub — Dota 2 Skin Changer"
    color: "#04060B"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Intercept window close to hide to tray
    onClosing: function(close_event) {
        close_event.accepted = false
        root.hide()
        toast.show("Minimized to system tray. Right-click the icon to quit.", "info")
    }

    // Deep cyberpunk background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#080C18" }
            GradientStop { position: 1.0; color: "#04060B" }
        }
        z: -100
    }

    // Ambient glow spots — atmospheric cyberpunk lighting
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        width: 400
        height: 400
        radius: 200
        color: SkinTheme.accentCyan
        opacity: 0.015
        z: -99
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 500
        height: 500
        radius: 250
        color: SkinTheme.accentViolet
        opacity: 0.012
        z: -99
    }



    // Animated scanning line sweep
    Rectangle {
        id: globalScanLine
        width: parent.width
        height: 1
        color: SkinTheme.accentCyan
        opacity: 0.04
        z: -97

        SequentialAnimation on y {
            running: true
            loops: Animation.Infinite
            NumberAnimation { to: root.height; duration: 6000; easing.type: Easing.Linear }
            NumberAnimation { to: 0; duration: 0 }
        }
    }

    // Scan line glow trail
    Rectangle {
        width: parent.width
        height: 40
        y: globalScanLine.y - 20
        z: -97
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: SkinTheme.accentCyanGlow }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.08
    }

    property string currentTab: "heroes"
    property var cart: []
    property var selectedDetailMod: null
    property bool isInstallingQueue: false
    property int queueInstallPercent: 0
    property string queueInstallStatus: ""
    property bool isDraggingFile: false

    function openSettings() {
        sidebar.currentTab = "settings"
        currentTab = "settings"
    }

    function addToCart(mod) {
        if (!mod) return
        for (var i = 0; i < cart.length; i++) {
            if (cart[i].name === mod.name && cart[i].categoryId === mod.categoryId) {
                toast.show("Skin '" + mod.name + "' is already in your queue", "info")
                return
            }
        }
        var next = cart.slice()
        next.push(mod)
        cart = next
        toast.show("Added '" + mod.name + "' to queue", "success")
    }

    function removeFromCart(index) {
        var next = []
        for (var i = 0; i < cart.length; i++) {
            if (i !== index) next.push(cart[i])
        }
        cart = next
    }

    function clearCart() {
        cart = []
        toast.show("Queue cleared", "info")
    }

    function installQueue() {
        if (!app.dotaDetected) {
            toast.show("Please configure your Dota 2 game path in Settings first!", "error")
            openSettings()
            return
        }
        if (cart.length === 0) return
        isInstallingQueue = true
        app.installBatch(JSON.stringify(cart))
    }

    Component.onCompleted: {
        SkinTheme.setTheme(app ? app.themeMode : "cyberpunk")
        app.loadAll()
        appStartupAnim.start()
    }

    Connections {
        target: app
        function onThemeModeChanged() {
            SkinTheme.setTheme(app.themeMode)
        }
        function onErrorOccurred(msg) {
            toast.show(msg, "error")
            isInstallingQueue = false
        }
        function onSuccessOccurred(msg) {
            toast.show(msg, "success")
        }
        function onProgressChanged(percent, status, item) {
            queueInstallPercent = percent
            queueInstallStatus = status
        }
        function onBatchFinished(success, msg) {
            isInstallingQueue = false
            if (success) {
                cart = []
            }
        }
    }

    // Drag & Drop Area
    DropArea {
        id: windowDropArea
        anchors.fill: parent
        z: 8000

        onEntered: function(drag) {
            if (drag.hasUrls) {
                root.isDraggingFile = true
            }
        }

        onExited: {
            root.isDraggingFile = false
        }

        onDropped: function(drop) {
            root.isDraggingFile = false
            if (drop.hasUrls) {
                for (var i = 0; i < drop.urls.length; i++) {
                    var u = drop.urls[i].toString()
                    if (u.toLowerCase().endsWith(".vpk") || u.toLowerCase().endsWith(".zip")) {
                        app.importCustomMod(u)
                    } else {
                        toast.show("Only .vpk and .zip mod files are supported.", "error")
                    }
                }
            }
        }
    }

    // Drop Overlay Indicator
    Rectangle {
        anchors.fill: parent
        color: "#EE040610"
        border.color: SkinTheme.accentCyan
        border.width: 1
        visible: root.isDraggingFile
        z: 8001

        // Scanning lines on drop overlay
        Column {
            anchors.fill: parent
            opacity: 0.03
            Repeater {
                model: Math.floor(parent.height / 4)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: SkinTheme.accentCyan
                    visible: index % 2 === 0
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 48
                height: 48
                radius: SkinTheme.radiusMedium
                color: "transparent"
                border.color: SkinTheme.accentCyan
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: SkinTheme.accentCyan
                    font.pixelSize: 24
                    font.weight: Font.Light
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "DROP .VPK OR .ZIP TO INSTALL"
                color: SkinTheme.textPrimary
                font.family: SkinTheme.fontMono
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2.0
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Files will be placed into your Dota 2 game directory"
                color: SkinTheme.textMuted
                font.pixelSize: 11
            }
        }
    }

    // Outer Border for Frameless Window
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: SkinTheme.borderMuted
        border.width: 1
        z: 999
        enabled: false
    }

    ParallelAnimation {
        id: appStartupAnim
        NumberAnimation {
            target: appContainer
            property: "opacity"
            from: 0.0; to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: appContainer
            property: "scale"
            from: 0.985; to: 1.0
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    function safeInstallMod(m) {
        if (!m) return
        var conflictJson = app.checkModConflict(JSON.stringify(m))
        if (conflictJson && conflictJson !== "{}") {
            try {
                var cObj = JSON.parse(conflictJson)
                if (cObj.hasConflict) {
                    conflictModal.conflictingMod = cObj.conflictingMod
                    conflictModal.newMod = m
                    conflictModal.isOpen = true
                    return
                }
            } catch (e) {}
        }
        app.installMod(JSON.stringify(m), m.categoryId)
    }

    // Main App Container
    Rectangle {
        id: appContainer
        anchors.fill: parent
        color: SkinTheme.bgVoid
        opacity: 0.0

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            SkinTitleBar {
                id: titleBar
                Layout.fillWidth: true
                rootWindow: root
                queueCount: root.cart.length
                onQueueClicked: cartDrawer.isOpen = true
                onPlayDotaClicked: app.launchDota()
                onPresetsClicked: presetsModal.isOpen = true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                SkinSidebar {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: sidebar.width
                    Layout.minimumWidth: sidebar.width
                    Layout.maximumWidth: sidebar.width
                    currentTab: root.currentTab
                    onTabSelected: function(tabId) { root.currentTab = tabId }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                // Views
                HeroesView {
                    anchors.fill: parent
                    visible: currentTab === "heroes"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                FavoritesView {
                    anchors.fill: parent
                    visible: currentTab === "favorites"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CategoryView {
                    anchors.fill: parent
                    visible: currentTab === "effects"
                    categoryIds: ["ti-bp-effects", "shaders", "emblems", "versus-screens"]
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CategoryView {
                    anchors.fill: parent
                    visible: currentTab === "map"
                    categoryIds: ["terrains", "trees", "river", "roshan", "ancient", "towers", "tormentor", "pedestal"]
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CategoryView {
                    anchors.fill: parent
                    visible: currentTab === "audio"
                    categoryIds: ["announcers", "mega-kill", "music", "sounds", "hero-sounds"]
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CategoryView {
                    anchors.fill: parent
                    visible: currentTab === "misc"
                    categoryIds: ["creeps", "creep-deny", "couriers", "wards", "huds", "item-effects", "item-icons", "ranks", "cursors", "fonts", "packs", "backgrounds", "other"]
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                FPSBoostView {
                    anchors.fill: parent
                    visible: currentTab === "fpsboost"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                InstalledView {
                    anchors.fill: parent
                    visible: currentTab === "installed"
                }

                SettingsView {
                    anchors.fill: parent
                    visible: currentTab === "settings"
                }
            }
        }
    }
    }

    // Drag and Drop VPK & ZIP Zone
    SkinDropZone {
        id: dropZone
        onFilesDropped: function(urls) {
            for (var i = 0; i < urls.length; i++) {
                app.importDroppedFile(urls[i])
            }
        }
    }

    // F2 Shortcut
    Shortcut {
        sequence: "F2"
        onActivated: app.toggleOverlay()
    }

    // Overlay
    DraftOverlayWindow {
        id: inGameOverlay
    }

    // Presets Modal
    SkinPresetsModal {
        id: presetsModal
        onApplyPresetRequested: function(preset) {
            if (preset && preset.items) {
                for (var i = 0; i < preset.items.length; i++) {
                    root.addToCart(preset.items[i])
                }
                cartDrawer.isOpen = true
            }
        }
        onSaveCurrentRequested: function(name, desc) {
            app.saveUserPreset(name, desc)
        }
        onDeletePresetRequested: function(pid) {
            app.deleteUserPreset(pid)
        }
    }

    // Conflict Detector Modal
    SkinConflictModal {
        id: conflictModal
        onReplaceRequested: function(oldMod, newMod) {
            if (oldMod && oldMod.name) {
                app.uninstallMod(oldMod.name, oldMod.categoryId)
            }
            if (newMod) {
                app.installMod(JSON.stringify(newMod), newMod.categoryId)
            }
        }
        onKeepBothRequested: function(newMod) {
            if (newMod) {
                app.installMod(JSON.stringify(newMod), newMod.categoryId)
            }
        }
    }

    // Detail Modal
    SkinDetailModal {
        id: detailModal
        modData: root.selectedDetailMod
        onCloseRequested: root.selectedDetailMod = null
        onAddToCartRequested: function(m) { root.addToCart(m) }
    }

    // Cart Drawer
    SkinCartDrawer {
        id: cartDrawer
        cartList: root.cart
        isInstalling: root.isInstallingQueue
        installPercent: root.queueInstallPercent
        installStatus: root.queueInstallStatus
        onCloseRequested: cartDrawer.isOpen = false
        onInstallAllRequested: root.installQueue()
        onClearRequested: root.clearCart()
        onRemoveItemRequested: function(idx) { root.removeFromCart(idx) }
    }

    // Toast
    SkinToast {
        id: toast
    }

    // Loading Splash — Cyberpunk Terminal
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgVoid
        visible: app.isLoading
        z: 9000

        // Scanning lines on splash
        Column {
            anchors.fill: parent
            opacity: 0.03
            Repeater {
                model: Math.floor(root.height / 3)
                Rectangle {
                    width: root.width
                    height: 1
                    color: "#FFFFFF"
                    visible: index % 2 === 0
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            AegisIcon {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "INITIALIZING SYSTEMS..."
                color: SkinTheme.accentCyan
                font.family: SkinTheme.fontMono
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 3.0

                SequentialAnimation on opacity {
                    running: app.isLoading
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            // Progress dots
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: 3
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: SkinTheme.accentCyan

                        SequentialAnimation on opacity {
                            running: app.isLoading
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 200 }
                            NumberAnimation { to: 0.2; duration: 400 }
                            NumberAnimation { to: 1.0; duration: 400 }
                        }
                    }
                }
            }
        }
    }

    // Resize Grip
    MouseArea {
        id: resizeGrip
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 16
        height: 16
        cursorShape: Qt.SizeFDiagCursor
        z: 1000

        property point clickPos: "0,0"

        onPressed: function(mouse) {
            clickPos = Qt.point(mouse.x, mouse.y)
        }

        onPositionChanged: function(mouse) {
            if (pressed) {
                var deltaX = mouse.x - clickPos.x
                var deltaY = mouse.y - clickPos.y
                root.width = Math.max(root.minimumWidth, root.width + deltaX)
                root.height = Math.max(root.minimumHeight, root.height + deltaY)
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: 8
            height: 8
            color: "transparent"

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 2
                height: 8
                color: SkinTheme.accentCyan
                opacity: 0.3
            }
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 8
                height: 2
                color: SkinTheme.accentCyan
                opacity: 0.3
            }
        }
    }
}
