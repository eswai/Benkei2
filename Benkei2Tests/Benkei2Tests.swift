import Testing
@testable import Benkei2
import Carbon
import Foundation

struct Benkei2Tests {

    // MARK: - ヘルパー

    enum KeyEvent {
        case press(Int)
        case release(Int)
    }

    /// アプリバンドル同梱の Naginata.yaml を読み込む（本番と同じ設定でテストする）
    static func loadNaginata() throws -> Naginata {
        let bundle = Bundle(for: Naginata.self)
        let path = try #require(bundle.path(forResource: "Naginata", ofType: "yaml"),
                                "Naginata.yaml がアプリバンドルに同梱されていない")
        return try #require(Naginata(filePath: path), "Naginata.yaml を読み込めない")
    }

    /// キーイベント列を流し込み、出力されたコマンドを連結して返す
    func emit(_ ng: Naginata, _ events: [KeyEvent]) -> [[String: String]] {
        var output: [[String: String]] = []
        for event in events {
            switch event {
            case .press(let kc):
                output += ng.ngPress(kc: kc)
            case .release(let kc):
                output += ng.ngRelease(kc: kc)
            }
        }
        return output
    }

    /// 単打（押して離す）
    func tap(_ ng: Naginata, _ kc: Int) -> [[String: String]] {
        return emit(ng, [.press(kc), .release(kc)])
    }

    /// 同時押し（順に押して、逆順に離す）
    func chord(_ ng: Naginata, _ kcs: [Int]) -> [[String: String]] {
        return emit(ng, kcs.map { KeyEvent.press($0) } + kcs.reversed().map { KeyEvent.release($0) })
    }

    // MARK: - 設定ファイル

    @Test func testBundledConfigLoads() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // YAMLの構文エラー（重複キーなど）があるとここで落ちる
        #expect(!ng.NGDIC.isEmpty)
    }

    @Test func testMissingConfigReturnsNil() async throws {
        #expect(Naginata(filePath: "/nonexistent/Naginata.yaml") == nil)
    }

    // MARK: - 単打

    @Test func testBasicKeyPress() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // あ (J)
        #expect(tap(ng, kVK_ANSI_J) == [["tap": "A"]])

        // い (K)
        #expect(tap(ng, kVK_ANSI_K) == [["tap": "I"]])

        // っ (G) 3打鍵に展開される
        #expect(tap(ng, kVK_ANSI_G) == [["tap": "X"], ["tap": "T"], ["tap": "U"]])
    }

    // MARK: - シフト面

    @Test func testSpaceShiftCombination() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // の (Space + J)
        #expect(chord(ng, [kVK_Space, kVK_ANSI_J]) == [["tap": "N"], ["tap": "O"]])
    }

    // MARK: - 同時押し

    @Test func testDakutenCombination() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // が (J + F)
        #expect(chord(ng, [kVK_ANSI_J, kVK_ANSI_F]) == [["tap": "G"], ["tap": "A"]])
    }

    @Test func testEditModeCombination() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // 編集モード ・ (J + K 前置 + T)
        #expect(chord(ng, [kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_T]) == [["tap": "Slash"]])
    }

    // MARK: - IME切り替え

    @Test func testImeToggleKeys() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // IMEオン (H + J)
        #expect(chord(ng, [kVK_ANSI_H, kVK_ANSI_J]) == [["tap": "JIS_Kana"]])

        // IMEオフ (F + G)
        #expect(chord(ng, [kVK_ANSI_F, kVK_ANSI_G]) == [["tap": "JIS_Eisu"]])
    }

    // MARK: - 編集キー

    @Test func testSpecialControls() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // BS (U)
        #expect(tap(ng, kVK_ANSI_U) == [["tap": "Delete"]])

        // ← (T)
        #expect(tap(ng, kVK_ANSI_T) == [["tap": "LeftArrow"]])

        // → (Y)
        #expect(tap(ng, kVK_ANSI_Y) == [["tap": "RightArrow"]])
    }

    // MARK: - 連続入力

    @Test func testSequentialInput() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        // あい (J → K) 打鍵が重ならない場合はそれぞれ確定する
        #expect(tap(ng, kVK_ANSI_J) == [["tap": "A"]])
        #expect(tap(ng, kVK_ANSI_K) == [["tap": "I"]])
        #expect(ng.nginput.isEmpty)
    }

    @Test func testResetClearsBuffer() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        _ = ng.ngPress(kc: kVK_Space)
        ng.reset()

        #expect(ng.pressedKeys.isEmpty)
        #expect(ng.nginput.isEmpty)
    }

    // MARK: - 対象キーの判定

    @Test func testIsNaginata() async throws {
        let ng = try Benkei2Tests.loadNaginata()

        #expect(ng.isNaginata(kc: kVK_ANSI_J))
        #expect(ng.isNaginata(kc: kVK_Space))
        #expect(ng.isNaginata(kc: kVK_Return))
        #expect(!ng.isNaginata(kc: kVK_Tab))
    }
}
