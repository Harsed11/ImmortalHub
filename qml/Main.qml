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
    title: "ImmortalHub — Dota 2 Skin Changer"
    color: SkinTheme.bgVoid
    flags: Qt.Window | Qt.FramelessWindowHint

    // Intercept window close to hide to tray
    onClosing: function(close_event) {
        close_event.accepted = false
        root.hide()
        toast.show("Minimized to system tray. Right-click the icon to quit.", "info")
    }

    // Subtle background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: SkinTheme.bgDark }
            GradientStop { position: 1.0; color: SkinTheme.bgVoid }
        }
        z: -100
    }

    // Subtle aurora background
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

    // Drop Overlay
    Rectangle {
        anchors.fill: parent
        color: "#EE08080E"
        border.color: SkinTheme.accentCyan
        border.width: 2
        radius: 0
        visible: root.isDraggingFile
        z: 8001

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 56
                height: 56
                radius: SkinTheme.radiusLarge
                color: "transparent"
                border.color: SkinTheme.accentCyan
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: SkinTheme.accentCyan
                    font.pixelSize: 28
                    font.weight: Font.Light
                }
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
                text: "Files will be placed into your Dota 2 game directory"
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

        Image {
            anchors.fill: parent
            source: app.bgImagePath !== "" ? "file:///" + app.bgImagePath : ""
            fillMode: Image.PreserveAspectCrop
            visible: app.bgImagePath !== ""
            asynchronous: true
            opacity: 0.3
        }

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
                onSearchClicked: searchModal.openWith()
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
                DashboardView {
                    anchors.fill: parent
                    visible: currentTab === "dashboard"
                    onNavigateToHeroes: { root.currentTab = "heroes"; sidebar.currentTab = "heroes" }
                    onNavigateToInstalled: { root.currentTab = "installed"; sidebar.currentTab = "installed" }
                    onModClicked: function(m) { root.selectedDetailMod = m }
                }

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

                CreatorsView {
                    id: creatorsViewInstance
                    anchors.fill: parent
                    visible: currentTab === "creators"
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

    // Add Creator Modal
    AddCreatorModal {
        id: addCreatorModalInstance
    }

    // Add Creator Mod Modal
    AddCreatorModModal {
        id: addModModalInstance
    }

    // Loading Splash — Minimal Premium
    Rectangle {
        anchors.fill: parent
        color: SkinTheme.bgVoid
        visible: app.isLoading
        z: 9000

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            AegisIcon {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "LOADING..."
                color: SkinTheme.textSecondary
                font.family: SkinTheme.fontFamily
                font.pixelSize: SkinTheme.fontSizeBody
                font.weight: Font.Medium
                font.letterSpacing: 3.0

                SequentialAnimation on opacity {
                    running: app.isLoading
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
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
                color: SkinTheme.textMuted
                opacity: 0.3
            }
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 8
                height: 2
                color: SkinTheme.textMuted
                opacity: 0.3
            }
        }
    }
}
