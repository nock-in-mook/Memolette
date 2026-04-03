import SwiftUI

// UIデザイン定数（全画面共通）
enum DesignConstants {

    // MARK: - コーナーラディウス
    enum CornerRadius {
        /// カード・ダイアログ・シート
        static let card: CGFloat = 10
        /// ボタン背景・検索バー
        static let button: CGFloat = 8
        /// 親タグバッジ
        static let tag: CGFloat = 6
        /// 子タグ・サブ要素
        static let tagSmall: CGFloat = 5
        /// 最小バッジ・インジケータ
        static let badge: CGFloat = 4
        /// ダイアログオーバーレイ
        static let dialog: CGFloat = 16
    }

    // MARK: - タグボーダー色
    enum TagStyle {
        /// 子タグのボーダー色（白半透明）
        static let borderColor = Color.white.opacity(0.3)
    }
}

// MARK: - シャドウ用View拡張
extension View {
    /// 軽い影（バッジ・タグ要素）— opacity 0.15, radius 2, y 1
    func shadowLight() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }

    /// 中程度の影（カード・コンテナ）— opacity 0.15, radius 6, y 2
    func shadowMedium() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    /// カード影（メモカード・バッジ）— opacity 0.15, radius 3, y 1
    func shadowCard() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }

    /// ダイアログ影（大きめ）— opacity 0.15, radius 10, y 4
    func shadowDialog() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    /// 重い影（ダイアログオーバーレイ）— opacity 0.2, radius 16, y 6
    func shadowHeavy() -> some View {
        self.shadow(color: .black.opacity(0.2), radius: 16, y: 6)
    }

    /// トレー引き出しの影 — opacity 0.2, radius 3, x -2, y 0
    func shadowTray() -> some View {
        self.shadow(color: .black.opacity(0.2), radius: 3, x: -2, y: 0)
    }

    /// エンボス影（タブ・ラベル微小影）— opacity 0.3, radius 0.5, x -0.5, y 0.5
    func shadowEmboss() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 0.5, x: -0.5, y: 0.5)
    }
}
