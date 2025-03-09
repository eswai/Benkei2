import Cocoa
import Carbon
import AppKit

class KeyRemapper {
    static let shared = KeyRemapper()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var isEnabled: Bool = true

    // Sample key mappings: change these as needed.
    let englishMapping: [CGKeyCode: CGKeyCode] = [
        // map 'A' (key code 0) to 'B' (key code 11)
        0: 11
    ]
    let japaneseMapping: [CGKeyCode: CGKeyCode] = [
        // map 'A' (key code 0) to 'C' (key code 8)
        0: 8
    ]

    private init() {}

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
            let originalKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let mode = getCurrentInputMode()
            let mapping = (mode == "en") ? englishMapping : japaneseMapping
            if let newKeyCode = mapping[CGKeyCode(originalKeyCode)] {
                event.setIntegerValueField(.keyboardEventKeycode, value: Int64(newKeyCode))
            }
        }
        return Unmanaged.passRetained(event)
    }
}
