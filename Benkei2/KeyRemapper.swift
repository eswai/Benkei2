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
    
    private func getCurrentInputMode() -> String {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return "en"
        }
        let sourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
        let sourceIDString = Unmanaged<CFString>.fromOpaque(sourceID!).takeUnretainedValue() as String
        
        return sourceIDString.contains("com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese") ? "ja" : "en"
    }

    func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passRetained(event) }

        if event.getIntegerValueField(.eventSourceUserData) == 1 {
            return Unmanaged.passRetained(event)
        }

        let mode = getCurrentInputMode()
        let originalKeyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))

        if mode == "en" && (type == .keyDown || type == .keyUp) {
//            if let targetKeys = englishMapping[originalKeyCode] {
//                if targetKeys.count == 1 {
//                    event.setIntegerValueField(.keyboardEventKeycode, value: Int64(targetKeys[0]))
//                    return Unmanaged.passRetained(event)
//                } else if targetKeys.count >= 2 {
//                    handleTargetKeys(targetKeys)
//                    return nil
//                }
//            }
        }
        
        // 修飾キーが押されている場合は処理をスキップ
        let flags = event.flags
        if flags.contains(.maskCommand) || flags.contains(.maskShift) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passRetained(event)
        }
        
        if mode == "ja" && (type == .keyDown || type == .keyUp) && ng.isNaginata(kc: originalKeyCode) {
            // キーアップの場合は、pressedKeysから削除
            if type == .keyUp {
                pressedKeys.remove(originalKeyCode)
                let targetKeys = ng.ngRelease(kc: originalKeyCode)
                handleTargetKeys(targetKeys)
                return nil
            }
            
            // キーダウンの場合は、まだ押されていないキーのみ処理
            if type == .keyDown && !pressedKeys.contains(originalKeyCode) {
                pressedKeys.insert(originalKeyCode)                
                let targetKeys = ng.ngPress(kc: originalKeyCode)
                handleTargetKeys(targetKeys)
                return nil
            }
        }

        return Unmanaged.passRetained(event)
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
                default:
                    print("no action")
                }
            }

        }
    }
}
