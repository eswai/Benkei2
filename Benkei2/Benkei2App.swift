import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Status bar icon initialization
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Key Remapper")
        }
        
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
