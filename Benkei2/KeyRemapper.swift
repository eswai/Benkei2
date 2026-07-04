import Cocoa
import Carbon
import AppKit

class KeyRemapper {
    static let shared = KeyRemapper()
    static let statusChangedNotification = Notification.Name("KeyRemapperStatusChanged")
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isEnabled: Bool = true {
        didSet {
            if oldValue != isEnabled {
                NotificationCenter.default.post(name: KeyRemapper.statusChangedNotification, object: nil)
            }
        }
    }
    static let sandsEnabledDefaultsKey = "sandsEnabled"
    private(set) var isSandSEnabled: Bool = true {
        didSet {
            if oldValue != isSandSEnabled {
                UserDefaults.standard.set(isSandSEnabled, forKey: KeyRemapper.sandsEnabledDefaultsKey)
                NotificationCenter.default.post(name: KeyRemapper.statusChangedNotification, object: nil)
            }
        }
    }
    private var ng: Naginata
    private var pressedKeys: Set<Int> = []
    private var keyRepeat = false
    private var allowRepeat: Bool = false // キーリピートを許可するかどうか
    private var sandsSpaceHeld = false // SandS: スペースを物理的に押下中か
    private var sandsSpaceUsedAsModifier = false // SandS: 押下中に他キーをシフト送出したか

    private init() {
        // 設定ファイルを設定ディレクトリから読み込み。
        // ユーザーが編集したYAMLが壊れていてもクラッシュせず、バンドル同梱のデフォルトへフォールバックする。
        ng = KeyRemapper.loadNaginata()
        // 未設定（初回起動）時はオンをデフォルトとする
        if UserDefaults.standard.object(forKey: KeyRemapper.sandsEnabledDefaultsKey) != nil {
            isSandSEnabled = UserDefaults.standard.bool(forKey: KeyRemapper.sandsEnabledDefaultsKey)
        }
    }

    private static func loadNaginata() -> Naginata {
        if let yamlPath = ConfigManager.shared.getNaginataConfigPath(),
           let naginata = Naginata(filePath: yamlPath) {
            return naginata
        }

        // ユーザー設定の読み込みに失敗した場合はバンドル同梱のデフォルト設定を使う
        if let bundlePath = Bundle.main.path(forResource: "Naginata", ofType: "yaml"),
           let naginata = Naginata(filePath: bundlePath) {
            DispatchQueue.main.async { KeyRemapper.showConfigErrorAlert() }
            return naginata
        }

        fatalError("Naginata.yaml not found")
    }

