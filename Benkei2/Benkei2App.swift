import SwiftUI
import AppKit
import ServiceManagement

/// Login item registration. Enabled by default on first launch.
enum LaunchAtLogin {
    private static let defaultAppliedKey = "LaunchAtLoginDefaultApplied"

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
        }
    }

    /// Turn on automatic launch the first time the app runs, then respect the user's choice.
    static func applyDefaultIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: defaultAppliedKey) else { return }
        defaults.set(true, forKey: defaultAppliedKey)
        setEnabled(true)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(self, selector: #selector(remapperStatusChanged(_:)), name: KeyRemapper.statusChangedNotification, object: nil)

        LaunchAtLogin.applyDefaultIfNeeded()

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

    @objc func toggleLaunchAtLogin() {
        LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        refreshLaunchAtLoginUI()
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
        let toggleItem = NSMenuItem(title: "薙刀式かな入力", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        toggleItem.state = KeyRemapper.shared.isEnabled ? .on : .off
        toggleMenuItem = toggleItem
        menu.addItem(toggleItem)
        let launchItem = NSMenuItem(title: "ログイン時に起動", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        launchAtLoginMenuItem = launchItem
        menu.addItem(launchItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "終了", action: #selector(terminate), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    private func refreshRemapperUI() {
        toggleMenuItem?.state = KeyRemapper.shared.isEnabled ? .on : .off
        updateStatusBarIcon()
    }

    private func refreshLaunchAtLoginUI() {
        launchAtLoginMenuItem?.state = LaunchAtLogin.isEnabled ? .on : .off
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
