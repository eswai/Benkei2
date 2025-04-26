import Testing
@testable import Benkei2
import Carbon

struct Benkei2Tests {
    @Test func testBasicKeyPress() async throws {
        let ng = Naginata()
        
        // Test basic "あ" input (J key)
        #expect(ng.ngPress(kc: kVK_ANSI_J) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_J) == [kVK_ANSI_A])
        
        // Test basic "い" input (K key)
        #expect(ng.ngPress(kc: kVK_ANSI_K) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_K) == [kVK_ANSI_I])
    }
    
    @Test func testDakutenCombination() async throws {
        let ng = Naginata()
        
        // Test "が" input (J+F keys)
        #expect(ng.ngPress(kc: kVK_ANSI_J) == [])
        #expect(ng.ngPress(kc: kVK_ANSI_F) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_F) == [kVK_ANSI_G, kVK_ANSI_A])
        #expect(ng.ngRelease(kc: kVK_ANSI_J) == [])
    }
    
    @Test func testSpaceShiftCombination() async throws {
        let ng = Naginata()
        
        // Test "お" input (Space+N keys)
        #expect(ng.ngPress(kc: kVK_Space) == [])
        #expect(ng.ngPress(kc: kVK_ANSI_N) == [kVK_ANSI_O])
        #expect(ng.ngRelease(kc: kVK_ANSI_N) == [])
        #expect(ng.ngRelease(kc: kVK_Space) == [])
    }

    @Test func testSmallCharacters() async throws {
        let ng = Naginata()
        
        // Test "ゃ" input (Q+H keys)
        #expect(ng.ngPress(kc: kVK_ANSI_Q) == [])
        #expect(ng.ngPress(kc: kVK_ANSI_H) == [kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_A])
        #expect(ng.ngRelease(kc: kVK_ANSI_H) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_Q) == [])
    }
    
    @Test func testSpecialControls() async throws {
        let ng = Naginata()
        
        // Test delete key (U key)
        #expect(ng.ngPress(kc: kVK_ANSI_U) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_U) == [kVK_Delete])
        
        // Test arrow keys
        #expect(ng.ngPress(kc: kVK_ANSI_T) == [kVK_LeftArrow])
        #expect(ng.ngRelease(kc: kVK_ANSI_T) == [])
        
        #expect(ng.ngPress(kc: kVK_ANSI_Y) == [kVK_RightArrow])
        #expect(ng.ngRelease(kc: kVK_ANSI_Y) == [])
    }
    
    @Test func testComplexCombinations() async throws {
        let ng = Naginata()
        
        // Test "じぇ" input (J+R+O keys)
        #expect(ng.ngPress(kc: kVK_ANSI_J) == [])
        #expect(ng.ngPress(kc: kVK_ANSI_R) == [])
        #expect(ng.ngPress(kc: kVK_ANSI_O) == [kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_E])
        #expect(ng.ngRelease(kc: kVK_ANSI_O) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_R) == [])
        #expect(ng.ngRelease(kc: kVK_ANSI_J) == [])
    }
}

