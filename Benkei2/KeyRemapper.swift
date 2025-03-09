import Cocoa
import Carbon
import AppKit

class KeyRemapper {
    static let shared = KeyRemapper()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var isEnabled: Bool = true
    private var ng: Naginata
    private var isSimulatingKeys: Bool = false  // 再帰的なリマップを防ぐ

    // Updated key mapping dictionaries using kVK_ANSI_* constants with explicit casting
    let englishMapping: [Int: [Int]] = [
        // one-to-one mapping
        kVK_ANSI_A: [kVK_ANSI_B],
        // one-to-many mapping
        kVK_ANSI_S: [kVK_ANSI_D, kVK_ANSI_F]
    ]
    let japaneseMapping: [Int: [Int]] = [
        kVK_ANSI_A: [kVK_ANSI_K, kVK_ANSI_I]
    ]

    private init() {
        ng = Naginata()
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
        
        return sourceIDString.contains("com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese") ? "jp" : "en"
    }

    func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        guard isEnabled else { return Unmanaged.passRetained(event) }
        if type == .keyDown || type == .keyUp {
            let originalKeyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let mode = getCurrentInputMode()
            let mapping = (mode == "en") ? englishMapping : japaneseMapping
            
            if let targetKeys = mapping[originalKeyCode] {
                if targetKeys.count == 1 {
                    // 1対1のマッピング
                    event.setIntegerValueField(.keyboardEventKeycode, value: Int64(targetKeys[0]))
                    return Unmanaged.passRetained(event)
                } else if targetKeys.count >= 2 && !isSimulatingKeys && type == .keyDown {
                    // 1対多のマッピング（キーダウン時のみ処理）
                    isSimulatingKeys = true
                    for key in targetKeys {
                        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: true),
                           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(key), keyDown: false) {
                            keyDown.post(tap: .cgSessionEventTap)
                            keyUp.post(tap: .cgSessionEventTap)
                        }
                    }
                    isSimulatingKeys = false
                    return nil // 元のイベントを抑制
                }
            }
        }
        return Unmanaged.passRetained(event)
    }
}
