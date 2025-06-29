import Foundation
import Carbon

class Naginata {

    let NG_KEYCODE: [Int] = [
        kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_E, kVK_ANSI_R, kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_U, kVK_ANSI_I, kVK_ANSI_O, kVK_ANSI_P,
        kVK_ANSI_A, kVK_ANSI_S, kVK_ANSI_D, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_Semicolon,
        kVK_ANSI_Z, kVK_ANSI_X, kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_B, kVK_ANSI_N, kVK_ANSI_M, kVK_ANSI_Comma, kVK_ANSI_Period, kVK_ANSI_Slash,
        kVK_Space, kVK_Return
    ]

    let NGDIC: [(Set<Int>, Set<Int>, [[String: String]])]

    let NGSHIFT: [Set<Int>] = [
        [kVK_ANSI_D, kVK_ANSI_F], [kVK_ANSI_C, kVK_ANSI_V], [kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_M, kVK_ANSI_Comma],
        [kVK_Space], [kVK_Return], [kVK_ANSI_F], [kVK_ANSI_V], [kVK_ANSI_J], [kVK_ANSI_M]
    ]

    var pressedKeys: Set<Int> = []
    var nginput: [[Int]] = []  // 未変換のキー [[:NG_M], [:NG_J, :NG_W]] (なぎ)のように、同時押しの組み合わせを2次元配列へ格納

    init?(filePath: String) {
        guard let commands = NaginataReader.readNaginataFile(path: filePath) else {
            print("Failed to read Naginata configuration file")
            return nil
        }
        
        // コマンドから変換辞書を構築
        var dictionary: [(Set<Int>, Set<Int>, [[String: String]])] = []
        
        for command in commands {
            let mae = Set(command.mae)
            let douji = Set(command.douji)
            let type = command.type
            
            dictionary.append((mae, douji, type))
        }
        
        self.NGDIC = dictionary
    }

    func reset() {
        pressedKeys.removeAll()
        nginput.removeAll()
    }

    func isNaginata(kc: Int) -> Bool {
        return NG_KEYCODE.contains(kc)
    }

    func ngPress(kc: Int) -> [[String: String]] {
        pressedKeys.insert(kc)

        // 後置シフトはしない
        if [kVK_Space, kVK_Return].contains(kc) {
            nginput.append([kc])
        // 前のキーとの同時押しの可能性があるなら前に足す
        // 同じキー連打を除外
        // V, H, EでVHがロールオーバーすると「こくて」=[[V,H], [E]]になる。「こりゃ」は[[V],[H,E]]。
        } else if let lastInput = nginput.last, lastInput.last != kc && numberOfCandidates(keys: lastInput + [kc]) > 0 {
            nginput[nginput.count - 1] = lastInput + [kc]
        // 前のキーと同時押しはない
        } else {
            nginput.append([kc])
            // pressedKeys.delete_if{|a| a == :NG_SFT}
        }

        // 連続シフトする
        // がある　がる x (JIの組み合わせがあるからJがC/Oされる) strictモードを作る
        // あいあう　あいう x
        // ぎょあう　ぎょう x
        // どか どが x 先にFがc/oされてJが残される
        for rs in NGSHIFT {
            let rskc = rs + nginput.last!
            // rskc.append(kc)
            // じょじょ よを先に押すと連続シフトしない x
            // Falseにすると、がる が　がある になる x
            if !rs.contains(kc) && !rs.isSubset(of: Set(nginput.last!)) && rs.isSubset(of: pressedKeys) && numberOfMatches(keys: rskc) > 0 {
                nginput[nginput.count - 1] = rskc
                break
            }
        }

        if nginput.count > 1 || numberOfCandidates(keys: nginput.first!) == 1 {
            return ngType(keys: nginput.removeFirst())
        }

        return []
    }

