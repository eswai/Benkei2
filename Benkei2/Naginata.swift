import Foundation
import Carbon

class Naginata {

    let NG_KEYCODE: [Int] = [
        kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_E, kVK_ANSI_R, kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_U, kVK_ANSI_I, kVK_ANSI_O, kVK_ANSI_P,
        kVK_ANSI_A, kVK_ANSI_S, kVK_ANSI_D, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L, kVK_ANSI_Semicolon,
        kVK_ANSI_Z, kVK_ANSI_X, kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_B, kVK_ANSI_N, kVK_ANSI_M, kVK_ANSI_Comma, kVK_ANSI_Period, kVK_ANSI_Slash,
        kVK_Space, kVK_Return
    ]

    let NGDIC: [([Int], [Int], [Int])] = [
        //  前置シフト      同時押し                        かな
        // ([kVK_Space], [kVK_ANSI_T], [kVK_ANSI_LSFT:KC_LEFT]"]),
        // ([kVK_Space], [kVK_ANSI_Y], [kVK_ANSI_LSFT:KC_RIGHT]"]),
        ([], [kVK_ANSI_U], [kVK_Delete]),
        ([], [kVK_Space], [kVK_Space]),
        ([], [kVK_ANSI_M, kVK_ANSI_V], [kVK_Return]),
        ([], [kVK_ANSI_T], [kVK_LeftArrow]),
        ([], [kVK_ANSI_Y], [kVK_RightArrow]),
        ([], [kVK_ANSI_Semicolon], [kVK_ANSI_Minus]), // ー
        ([kVK_Space], [kVK_ANSI_V], [kVK_ANSI_Comma, kVK_Return]), // 、[Enter]
        ([kVK_Space], [kVK_ANSI_M], [kVK_ANSI_Period, kVK_Return]), // 。[Enter]Set

        ([], [kVK_ANSI_J], [kVK_ANSI_A]), // あ
        ([], [kVK_ANSI_K], [kVK_ANSI_I]), // い
        ([], [kVK_ANSI_L], [kVK_ANSI_U]), // う
        ([kVK_Space], [kVK_ANSI_O], [kVK_ANSI_E]), // え
        ([kVK_Space], [kVK_ANSI_N], [kVK_ANSI_O]), // お
        ([], [kVK_ANSI_F], [kVK_ANSI_K, kVK_ANSI_A]), // か
        ([], [kVK_ANSI_W], [kVK_ANSI_K, kVK_ANSI_I]), // き
        ([], [kVK_ANSI_H], [kVK_ANSI_K, kVK_ANSI_U]), // く
        ([], [kVK_ANSI_S], [kVK_ANSI_K, kVK_ANSI_E]), // け
        ([], [kVK_ANSI_V], [kVK_ANSI_K, kVK_ANSI_O]), // こ
        ([kVK_Space], [kVK_ANSI_U], [kVK_ANSI_S, kVK_ANSI_A]), // さ
        ([], [kVK_ANSI_R], [kVK_ANSI_S, kVK_ANSI_I]), // し
        ([], [kVK_ANSI_O], [kVK_ANSI_S, kVK_ANSI_U]), // す
        ([kVK_Space], [kVK_ANSI_A], [kVK_ANSI_S, kVK_ANSI_E]), // せ
        ([], [kVK_ANSI_B], [kVK_ANSI_S, kVK_ANSI_O]), // そ
        ([], [kVK_ANSI_N], [kVK_ANSI_T, kVK_ANSI_A]), // た
        ([kVK_Space], [kVK_ANSI_G], [kVK_ANSI_T, kVK_ANSI_I]), // ち
        ([kVK_Space], [kVK_ANSI_L], [kVK_ANSI_T, kVK_ANSI_U]), // つ
        ([], [kVK_ANSI_E], [kVK_ANSI_T, kVK_ANSI_E]), // て
        ([], [kVK_ANSI_D], [kVK_ANSI_T, kVK_ANSI_O]), // と
        ([], [kVK_ANSI_M], [kVK_ANSI_N, kVK_ANSI_A]), // な
        ([kVK_Space], [kVK_ANSI_D], [kVK_ANSI_N, kVK_ANSI_I]), // に
        ([kVK_Space], [kVK_ANSI_W], [kVK_ANSI_N, kVK_ANSI_U]), // ぬ
        ([kVK_Space], [kVK_ANSI_R], [kVK_ANSI_N, kVK_ANSI_E]), // ね
        ([kVK_Space], [kVK_ANSI_J], [kVK_ANSI_N, kVK_ANSI_O]), // の
        ([], [kVK_ANSI_C], [kVK_ANSI_H, kVK_ANSI_A]), // は
        ([], [kVK_ANSI_X], [kVK_ANSI_H, kVK_ANSI_I]), // ひ
        ([kVK_Space], [kVK_ANSI_X], [kVK_ANSI_H, kVK_ANSI_I]), // ひ
        ([kVK_Space], [kVK_ANSI_Semicolon], [kVK_ANSI_H, kVK_ANSI_U]), // ふ
        ([], [kVK_ANSI_P], [kVK_ANSI_H, kVK_ANSI_E]), // へ
        ([], [kVK_ANSI_Z], [kVK_ANSI_H, kVK_ANSI_O]), // ほ
        ([kVK_Space], [kVK_ANSI_Z], [kVK_ANSI_H, kVK_ANSI_O]), // ほ
        ([kVK_Space], [kVK_ANSI_F], [kVK_ANSI_M, kVK_ANSI_A]), // ま
        ([kVK_Space], [kVK_ANSI_B], [kVK_ANSI_M, kVK_ANSI_I]), // み
        ([kVK_Space], [kVK_ANSI_Comma], [kVK_ANSI_M, kVK_ANSI_U]), // む
        ([kVK_Space], [kVK_ANSI_S], [kVK_ANSI_M, kVK_ANSI_E]), // め
        ([kVK_Space], [kVK_ANSI_K], [kVK_ANSI_M, kVK_ANSI_O]), // も
        ([kVK_Space], [kVK_ANSI_H], [kVK_ANSI_Y, kVK_ANSI_A]), // や
        ([kVK_Space], [kVK_ANSI_P], [kVK_ANSI_Y, kVK_ANSI_U]), // ゆ
        ([kVK_Space], [kVK_ANSI_I], [kVK_ANSI_Y, kVK_ANSI_O]), // よ
        ([], [kVK_ANSI_Period], [kVK_ANSI_R, kVK_ANSI_A]), // ら
        ([kVK_Space], [kVK_ANSI_E], [kVK_ANSI_R, kVK_ANSI_I]), // り
        ([], [kVK_ANSI_I], [kVK_ANSI_R, kVK_ANSI_U]), // る
        ([], [kVK_ANSI_Slash], [kVK_ANSI_R, kVK_ANSI_E]), // れ
        ([kVK_Space], [kVK_ANSI_Slash], [kVK_ANSI_R, kVK_ANSI_E]), // れ
        ([], [kVK_ANSI_A], [kVK_ANSI_R, kVK_ANSI_O]), // ろ
        ([kVK_Space], [kVK_ANSI_Period], [kVK_ANSI_W, kVK_ANSI_A]), // わ
        ([kVK_Space], [kVK_ANSI_C], [kVK_ANSI_W, kVK_ANSI_O]), // を
        ([], [kVK_ANSI_Comma], [kVK_ANSI_N, kVK_ANSI_N]), // ん
        ([], [kVK_ANSI_Q], [kVK_ANSI_V, kVK_ANSI_U]), // ゔ
        ([kVK_Space], [kVK_ANSI_Q], [kVK_ANSI_V, kVK_ANSI_U]), // ゔ
        ([], [kVK_ANSI_J, kVK_ANSI_F], [kVK_ANSI_G, kVK_ANSI_A]), // が
        ([], [kVK_ANSI_J, kVK_ANSI_W], [kVK_ANSI_G, kVK_ANSI_I]), // ぎ
        ([], [kVK_ANSI_F, kVK_ANSI_H], [kVK_ANSI_G, kVK_ANSI_U]), // ぐ
        ([], [kVK_ANSI_J, kVK_ANSI_S], [kVK_ANSI_G, kVK_ANSI_E]), // げ
        ([], [kVK_ANSI_J, kVK_ANSI_V], [kVK_ANSI_G, kVK_ANSI_O]), // ご
        ([], [kVK_ANSI_F, kVK_ANSI_U], [kVK_ANSI_Z, kVK_ANSI_A]), // ざ
        ([], [kVK_ANSI_J, kVK_ANSI_R], [kVK_ANSI_Z, kVK_ANSI_I]), // じ
        ([], [kVK_ANSI_F, kVK_ANSI_O], [kVK_ANSI_Z, kVK_ANSI_U]), // ず
        ([], [kVK_ANSI_J, kVK_ANSI_A], [kVK_ANSI_Z, kVK_ANSI_E]), // ぜ
        ([], [kVK_ANSI_J, kVK_ANSI_B], [kVK_ANSI_Z, kVK_ANSI_O]), // ぞ
        ([], [kVK_ANSI_F, kVK_ANSI_N], [kVK_ANSI_D, kVK_ANSI_A]), // だ
        ([], [kVK_ANSI_J, kVK_ANSI_G], [kVK_ANSI_D, kVK_ANSI_I]), // ぢ
        ([], [kVK_ANSI_F, kVK_ANSI_L], [kVK_ANSI_D, kVK_ANSI_U]), // づ
        ([], [kVK_ANSI_J, kVK_ANSI_E], [kVK_ANSI_D, kVK_ANSI_E]), // で
        ([], [kVK_ANSI_J, kVK_ANSI_D], [kVK_ANSI_D, kVK_ANSI_O]), // ど
        ([], [kVK_ANSI_C], [kVK_ANSI_B, kVK_ANSI_A]), // ば
        ([], [kVK_ANSI_X], [kVK_ANSI_B, kVK_ANSI_I]), // び
        ([], [kVK_ANSI_F, kVK_ANSI_Semicolon], [kVK_ANSI_B, kVK_ANSI_U]), // ぶ
        ([], [kVK_ANSI_F, kVK_ANSI_P], [kVK_ANSI_B, kVK_ANSI_E]), // べ
        ([], [kVK_ANSI_J, kVK_ANSI_Z], [kVK_ANSI_B, kVK_ANSI_O]), // ぼ
        ([], [kVK_ANSI_F, kVK_ANSI_L], [kVK_ANSI_V, kVK_ANSI_U]), // ゔ
        ([], [kVK_ANSI_M, kVK_ANSI_C], [kVK_ANSI_P, kVK_ANSI_A]), // ぱ
        ([], [kVK_ANSI_M, kVK_ANSI_X], [kVK_ANSI_P, kVK_ANSI_I]), // ぴ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon], [kVK_ANSI_P, kVK_ANSI_U]), // ぷ
        ([], [kVK_ANSI_V, kVK_ANSI_P], [kVK_ANSI_P, kVK_ANSI_E]), // ぺ
        ([], [kVK_ANSI_M, kVK_ANSI_Z], [kVK_ANSI_P, kVK_ANSI_O]), // ぽ
        ([], [kVK_ANSI_Q, kVK_ANSI_H], [kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_A]), // ゃ
        ([], [kVK_ANSI_Q, kVK_ANSI_P], [kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_U]), // ゅ
        ([], [kVK_ANSI_Q, kVK_ANSI_I], [kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_O]), // ょ
        ([], [kVK_ANSI_Q, kVK_ANSI_J], [kVK_ANSI_X, kVK_ANSI_A]), // ぁ
        ([], [kVK_ANSI_Q, kVK_ANSI_K], [kVK_ANSI_X, kVK_ANSI_I]), // ぃ
        ([], [kVK_ANSI_Q, kVK_ANSI_L], [kVK_ANSI_X, kVK_ANSI_U]), // ぅ
        ([], [kVK_ANSI_Q, kVK_ANSI_O], [kVK_ANSI_X, kVK_ANSI_E]), // ぇ
        ([], [kVK_ANSI_Q, kVK_ANSI_N], [kVK_ANSI_X, kVK_ANSI_O]), // ぉ
        ([], [kVK_ANSI_Q, kVK_ANSI_Period], [kVK_ANSI_X, kVK_ANSI_W, kVK_ANSI_A]), // ゎ
        ([], [kVK_ANSI_G], [kVK_ANSI_X, kVK_ANSI_T, kVK_ANSI_U]), // っ
        ([], [kVK_ANSI_Q, kVK_ANSI_S], [kVK_ANSI_X, kVK_ANSI_K, kVK_ANSI_E]), // ヶ
        ([], [kVK_ANSI_Q, kVK_ANSI_F], [kVK_ANSI_X, kVK_ANSI_K, kVK_ANSI_A]), // ヵ
        ([], [kVK_ANSI_R, kVK_ANSI_H], [kVK_ANSI_S, kVK_ANSI_Y, kVK_ANSI_A]), // しゃ
        ([], [kVK_ANSI_R, kVK_ANSI_P], [kVK_ANSI_S, kVK_ANSI_Y, kVK_ANSI_U]), // しゅ
        ([], [kVK_ANSI_R, kVK_ANSI_I], [kVK_ANSI_S, kVK_ANSI_Y, kVK_ANSI_O]), // しょ
        ([], [kVK_ANSI_J, kVK_ANSI_R, kVK_ANSI_H], [kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_A]), // じゃ
        ([], [kVK_ANSI_J, kVK_ANSI_R, kVK_ANSI_P], [kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_U]), // じゅ
        ([], [kVK_ANSI_J, kVK_ANSI_R, kVK_ANSI_I], [kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_O]), // じょ
        ([], [kVK_ANSI_W, kVK_ANSI_H], [kVK_ANSI_K, kVK_ANSI_Y, kVK_ANSI_A]), // きゃ
        ([], [kVK_ANSI_W, kVK_ANSI_P], [kVK_ANSI_K, kVK_ANSI_Y, kVK_ANSI_U]), // きゅ
        ([], [kVK_ANSI_W, kVK_ANSI_I], [kVK_ANSI_K, kVK_ANSI_Y, kVK_ANSI_O]), // きょ
        ([], [kVK_ANSI_J, kVK_ANSI_W, kVK_ANSI_H], [kVK_ANSI_G, kVK_ANSI_Y, kVK_ANSI_A]), // ぎゃ
        ([], [kVK_ANSI_J, kVK_ANSI_W, kVK_ANSI_P], [kVK_ANSI_G, kVK_ANSI_Y, kVK_ANSI_U]), // ぎゅ
        ([], [kVK_ANSI_J, kVK_ANSI_W, kVK_ANSI_I], [kVK_ANSI_G, kVK_ANSI_Y, kVK_ANSI_O]), // ぎょ
        ([], [kVK_ANSI_G, kVK_ANSI_H], [kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_A]), // ちゃ
        ([], [kVK_ANSI_G, kVK_ANSI_P], [kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_U]), // ちゅ
        ([], [kVK_ANSI_G, kVK_ANSI_I], [kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_O]), // ちょ
        ([], [kVK_ANSI_J, kVK_ANSI_G, kVK_ANSI_H], [kVK_ANSI_D, kVK_ANSI_Y, kVK_ANSI_A]), // ぢゃ
        ([], [kVK_ANSI_J, kVK_ANSI_G, kVK_ANSI_P], [kVK_ANSI_D, kVK_ANSI_Y, kVK_ANSI_U]), // ぢゅ
        ([], [kVK_ANSI_J, kVK_ANSI_G, kVK_ANSI_I], [kVK_ANSI_D, kVK_ANSI_Y, kVK_ANSI_O]), // ぢょ
        ([], [kVK_ANSI_D, kVK_ANSI_H], [kVK_ANSI_N, kVK_ANSI_Y, kVK_ANSI_A]), // にゃ
        ([], [kVK_ANSI_D, kVK_ANSI_P], [kVK_ANSI_N, kVK_ANSI_Y, kVK_ANSI_U]), // にゅ
        ([], [kVK_ANSI_D, kVK_ANSI_I], [kVK_ANSI_N, kVK_ANSI_Y, kVK_ANSI_O]), // にょ
        ([], [kVK_ANSI_X, kVK_ANSI_H], [kVK_ANSI_H, kVK_ANSI_Y, kVK_ANSI_A]), // ひゃ
        ([], [kVK_ANSI_X, kVK_ANSI_P], [kVK_ANSI_H, kVK_ANSI_Y, kVK_ANSI_U]), // ひゅ
        ([], [kVK_ANSI_X, kVK_ANSI_I], [kVK_ANSI_H, kVK_ANSI_Y, kVK_ANSI_O]), // ひょ
        ([], [kVK_ANSI_J, kVK_ANSI_X, kVK_ANSI_H], [kVK_ANSI_B, kVK_ANSI_Y, kVK_ANSI_A]), // びゃ
        ([], [kVK_ANSI_J, kVK_ANSI_X, kVK_ANSI_P], [kVK_ANSI_B, kVK_ANSI_Y, kVK_ANSI_U]), // びゅ
        ([], [kVK_ANSI_J, kVK_ANSI_X, kVK_ANSI_I], [kVK_ANSI_B, kVK_ANSI_Y, kVK_ANSI_O]), // びょ
        ([], [kVK_ANSI_M, kVK_ANSI_X, kVK_ANSI_H], [kVK_ANSI_P, kVK_ANSI_Y, kVK_ANSI_A]), // ぴゃ
        ([], [kVK_ANSI_M, kVK_ANSI_X, kVK_ANSI_P], [kVK_ANSI_P, kVK_ANSI_Y, kVK_ANSI_U]), // ぴゅ
        ([], [kVK_ANSI_M, kVK_ANSI_X, kVK_ANSI_I], [kVK_ANSI_P, kVK_ANSI_Y, kVK_ANSI_O]), // ぴょ
        ([], [kVK_ANSI_B, kVK_ANSI_H], [kVK_ANSI_M, kVK_ANSI_Y, kVK_ANSI_A]), // みゃ
        ([], [kVK_ANSI_B, kVK_ANSI_P], [kVK_ANSI_M, kVK_ANSI_Y, kVK_ANSI_U]), // みゅ
        ([], [kVK_ANSI_B, kVK_ANSI_I], [kVK_ANSI_M, kVK_ANSI_Y, kVK_ANSI_O]), // みょ
        ([], [kVK_ANSI_E, kVK_ANSI_H], [kVK_ANSI_R, kVK_ANSI_Y, kVK_ANSI_A]), // りゃ
        ([], [kVK_ANSI_E, kVK_ANSI_P], [kVK_ANSI_R, kVK_ANSI_Y, kVK_ANSI_U]), // りゅ
        ([], [kVK_ANSI_E, kVK_ANSI_I], [kVK_ANSI_R, kVK_ANSI_Y, kVK_ANSI_O]), // りょ
        ([], [kVK_ANSI_M, kVK_ANSI_E, kVK_ANSI_K], [kVK_ANSI_T, kVK_ANSI_H, kVK_ANSI_I]), // てぃ
        ([], [kVK_ANSI_M, kVK_ANSI_E, kVK_ANSI_P], [kVK_ANSI_T, kVK_ANSI_E, kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_U]), // てゅ
        ([], [kVK_ANSI_J, kVK_ANSI_E, kVK_ANSI_K], [kVK_ANSI_D, kVK_ANSI_H, kVK_ANSI_I]), // でぃ
        ([], [kVK_ANSI_J, kVK_ANSI_E, kVK_ANSI_P], [kVK_ANSI_D, kVK_ANSI_H, kVK_ANSI_U]), // でゅ
        ([], [kVK_ANSI_M, kVK_ANSI_D, kVK_ANSI_L], [kVK_ANSI_T, kVK_ANSI_O, kVK_ANSI_X, kVK_ANSI_U]), // とぅ
        ([], [kVK_ANSI_J, kVK_ANSI_D, kVK_ANSI_L], [kVK_ANSI_D, kVK_ANSI_O, kVK_ANSI_X, kVK_ANSI_U]), // どぅ
        ([], [kVK_ANSI_M, kVK_ANSI_R, kVK_ANSI_O], [kVK_ANSI_S, kVK_ANSI_Y, kVK_ANSI_E]), // しぇ
        ([], [kVK_ANSI_M, kVK_ANSI_G, kVK_ANSI_O], [kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_E]), // ちぇ
        ([], [kVK_ANSI_J, kVK_ANSI_R, kVK_ANSI_O], [kVK_ANSI_Z, kVK_ANSI_Y, kVK_ANSI_E]), // じぇ
        ([], [kVK_ANSI_J, kVK_ANSI_G, kVK_ANSI_O], [kVK_ANSI_D, kVK_ANSI_Y, kVK_ANSI_E]), // ぢぇ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon, kVK_ANSI_J], [kVK_ANSI_F, kVK_ANSI_A]), // ふぁ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon, kVK_ANSI_K], [kVK_ANSI_F, kVK_ANSI_I]), // ふぃ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon, kVK_ANSI_O], [kVK_ANSI_F, kVK_ANSI_E]), // ふぇ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon, kVK_ANSI_N], [kVK_ANSI_F, kVK_ANSI_O]), // ふぉ
        ([], [kVK_ANSI_V, kVK_ANSI_Semicolon, kVK_ANSI_P], [kVK_ANSI_F, kVK_ANSI_Y, kVK_ANSI_U]), // ふゅ
        ([], [kVK_ANSI_V, kVK_ANSI_K, kVK_ANSI_O], [kVK_ANSI_I, kVK_ANSI_X, kVK_ANSI_E]), // いぇ
        ([], [kVK_ANSI_V, kVK_ANSI_L, kVK_ANSI_K], [kVK_ANSI_W, kVK_ANSI_I]), // うぃ
        ([], [kVK_ANSI_V, kVK_ANSI_L, kVK_ANSI_O], [kVK_ANSI_W, kVK_ANSI_E]), // うぇ
        ([], [kVK_ANSI_V, kVK_ANSI_L, kVK_ANSI_N], [kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_O]), // うぉ
        ([], [kVK_ANSI_M, kVK_ANSI_Q, kVK_ANSI_J], [kVK_ANSI_V, kVK_ANSI_A]), // ゔぁ
        ([], [kVK_ANSI_M, kVK_ANSI_Q, kVK_ANSI_K], [kVK_ANSI_V, kVK_ANSI_I]), // ゔぃ
        ([], [kVK_ANSI_M, kVK_ANSI_Q, kVK_ANSI_O], [kVK_ANSI_V, kVK_ANSI_E]), // ゔぇ
        ([], [kVK_ANSI_M, kVK_ANSI_Q, kVK_ANSI_N], [kVK_ANSI_V, kVK_ANSI_O]), // ゔぉ
        ([], [kVK_ANSI_M, kVK_ANSI_Q, kVK_ANSI_P], [kVK_ANSI_V, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_Y, kVK_ANSI_U]), // ゔゅ
        ([], [kVK_ANSI_V, kVK_ANSI_H, kVK_ANSI_J], [kVK_ANSI_K, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_A]), // くぁ
        ([], [kVK_ANSI_V, kVK_ANSI_H, kVK_ANSI_K], [kVK_ANSI_K, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_I]), // くぃ
        ([], [kVK_ANSI_V, kVK_ANSI_H, kVK_ANSI_O], [kVK_ANSI_K, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_E]), // くぇ
        ([], [kVK_ANSI_V, kVK_ANSI_H, kVK_ANSI_N], [kVK_ANSI_K, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_O]), // くぉ
        ([], [kVK_ANSI_V, kVK_ANSI_H, kVK_ANSI_Period], [kVK_ANSI_K, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_W, kVK_ANSI_A]), // くゎ
        ([], [kVK_ANSI_F, kVK_ANSI_H, kVK_ANSI_J], [kVK_ANSI_G, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_A]), // ぐぁ
        ([], [kVK_ANSI_F, kVK_ANSI_H, kVK_ANSI_K], [kVK_ANSI_G, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_I]), // ぐぃ
        ([], [kVK_ANSI_F, kVK_ANSI_H, kVK_ANSI_O], [kVK_ANSI_G, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_E]), // ぐぇ
        ([], [kVK_ANSI_F, kVK_ANSI_H, kVK_ANSI_N], [kVK_ANSI_G, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_O]), // ぐぉ
        ([], [kVK_ANSI_F, kVK_ANSI_H, kVK_ANSI_Period], [kVK_ANSI_G, kVK_ANSI_U, kVK_ANSI_X, kVK_ANSI_W, kVK_ANSI_A]), // ぐゎ
        ([], [kVK_ANSI_V, kVK_ANSI_L, kVK_ANSI_J], [kVK_ANSI_T, kVK_ANSI_S, kVK_ANSI_A]), // つぁ

        // ([kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_D], [kVK_ANSI_QUES, kVK_Return]), // ？[改行]
        // ([kVK_ANSI_J, kVK_ANSI_K], [kVK_ANSI_C], [kVK_ANSI_EXLM, kVK_Return]) // ！[改行]
    ]

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

    func ngPress(kc: Int) -> [Int] {
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

    func ngRelease(kc: Int) -> [Int] {
        pressedKeys.remove(kc)

        // 全部キーを離したらバッファを全部吐き出す
        var r: [Int] = []
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

    func ngType(keys: [Int]) -> [Int] {
        guard !keys.isEmpty else { return [] }

        if keys.count == 1 && keys[0] == kVK_Return {
            return [kVK_Return]
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
