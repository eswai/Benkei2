import Foundation
import Carbon
import Yams

struct NaginataCommand: Decodable {
    let mae: [Int]
    let douji: [Int]
    let type: [[String: String]]
    
    private enum CodingKeys: String, CodingKey {
        case mae, douji, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // String配列をデコードしてInt配列に変換
        let maeStrings = try container.decode([String].self, forKey: .mae)
        let doujiStrings = try container.decode([String].self, forKey: .douji)
        
        // キーコードに変換
        self.mae = maeStrings.compactMap { NaginataReader.keyCodeMap[$0] }
        self.douji = doujiStrings.compactMap { NaginataReader.keyCodeMap[$0] }
        
        // typeの変換処理を追加
        self.type = try container.decode([[String: String]].self, forKey: .type)
    }
}

class NaginataReader {

    static let keyCodeMap: Dictionary<String, Int> = [
        // Letters
        "A": kVK_ANSI_A,
        "B": kVK_ANSI_B,
        "C": kVK_ANSI_C,
        "D": kVK_ANSI_D,
        "E": kVK_ANSI_E,
        "F": kVK_ANSI_F,
        "G": kVK_ANSI_G,
        "H": kVK_ANSI_H,
        "I": kVK_ANSI_I,
        "J": kVK_ANSI_J,
        "K": kVK_ANSI_K,
        "L": kVK_ANSI_L,
        "M": kVK_ANSI_M,
        "N": kVK_ANSI_N,
        "O": kVK_ANSI_O,
        "P": kVK_ANSI_P,
        "Q": kVK_ANSI_Q,
        "R": kVK_ANSI_R,
        "S": kVK_ANSI_S,
        "T": kVK_ANSI_T,
        "U": kVK_ANSI_U,
        "V": kVK_ANSI_V,
        "W": kVK_ANSI_W,
        "X": kVK_ANSI_X,
        "Y": kVK_ANSI_Y,
        "Z": kVK_ANSI_Z,

        // Numbers
        "0": kVK_ANSI_0,
        "1": kVK_ANSI_1,
        "2": kVK_ANSI_2,
        "3": kVK_ANSI_3,
        "4": kVK_ANSI_4,
        "5": kVK_ANSI_5,
        "6": kVK_ANSI_6,
        "7": kVK_ANSI_7,
        "8": kVK_ANSI_8,
        "9": kVK_ANSI_9,

        // Special Keys
        "Return": kVK_Return,
        "Tab": kVK_Tab,
        "Space": kVK_Space,
        "Delete": kVK_Delete,
        "Escape": kVK_Escape,
        "Command": kVK_Command,
        "Shift": kVK_Shift,
        "CapsLock": kVK_CapsLock,
        "Option": kVK_Option,
        "Control": kVK_Control,
        "RightCommand": kVK_RightCommand,
        "RightShift": kVK_RightShift,
        "RightOption": kVK_RightOption,
        "RightControl": kVK_RightControl,
        "Function": kVK_Function,

        // Symbols
        "Equal": kVK_ANSI_Equal,
        "Minus": kVK_ANSI_Minus,
        "RightBracket": kVK_ANSI_RightBracket,
        "LeftBracket": kVK_ANSI_LeftBracket,
        "Quote": kVK_ANSI_Quote,
        "Semicolon": kVK_ANSI_Semicolon,
        "Backslash": kVK_ANSI_Backslash,
        "Comma": kVK_ANSI_Comma,
        "Slash": kVK_ANSI_Slash,
        "Period": kVK_ANSI_Period,
        "Grave": kVK_ANSI_Grave,

        // Arrow Keys
        "RightArrow": kVK_RightArrow,
        "LeftArrow": kVK_LeftArrow,
        "DownArrow": kVK_DownArrow,
        "UpArrow": kVK_UpArrow,

        // Keypad
        "KeypadDecimal": kVK_ANSI_KeypadDecimal,
        "KeypadMultiply": kVK_ANSI_KeypadMultiply,
        "KeypadPlus": kVK_ANSI_KeypadPlus,
        "KeypadClear": kVK_ANSI_KeypadClear,
        "KeypadDivide": kVK_ANSI_KeypadDivide,
        "KeypadEnter": kVK_ANSI_KeypadEnter,
        "KeypadMinus": kVK_ANSI_KeypadMinus,
        "KeypadEquals": kVK_ANSI_KeypadEquals,
        "Keypad0": kVK_ANSI_Keypad0,
        "Keypad1": kVK_ANSI_Keypad1,
        "Keypad2": kVK_ANSI_Keypad2,
        "Keypad3": kVK_ANSI_Keypad3,
        "Keypad4": kVK_ANSI_Keypad4,
        "Keypad5": kVK_ANSI_Keypad5,
        "Keypad6": kVK_ANSI_Keypad6,
        "Keypad7": kVK_ANSI_Keypad7,
        "Keypad8": kVK_ANSI_Keypad8,
        "Keypad9": kVK_ANSI_Keypad9,

        // Function Keys
        "F1": kVK_F1,
        "F2": kVK_F2,
        "F3": kVK_F3,
        "F4": kVK_F4,
        "F5": kVK_F5,
        "F6": kVK_F6,
        "F7": kVK_F7,
        "F8": kVK_F8,
        "F9": kVK_F9,
        "F10": kVK_F10,
        "F11": kVK_F11,
        "F12": kVK_F12,
        "F13": kVK_F13,
        "F14": kVK_F14,
        "F15": kVK_F15,
        "F16": kVK_F16,
        "F17": kVK_F17,
        "F18": kVK_F18,
        "F19": kVK_F19,
        "F20": kVK_F20,

        // Volume Controls
        "VolumeUp": kVK_VolumeUp,
        "VolumeDown": kVK_VolumeDown,
        "Mute": kVK_Mute,

        // Other
        "Help": kVK_Help,
        "Home": kVK_Home,
        "PageUp": kVK_PageUp,
        "ForwardDelete": kVK_ForwardDelete,
        "End": kVK_End,
        "PageDown": kVK_PageDown
    ]

    static func readNaginataFile(path: String) -> [NaginataCommand]? {
        guard let yamlString = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        guard let yamlData = yamlString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let decoder = YAMLDecoder()
            let commands = try decoder.decode([NaginataCommand].self, from: yamlData)
            return commands
        } catch {
            print("Error decoding YAML: \(error)")
            return nil
        }
    }
    
    static func parseCommands(from path: String) {
        guard let commands = readNaginataFile(path: path) else {
            print("Failed to read Naginata file")
            return
        }
        
        for command in commands {
            print("Mae: \(command.mae)")
            print("Douji: \(command.douji)")
            print("Type: \(command.type)")
        }
    }
}
