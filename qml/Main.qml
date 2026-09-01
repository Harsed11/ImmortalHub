import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "theme"
import "components"
import "views"

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 820
    minimumWidth: 1040
    minimumHeight: 680
    title: "ImmortalHub — Dota 2 Skin Changer & Mod Manager"
    color: SkinTheme.bgVoid
    flags: Qt.Window | Qt.FramelessWindowHint

    // Intercept window close to hide to tray
    onClosing: function(close_event) {
        close_event.accepted = false
        root.hide()
        toast.show("Minimized to system tray. Right-click the tray icon to quit.", "info")
    }

    // Liquid Dark background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: SkinTheme.bgDark }
            GradientStop { position: 1.0; color: SkinTheme.bgVoid }
        }
        z: -100
    }

    // Subtle ambient glow
    AuroraBackground {
        anchors.fill: parent
        z: -98
    }

    property string currentTab: "dashboard"
    property var cart: []
    property var selectedDetailMod: null
    property bool isInstallingQueue: false
    property int queueInstallPercent: 0
    property string queueInstallStatus: ""
    property bool isDraggingFile: false

    function openSettings() {
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
        toast.show("Added '" + mod.name + "' to queue (" + cart.length + ")", "success")
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
        SkinTheme.applyAccentHue(app ? app.accentHue : "immortal")
        app.loadAll()
        appStartupAnim.start()
    }

    Connections {
        target: app
        function onThemeModeChanged() {
            SkinTheme.setTheme(app.themeMode)
        }
        function onAccentHueChanged() {
            SkinTheme.applyAccentHue(app.accentHue)
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
                        if (root.currentTab === "creators" && creatorsViewInstance.selectedCreatorId !== "") {
                            var cleanLocal = u.replace("file:///", "").replace("file://", "")
                            addModModalInstance.openForCreator(
                                creatorsViewInstance.selectedCreatorId,
                                creatorsViewInstance.selectedCreatorData ? creatorsViewInstance.selectedCreatorData.name : "Custom",
                                cleanLocal
                            )
                        } else {
                            app.importCustomMod(u)
                        }
                    } else {
                        toast.show("Only .vpk and .zip mod files are supported.", "error")
                    }
                }
            }
        }
    }

    // Drag Drop Overlay
    Rectangle {
        anchors.fill: parent
        color: "#EE06070B"
        border.color: SkinTheme.accentCyan
        border.width: 2
        visible: root.isDraggingFile
        z: 8001

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "📦"
                font.pixelSize: 44
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "DROP .VPK OR .ZIP TO INSTALL"
                color: SkinTheme.textPrimary
                font.family: SkinTheme.fontFamily
                font.pixelSize: SkinTheme.fontSizeBody
                font.bold: true
                font.letterSpacing: 2.0
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Files will be automatically deployed to Dota 2"
                color: SkinTheme.textMuted
                font.pixelSize: SkinTheme.fontSizeSmall
            }
        }
    }

    // Window border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: SkinTheme.borderSubtle
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
            duration: 350
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: appContainer
            property: "scale"
            from: 0.99; to: 1.0
            duration: 350
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

    // Main App Canvas
    Rectangle {
        id: appContainer
        anchors.fill: parent
        color: SkinTheme.bgVoid
        opacity: 0.0

        Image {
            anchors.fill: parent
            source: (typeof app !== "undefined" && app && app.bgImagePath) ? "file:///" + app.bgImagePath : ""
            fillMode: Image.PreserveAspectCrop
            visible: typeof app !== "undefined" && app && Boolean(app.bgImagePath)
            asynchronous: true
            opacity: 0.25
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ═══════════════════════════════════════════
            // UNIFIED TOP-NAV GAMING HEADER
            // ═══════════════════════════════════════════
            SkinTopNav {
                id: topNav
                Layout.fillWidth: true
                rootWindow: root
                currentTab: root.currentTab
                queueCount: root.cart.length
                installedCount: (typeof app !== "undefined" && app) ? app.installedCount : 0
                onTabSelected: function(tabId) { root.currentTab = tabId }
                onQueueClicked: cartDrawer.isOpen = true
                onPlayDotaClicked: app.launchDota()
                onPresetsClicked: presetsModal.isOpen = true
                onSearchClicked: searchModal.openWith()
                onSettingsClicked: root.currentTab = "settings"
            }

            // ═══════════════════════════════════════════
            // FULL-WIDTH VIEWS STACK (100% Canvas Width)
            // ═══════════════════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                DashboardView {
                    anchors.fill: parent
                    visible: root.currentTab === "dashboard"
                    onNavigateToHeroes: root.currentTab = "heroes"
                    onNavigateToInstalled: root.currentTab = "installed"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                }

                HeroesView {
                    anchors.fill: parent
                    visible: root.currentTab === "heroes"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CreatorsView {
                    id: creatorsViewInstance
                    anchors.fill: parent
                    visible: root.currentTab === "creators"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                CategoryView {
                    anchors.fill: parent
                    visible: root.currentTab === "effects"
                    categoryIds: ["ti-bp-effects", "shaders", "emblems", "versus-screens", "terrains", "trees", "river", "roshan", "ancient", "towers", "announcers", "music", "sounds", "creeps", "couriers", "wards", "huds", "item-effects", "item-icons", "ranks", "cursors", "fonts", "packs", "backgrounds", "other"]
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                FPSBoostView {
                    anchors.fill: parent
                    visible: root.currentTab === "fpsboost"
                    onModClicked: function(m) { root.selectedDetailMod = m }
                    onModInstall: function(m) { root.safeInstallMod(m) }
                    onModUninstall: function(m) { app.uninstallMod(m.name, m.categoryId) }
                    onModAddToCart: function(m) { root.addToCart(m) }
                }

                InstalledView {
                    anchors.fill: parent
                    visible: root.currentTab === "installed"
                }

                SettingsView {
                    anchors.fill: parent
                    visible: root.currentTab === "settings"
                }
            }
        }
    }

    // Drag and Drop Zone
    SkinDropZone {
        id: dropZone
        onFilesDropped: function(urls) {
            for (var i = 0; i < urls.length; i++) {
                app.importDroppedFile(urls[i])
            }
        }
    }

    // Ctrl+K Shortcut
    Shortcut {
        sequence: "Ctrl+K"
        onActivated: searchModal.openWith()
    }

    // Global Search Modal
    GlobalSearchModal {
        id: searchModal
        onModPicked: function(m) { root.selectedDetailMod = m }
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

    // Detail Modal
    SkinDetailModal {
        id: detailModal
        modData: root.selectedDetailMod
        isOpen: root.selectedDetailMod !== null
        onCloseRequested: root.selectedDetailMod = null
        onInstallRequested: function(m) { root.safeInstallMod(m) }
        onUninstallRequested: function(m) { app.uninstallMod(m.name, m.categoryId) }
        onAddToCartRequested: function(m) { root.addToCart(m) }
    }

    // Conflict Modal
    SkinConflictModal {
        id: conflictModal
        onReplaceRequested: function(oldM, newM) {
            app.forceInstallMod(JSON.stringify(newM), newM.categoryId)
            conflictModal.isOpen = false
        }
        onKeepBothRequested: function(newM) {
            app.installMod(JSON.stringify(newM), newM.categoryId)
            conflictModal.isOpen = false
        }
        onCloseRequested: conflictModal.isOpen = false
    }

    // Queue Cart Drawer
    SkinCartDrawer {
        id: cartDrawer
        cartList: root.cart
        isInstalling: root.isInstallingQueue
        installPercent: root.queueInstallPercent
        installStatus: root.queueInstallStatus
        onRemoveItemRequested: function(index) { root.removeFromCart(index) }
        onClearRequested: root.clearCart()
        onInstallAllRequested: root.installQueue()
        onCloseRequested: cartDrawer.isOpen = false
    }

    // Toast Stack
    SkinToast {
        id: toast
    }
}
