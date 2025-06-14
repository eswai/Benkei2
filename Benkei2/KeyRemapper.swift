import Cocoa
import Carbon
import AppKit

class KeyRemapper {
    static let shared = KeyRemapper()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var isEnabled: Bool = true
    private var ng: Naginata
    private var pressedKeys: Set<Int> = []
    
    // H+J同時押し用の状態管理
    private var hjbuf: Int = -1 // 同時押し判定用のバッファ

    // Updated key mapping dictionaries using kVK_ANSI_* constants with explicit casting
    let englishMapping: [Int: [Int]] = [
        // one-to-one mapping
        kVK_ANSI_A: [kVK_ANSI_B],
        // one-to-many mapping
        // kVK_ANSI_S: [kVK_ANSI_D, kVK_ANSI_F]
    ]

    private init() {
        let yamlPath = Bundle.main.path(forResource: "Naginata", ofType: "yaml")!
        ng = Naginata(filePath: yamlPath)!
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
            print("Failed to create event tap")
        }
    }

    func stop() {
        if let eventTap = eventTap, let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
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
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return "en"
        }
        guard let sourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID) else {
            return "en"
        }
        let sourceIDString = Unmanaged<CFString>.fromOpaque(sourceID).takeUnretainedValue() as String
        
        // print("Current Input Source ID: \(sourceIDString)")
        return kanaMethods.contains(sourceIDString) ? "ja" : "en"
    }

    func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passRetained(event) }

        if event.getIntegerValueField(.eventSourceUserData) == 1 {
            return Unmanaged.passRetained(event)
        }

        let mode = getCurrentInputMode()
        let originalKeyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))

        // キーリピートが無効
        if type == .keyDown {
            pressedKeys.insert(originalKeyCode)
        } else if type == .keyUp {
            if pressedKeys.contains(originalKeyCode) {
                pressedKeys.remove(originalKeyCode)
            } else {
                return nil
            }
        }

        if mode == "en" {
            if type == .keyDown {
                if hjbuf == -1 {
                    if originalKeyCode == kVK_ANSI_H || originalKeyCode == kVK_ANSI_J {
                        hjbuf = originalKeyCode;
                        return nil;
                    }
                } else {
                    if hjbuf + originalKeyCode == kVK_ANSI_H + kVK_ANSI_J {
                        sendJISKanaKey()
                        hjbuf = -1
                        return nil
                    } else {
                        tapKey(keyCode: hjbuf)
                        pressedKeys.remove(hjbuf)
                        hjbuf = -1
                        return Unmanaged.passRetained(event)
                    }
                }
            } else if type == .keyUp {
                if hjbuf > -1 && hjbuf == originalKeyCode {
                    tapKey(keyCode: hjbuf)
                    pressedKeys.remove(hjbuf)
                    hjbuf = -1
                    return nil
                }
            }
        }
        
        // 修飾キーが押されている場合は処理をスキップ
        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskShift) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passRetained(event)
        }
        
        if mode == "ja" && (type == .keyDown || type == .keyUp) && ng.isNaginata(kc: originalKeyCode) {
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

        return Unmanaged.passRetained(event)
    }

    private func tapKey(keyCode: Int) {
        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false) {
            keyDown.setIntegerValueField(.eventSourceUserData, value: 1)
            keyUp.setIntegerValueField(.eventSourceUserData, value: 1)
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }
    }

    private func sendJISKanaKey() {
        ng.reset()
        pressedKeys.removeAll()
        tapKey(keyCode: kVK_JIS_Kana)
    }

    private func handleTargetKeys(_ targetKeys: [[String: String]]) {
        for action in targetKeys {
            for (mode, value) in action {
                switch mode {
                case "tap":
                    if let key = NaginataReader.keyCodeMap[value],
                       let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: true),
                       let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: false) {
                        keyDown.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyUp.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyDown.post(tap: .cgSessionEventTap)
                        keyUp.post(tap: .cgSessionEventTap)
                    }
                case "press":
                    if let key = NaginataReader.keyCodeMap[value],
                       let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: true) {
                        keyDown.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyDown.post(tap: .cgSessionEventTap)
                    }
                case "release":
                    if let key = NaginataReader.keyCodeMap[value],
                       let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: false) {
                        keyUp.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyUp.post(tap: .cgSessionEventTap)
                    }
                case "reset":
                    // Naginataの状態をリセット
                    ng.reset()
                    pressedKeys.removeAll()
                case "character":
                    // 未変換を確定
                    if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Eisu), keyDown: true),
                       let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Eisu), keyDown: false) {
                        keyDown.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyUp.setIntegerValueField(.eventSourceUserData, value: 1)
                        keyDown.post(tap: .cgSessionEventTap)
                        keyUp.post(tap: .cgSessionEventTap)
                    }
                    for scalar in value.unicodeScalars {
                        let uniChar = UniChar(scalar.value)
                        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: [uniChar])
                            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: [uniChar])
                            keyDown.setIntegerValueField(.eventSourceUserData, value: 1)
                            keyUp.setIntegerValueField(.eventSourceUserData, value: 1)
                            keyDown.post(tap: .cgSessionEventTap)
                            keyUp.post(tap: .cgSessionEventTap)
                        }
                    }
                    // 日本語入力へ切り替え。再変換にならないように「shift+かな」「かな」の2打にする。
                    if let shiftDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: true),
                        let kanaDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Kana), keyDown: true),
                        let kanaUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Kana), keyDown: false),
                        let shiftUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Shift), keyDown: false) {
                         shiftDown.setIntegerValueField(.eventSourceUserData, value: 1)
                         kanaDown.setIntegerValueField(.eventSourceUserData, value: 1)
                         kanaUp.setIntegerValueField(.eventSourceUserData, value: 1)
                         shiftUp.setIntegerValueField(.eventSourceUserData, value: 1)
                         shiftDown.flags = .maskShift
                         kanaDown.flags = .maskShift
                         kanaUp.flags = .maskShift
                         shiftDown.post(tap: .cgSessionEventTap)
                         kanaDown.post(tap: .cgSessionEventTap)
                         kanaUp.post(tap: .cgSessionEventTap)
                         shiftUp.post(tap: .cgSessionEventTap)
                    }
                    if let kanaDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Kana), keyDown: true),
                        let kanaUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_JIS_Kana), keyDown: false) {
                         kanaDown.setIntegerValueField(.eventSourceUserData, value: 1)
                         kanaUp.setIntegerValueField(.eventSourceUserData, value: 1)
                         kanaDown.post(tap: .cgSessionEventTap)
                         kanaUp.post(tap: .cgSessionEventTap)
                    }
                default:
                    print("no action")
                }
            }

        }
    }
}
