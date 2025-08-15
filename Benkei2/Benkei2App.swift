import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // 設定ディレクトリを初期化（初回起動時に ~/Library/Containers/jp.eswai.Benkei2/Data/config を作成し、設定ファイルをコピー）
        ConfigManager.shared.initializeConfigDirectory()
        
        // Status bar icon initialization
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon()
        
        let menu = NSMenu()
        // Toggle menu: title shows target action (i.e. what to switch to)
        let toggleTitle = KeyRemapper.shared.isEnabled ? "無効" : "有効"
        menu.addItem(withTitle: toggleTitle, action: #selector(toggleEnabled), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "終了", action: #selector(terminate), keyEquivalent: "q")
        statusItem.menu = menu
        
        // Start key remapping
        KeyRemapper.shared.start()
    }
    
    @objc func toggleEnabled() {
        KeyRemapper.shared.isEnabled.toggle()
        if let menu = statusItem.menu, let toggleItem = menu.item(at: 0) {
            toggleItem.title = KeyRemapper.shared.isEnabled ? "無効" : "有効"
        }
        updateStatusBarIcon()
    }
    
    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let imageName = KeyRemapper.shared.isEnabled ? "Benkei_active" : "Benkei_inactive"
            button.image = NSImage(named: imageName)
            button.image?.isTemplate = true
        }
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