    private static func showConfigErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "設定ファイルを読み込めませんでした"
        alert.informativeText = "\(ConfigManager.shared.getConfigDirectoryPath()) の Naginata.yaml に問題があるため、デフォルト設定で起動しました。ファイルの内容を確認してください。"
        alert.alertStyle = .warning
        alert.runModal()
    }

    func setEnabled(_ enabled: Bool) {
        guard isEnabled != enabled else { return }
        isEnabled = enabled
        if !enabled {
            resetSandSState()
        }
    }

    func toggleEnabled() {
        setEnabled(!isEnabled)
    }

    func setSandSEnabled(_ enabled: Bool) {
        guard isSandSEnabled != enabled else { return }
        isSandSEnabled = enabled
        if !enabled {
            resetSandSState()
        }
    }

    func toggleSandS() {
        setSandSEnabled(!isSandSEnabled)
    }

    private func resetSandSState() {
        sandsSpaceHeld = false
        sandsSpaceUsedAsModifier = false
    }

    func start() {
        guard eventTap == nil else { return }
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            return KeyRemapper.shared.handle(event: event, type: type)
        }, userInfo: nil)
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            // アクセシビリティ権限がないとタップを作成できない。
            // 権限ダイアログを表示し、付与されるまでポーリングして自動でリトライする。
            print("Failed to create event tap")
            requestAccessibilityAndRetry()
        }
    }

    private func requestAccessibilityAndRetry() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        guard !trusted else {
            start()
            return
        }
        // 権限付与を待って再試行する
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self, self.eventTap == nil else { return }
            if AXIsProcessTrusted() {
                self.start()
            } else {
                self.requestAccessibilityAndRetry()
            }
        }
    }

    func stop() {
        if let eventTap = eventTap, let runLoopSource = runLoopSource {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }

    let kanaMethods = [
        "com.apple.inputmethod.Japanese",
        "com.apple.inputmethod.Japanese.Katakana",
        "com.apple.inputmethod.Japanese.HalfWidthKana"
    ]

    private func getCurrentInputMode() -> String {
        // TISCopyCurrentKeyboardInputSource は Create Rule のため takeRetainedValue で解放責任を引き受ける。
        // takeUnretainedValue だとキー入力ごとにリークする。
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return "en"
        }
        guard let sourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID) else {
            return "en"
        }
        let sourceIDString = Unmanaged<CFString>.fromOpaque(sourceID).takeUnretainedValue() as String

        return kanaMethods.contains(sourceIDString) ? "ja" : "en"
    }

    func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        // コールバックがタイムアウト等でOSにタップを無効化された場合、再度有効化する。
        // これをしないと一度無効化されたきり変換が黙って止まる。
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return nil
        }

        guard type == .keyDown || type == .keyUp else { return Unmanaged.passRetained(event) }

        if event.getIntegerValueField(.eventSourceUserData) == 1 {
            return Unmanaged.passRetained(event)
        }

        let originalKeyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // control + shift + 1で有効化、control + shift + 0で無効化
        if handleToggleShortcut(for: originalKeyCode, flags: flags, type: type) {
            return nil
        }

        // 無効時（サスペンド中）はすべて素通し。ここより上でトグルショートカットは処理済み。
        guard isEnabled else { return Unmanaged.passRetained(event) }

        let mode = getCurrentInputMode()

        // SandS: 英字モードではスペースをShiftキーと兼用する。
        // 修飾キー素通し判定より前に置くことで、スペース押下中のcmd+C等にもShiftを足せる。
        if isSandSEnabled {
            if mode != "en" {
                // スペース押下中に日本語モードへ切り替わった場合は状態だけ破棄する
                resetSandSState()
            } else {
                switch handleSandS(event: event, type: type, keyCode: originalKeyCode, flags: flags) {
                case .suppress:
                    return nil
                case .passModified:
                    return Unmanaged.passRetained(event)
                case .notHandled:
                    break
                }
            }
        }

        // 修飾キーが押されている場合は処理をスキップ
        if flags.contains(.maskCommand) || flags.contains(.maskShift) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            if mode == "ja" {
                postKeyEvent(keyCode: originalKeyCode, keyDown: (type == .keyDown))
                return nil
            }
            return Unmanaged.passRetained(event)
        }

        // kVK_ANSI_A to kVK_Escape
        guard originalKeyCode >= 0 && originalKeyCode <= 0x35 else {
            return Unmanaged.passRetained(event)
        }

        // キーリピートが無効
        if type == .keyDown {
            if pressedKeys.contains(originalKeyCode) {
                keyRepeat = true
            } else {
                keyRepeat = false
                pressedKeys.insert(originalKeyCode)
            }
        } else if type == .keyUp {
            keyRepeat = false
            allowRepeat = false
            if pressedKeys.contains(originalKeyCode) {
                pressedKeys.remove(originalKeyCode)
            } else {
                // 押下を記録していないキーのkeyUpは握りつぶさず素通しする。
                // （無効状態で押して有効化後に離した等でキーが押しっぱなしになるのを防ぐ）
                return Unmanaged.passRetained(event)
            }
        }

        if mode == "ja" {
            if ng.isNaginata(kc: originalKeyCode) {
                if !allowRepeat && keyRepeat {
                    return nil
                }
                if type == .keyUp {
                    let targetKeys = ng.ngRelease(kc: originalKeyCode)
                    handleTargetKeys(targetKeys)
                    return nil
                } else if type == .keyDown {
                    let targetKeys = ng.ngPress(kc: originalKeyCode)
                    handleTargetKeys(targetKeys)
                    return nil
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    private enum SandSResult {
        case suppress // イベントを握りつぶす
        case passModified // flagsを書き換えたイベントをそのまま流す
        case notHandled // SandSの対象外。通常フローへ
    }

    // 英字モードのSandS判定。スペース押下中は全キーにShiftを付与し、
    // 他キーを押さずに離した場合のみリリース時点でスペースを送出する（タイマー判定なし）。
    private func handleSandS(event: CGEvent, type: CGEventType, keyCode: Int, flags: CGEventFlags) -> SandSResult {
        let physicalModifiers: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]

        if keyCode == kVK_Space {
            if type == .keyDown {
                // スペース自体のキーリピートは無視
                if sandsSpaceHeld { return .suppress }
                // cmd+space（Spotlight）など物理修飾キー併用時は発動しない
                if !flags.intersection(physicalModifiers).isEmpty { return .notHandled }
                sandsSpaceHeld = true
                sandsSpaceUsedAsModifier = false
                return .suppress
            } else {
                // SandSとして押下を記録していないkeyUpは素通し（機能オン前から押されていた等）
                guard sandsSpaceHeld else { return .notHandled }
                sandsSpaceHeld = false
                let usedAsModifier = sandsSpaceUsedAsModifier
                sandsSpaceUsedAsModifier = false
                if !usedAsModifier {
                    postKeyEventWithFlags(keyCode: kVK_Space, keyDown: true, flags: [])
                    postKeyEventWithFlags(keyCode: kVK_Space, keyDown: false, flags: [])
                }
                return .suppress
            }
        }

        if sandsSpaceHeld {
            if type == .keyDown {
                sandsSpaceUsedAsModifier = true
            }
            // keyUpにもShiftを付与する（物理Shiftと同じ挙動）。
            // スペースリリース後に来るkeyUpは.notHandledで素通しになるが、文字はkeyDownで確定済みなので問題ない。
            event.flags = flags.union(.maskShift)
            return .passModified
        }
        return .notHandled
    }

    private func tapKey(keyCode: Int) {
        postKeyEvent(keyCode: keyCode, keyDown: true)
        postKeyEvent(keyCode: keyCode, keyDown: false)
    }

    private func postKeyEvent(keyCode: Int, keyDown: Bool) {
        if let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: keyDown) {
            keyEvent.setIntegerValueField(.eventSourceUserData, value: 1)
            keyEvent.post(tap: .cgSessionEventTap)
        }
    }

    private func postKeyEventWithFlags(keyCode: Int, keyDown: Bool, flags: CGEventFlags = []) {
        if let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: keyDown) {
            keyEvent.setIntegerValueField(.eventSourceUserData, value: 1)
            keyEvent.flags = flags
            keyEvent.post(tap: .cgSessionEventTap)
        }
    }

    private func postUnicodeEvent(unicodeString: [UniChar], keyDown: Bool) {
        if let keyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: keyDown) {
            keyEvent.keyboardSetUnicodeString(stringLength: unicodeString.count, unicodeString: unicodeString)
            keyEvent.setIntegerValueField(.eventSourceUserData, value: 1)
            keyEvent.post(tap: .cgSessionEventTap)
        }
    }

    private var currentModifierFlags: CGEventFlags = []

    private func updateModifierFlags(for key: Int, isPress: Bool) {
        switch key {
        case kVK_Shift:
            if isPress {
                currentModifierFlags.insert(.maskShift)
            } else {
                currentModifierFlags.remove(.maskShift)
            }
        case kVK_Control:
            if isPress {
                currentModifierFlags.insert(.maskControl)
            } else {
                currentModifierFlags.remove(.maskControl)
            }
        case kVK_Command:
            if isPress {
                currentModifierFlags.insert(.maskCommand)
            } else {
                currentModifierFlags.remove(.maskCommand)
            }
        case kVK_Option:
            if isPress {
                currentModifierFlags.insert(.maskAlternate)
            } else {
                currentModifierFlags.remove(.maskAlternate)
            }
        default:
            break
        }
    }

    private func handleTargetKeys(_ targetKeys: [[String: String]]) {
        for action in targetKeys {
            for (mode, value) in action {
                switch mode {
                case "tap":
                    if let key = NaginataReader.keyCodeMap[value] {
                        postKeyEventWithFlags(keyCode: key, keyDown: true, flags: currentModifierFlags)
                        postKeyEventWithFlags(keyCode: key, keyDown: false, flags: currentModifierFlags)
                    } else {
                        print("Unknown key: \(value)")
                    }
                case "press":
                    if let key = NaginataReader.keyCodeMap[value] {
                        updateModifierFlags(for: key, isPress: true)
                        postKeyEventWithFlags(keyCode: key, keyDown: true, flags: currentModifierFlags)
                    } else {
                        print("Unknown key: \(value)")
                    }
                case "release":
                    if let key = NaginataReader.keyCodeMap[value] {
                        postKeyEventWithFlags(keyCode: key, keyDown: false, flags: currentModifierFlags)
                        updateModifierFlags(for: key, isPress: false)
                    } else {
                        print("Unknown key: \(value)")
                    }
                case "repeat":
                    if value == "true" {
                        allowRepeat = true
                    } else {
                        allowRepeat = false
                    }
                case "reset":
                    ng.reset()
                    pressedKeys.removeAll()
                    currentModifierFlags = []
                case "character":
                    // 未変換を確定
                    tapKey(keyCode: kVK_JIS_Eisu)
                    
                    // Unicode文字を送信
                    for scalar in value.unicodeScalars {
                        let uniChar = UniChar(scalar.value)
                        postUnicodeEvent(unicodeString: [uniChar], keyDown: true)
                        postUnicodeEvent(unicodeString: [uniChar], keyDown: false)
                    }
                    
                    // 日本語入力へ切り替え
                    postKeyEventWithFlags(keyCode: kVK_Shift, keyDown: true, flags: .maskShift)
                    postKeyEventWithFlags(keyCode: kVK_JIS_Kana, keyDown: true, flags: .maskShift)
                    postKeyEventWithFlags(keyCode: kVK_JIS_Kana, keyDown: false, flags: .maskShift)
                    postKeyEventWithFlags(keyCode: kVK_Shift, keyDown: false)
                    
                    tapKey(keyCode: kVK_JIS_Kana)
                case "unmatch":
                    break
                default:
                    print("Unknown action: \(mode)")
                }
            }
        }
    }
    
    private func handleToggleShortcut(for keyCode: Int, flags: CGEventFlags, type: CGEventType) -> Bool {
        guard type == .keyDown else { return false }
        let usesShiftControl = flags.contains(.maskShift) && flags.contains(.maskControl)
        guard usesShiftControl else { return false }
        switch keyCode {
        case kVK_ANSI_1:
            setEnabled(true)
            return true
        case kVK_ANSI_0:
            setEnabled(false)
            return true
        default:
            return false
        }
    }
}