    func ngRelease(kc: Int) -> [[String: String]] {
        pressedKeys.remove(kc)

        // 全部キーを離したらバッファを全部吐き出す
        var r: [[String: String]] = []
        if pressedKeys.count == 0 {
            while nginput.count > 0 {
                r.append(contentsOf: ngType(keys: nginput.removeFirst()))
            }
        } else {
            nginput.append([])
            if nginput.count > 0 && numberOfCandidates(keys: nginput.first!) == 1 {
                r.append(contentsOf: ngType(keys: nginput.removeFirst()))
            }
        }

        return r
    }

    func ngType(keys: [Int]) -> [[String: String]] {
        guard !keys.isEmpty else { return [] }

        if keys.count == 1 && keys[0] == kVK_Return {
            return [["tap": "Return"]]
        }

        let skc = Set(keys.map { $0 == kVK_Return ? kVK_Space : $0 })
        for k in NGDIC {
            if skc == k.0.union(k.1) {
                return k.2
            }
        }
        // JIみたいにJIを含む同時押しはたくさんあるが、JIのみの同時押しがないとき
        // 最後の１キーを別に分けて変換する
        if keys.count  > 1 {
            var mutableKeys = keys
            let kl = mutableKeys.removeLast()
            return ngType(keys: mutableKeys) + ngType(keys: [kl])
        }
        return []
    }

    func numberOfMatches(keys: [Int]) -> Int {
        guard keys.count > 0 else { return 0 }

        var noc = 0

        NGDIC.forEach { k in
            switch keys.count {
                case 1:
                    // 1, 0
                    if k.0 == Set(keys) {
                        noc += 1
                    }
                    // 0, 1
                    if k.0.isEmpty && k.1 == Set(keys) {
                        noc += 1
                    }
                case 2:
                    // 2, 0
                    if k.0 == Set(keys) {
                        noc += 1
                    }
                    // 1, 1
                    if k.0 == Set(keys[0..<1]) && k.1 == Set(keys[1...]) {
                        noc += 1
                    }
                    // 0, 2
                    if k.0.isEmpty && k.1 == Set(keys) {
                        noc += 1
                    }
                default:
                    // 2, 1
                    if k.0 == Set(keys[0..<2]) && k.1 == Set(keys[2...]) {
                        noc += 1
                    }
                    // 1, 2
                    if k.0 == Set(keys[0..<1])  && k.1 == Set(keys[1...]) {
                        noc += 1
                    }
                    // 0, 3
                    if k.0.isEmpty && k.1 == Set(keys) {
                        noc += 1
                    }
            }
        }

        print("NG num of matches \(noc)")
        return noc
    }

    func numberOfCandidates(keys: [Int]) -> Int {
        guard keys.count > 0 else { return 0 }

        var noc = 0

        NGDIC.forEach { k in
            switch keys.count {
                case 1:
                    // 1, 0
                    if k.0.isSuperset(of: Set(keys)) {
                        noc += 1
                    }
                    // 0, 1
                    if k.0.isEmpty && k.1.isSuperset(of: Set(keys)) {
                        noc += 1
                    }
                case 2:
                    // 2, 0
                    if k.0 == Set(keys) {
                        noc += 1
                    }
                    // 1, 1
                    if k.0 == Set(keys[0..<1]) && k.1.isSuperset(of: Set(keys[1...])) {
                        noc += 1
                    }
                    // 0, 2
                    if k.0.isEmpty && k.1.isSuperset(of: Set(keys)) {
                        if k.1.count > 2 {
                            noc = 2
                        } else {
                            noc += 1
                        }
                    }
                default:
                    // 2, 1
                    if k.0 == Set(keys[0..<2]) && k.1.isSuperset(of: Set(keys[2...])) {
                        noc += 1
                    }
                    // 1, 2
                    if k.0 == Set(keys[0..<1])  && k.1.isSuperset(of: Set(keys[1...])) {
                        noc += 1
                    }
                    // 0, 3
                    if k.0.isEmpty && k.1.isSuperset(of: Set(keys)) {
                        noc += 1
                    }
            }
        }

        print("NG num of candidates \(noc)")
        return noc
    }
}
