import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // 設定ディレクトリを初期化（初回起動時に ~/Library/Containers/jp.eswai.Benkei2/Data/config を作成し、設定ファイルをコピー）
        ConfigManager.shared.initializeConfigDirectory()
        
        NotificationCenter.default.addObserver(self, selector: #selector(remapperStatusChanged(_:)), name: KeyRemapper.statusChangedNotification, object: nil)

        // Status bar icon initialization
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureStatusMenu()
        updateStatusBarIcon()
        
        // Start key remapping
        KeyRemapper.shared.start()
    }
    
    @objc func toggleEnabled() {
        KeyRemapper.shared.toggleEnabled()
        refreshRemapperUI()
    }
    
    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let imageName = KeyRemapper.shared.isEnabled ? "Benkei_active" : "Benkei_inactive"
            button.image = NSImage(named: imageName)
            button.image?.isTemplate = true
        }
    }

    private func configureStatusMenu() {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: currentRemapperTitle(), action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleMenuItem = toggleItem
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "終了", action: #selector(terminate), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func currentRemapperTitle() -> String {
        return KeyRemapper.shared.isEnabled ? "変換有効" : "変換オフ"
    }

    private func refreshRemapperUI() {
        toggleMenuItem?.title = currentRemapperTitle()
        updateStatusBarIcon()
    }

    @objc private func remapperStatusChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.refreshRemapperUI()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

@main
struct Benkei2App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        // Replace WindowGroup with Settings to avoid creating a startup window
        Settings {
            EmptyView()
        }
    }
}
