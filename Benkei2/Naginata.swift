import Foundation
import Carbon

class Naginata {

    let NG_KEYCODE: [Int] = [
        kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_E, kVK_ANSI_R, kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_U, kVK_ANSI_I, kVK_ANSI_O, kVK_ANSI_P,
        kVK_ANSI_A, kVK_ANSI_S, kVK_ANSI_D, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_Semicolon,
        kVK_ANSI_Z, kVK_ANSI_X, kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_B, kVK_ANSI_N, kVK_ANSI_M, kVK_ANSI_Comma, kVK_ANSI_Period, kVK_ANSI_Slash,
        kVK_Space, kVK_Return
    ]

    let NGDIC: [([Int], [Int], [[String: String]])]

    let NGSHIFT1: [[Int]] = [
        [kVK_Space], [kVK_Return], [kVK_ANSI_D, kVK_ANSI_F], [kVK_ANSI_C, kVK_ANSI_V], [kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_M, kVK_ANSI_Comma]
    ]

    let NGSHIFT2: [[Int]] = [
        [kVK_ANSI_D, kVK_ANSI_F], [kVK_ANSI_C, kVK_ANSI_V], [kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_M, kVK_ANSI_Comma],
        [kVK_Space], [kVK_Return], [kVK_ANSI_F], [kVK_ANSI_V], [kVK_ANSI_J], [kVK_ANSI_M]
    ]

    let HENSHU: [[Int]] = [
        [kVK_ANSI_D, kVK_ANSI_F], [kVK_ANSI_C, kVK_ANSI_V], [kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_M, kVK_ANSI_Comma]
    ]

    var pressedKeys: Set<Int> = []
    var nginput: [[Int]] = []  // 未変換のキー [[:NG_M], [:NG_J, :NG_W]] (なぎ)のように、同時押しの組み合わせを2次元配列へ格納

    init?(filePath: String) {
        guard let commands = NaginataReader.readNaginataFile(path: filePath) else {
            print("Failed to read Naginata configuration file")
            return nil
        }
        
        // コマンドから変換辞書を構築
        var dictionary: [([Int], [Int], [[String: String]])] = []
        
        for command in commands {
            let mae = command.mae
            let douji = command.douji
            let type = command.type
            
            dictionary.append((mae, douji, type))
        }
        
        self.NGDIC = dictionary
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
        for rs in NGSHIFT2 {
            let rskc = rs + nginput.last!
            // rskc.append(kc)
            // じょじょ よを先に押すと連続シフトしない x
            // Falseにすると、がる が　がある になる x
            if !rs.contains(kc) && Set(rs).isSubset(of: pressedKeys) && numberOfMatches(keys: rskc) > 0 {
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
            if nginput.count > 1 || numberOfCandidates(keys: nginput.first!) == 1 {
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
            if skc == Set(k.0 + k.1) {
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

        // skc = set(map(lambda x: :NG_SFT if x == :NG_SFT2 else x, keys))
        if [kVK_Space, kVK_Return].contains(keys[0]) && keys.count == 1 {
            noc = 1
        } else if [kVK_Space, kVK_Return].contains(keys[0]) && keys.count > 1 {
            let skc = Set(keys[1...])
            for k in NGDIC {
                if k.0.contains(kVK_Space) && Set(k.1) == skc {
                    noc += 1
                    if noc > 1 {
                        break
                    }
                }
            }
        } else {
            var f = true
            for rs in HENSHU {
                if keys.count == 3 && Set(keys[0..<2]) == Set(rs) {
                    for k in NGDIC {
                        if Set(rs) == Set(k.0) && Set([keys[2]]) == Set(k.1) {
                            noc = 1
                            f = false
                            break
                        }
                    }
                    if !f { break }
                }
            }
            if f {
                let skc = Set(keys)
                for k in NGDIC {
                    if k.0.isEmpty && Set(k.1) == skc {
                        noc += 1
                        if noc > 1 {
                            break
                        }
                    }
                }
            }
        }

        print("NG num of matches \(noc)")
        return noc
    }

    func numberOfCandidates(keys: [Int]) -> Int {
        guard keys.count > 0 else { return 0 }

        var noc = 0

        if NGSHIFT1.contains(keys) {
            noc = 2
        } else if [kVK_Space, kVK_Return].contains(keys[0]) && keys.count > 1 {
            let skc = Set(keys[1...])
            for k in NGDIC {
                // if k.0.contains(kVK_Space) && Set(k.1).isSubset(of: skc) {  // <=だけ違う
                if k.0.contains(kVK_Space) && skc.isSubset(of: Set(k.1)) {  // <=だけ違う
                    noc += 1
                    if noc > 1 {
                        break
                    }
                }
            }
        } else {
            var f = true
            for rs in HENSHU {
                if keys.count == 3 && Set(keys[0..<2]) == Set(rs) {
                    for k in NGDIC {
                        if Set(rs) == Set(k.0) && Set([keys[2]]) == Set(k.1) {
                            noc = 1
                            f = false
                            break
                        }
                    }
                    if !f { break }
                }
            }
            if f {
                let skc = Set(keys)
                for k in NGDIC {
                    if k.0.isEmpty && skc.isSubset(of: Set(k.1)) {  // <=だけ違う
                        // シェ、チェは２文字タイプしたらnoc = 1になるが、まだ２キーしか押してないので、早期確定してはいけない。
                        if keys.count < k.1.count {
                            noc = 2
                            break
                        } else {
                            noc += 1
                            if noc > 1 {
                                break
                            }
                        }
                    }
                }
            }
        }

        print("NG num of candidates \(noc)")
        return noc
    }
}
