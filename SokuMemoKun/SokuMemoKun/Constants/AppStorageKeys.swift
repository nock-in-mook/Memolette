import Foundation

// AppStorage / UserDefaults で使うキー文字列を一元管理
enum AppStorageKeys {

    // MARK: - 設定系

    /// マークダウン表示ON/OFF
    static let markdownEnabled = "markdownEnabled"
    /// 新規メモをデフォルトでマークダウンにするか
    static let defaultMarkdown = "defaultMarkdown"
    /// 前回のメモを復元するか
    static let restoreLastMemo = "restoreLastMemo"
    /// ルーレットの初期選択タグインデックス
    static let dialDefault = "dialDefault"
    /// カラー枠表示ON/OFF
    static let coloredFrame = "coloredFrame"
    /// 文字数カウント表示ON/OFF
    static let showCharCount = "showCharCount"
    /// 行番号表示ON/OFF
    static let showLineNumbers = "showLineNumbers"

    // MARK: - グリッドサイズ

    /// タグなしタブのグリッド列数
    static let noTagGridSize = "noTagGridSize"
    /// 全タグタブのグリッド列数
    static let allTagGridSize = "allTagGridSize"
    /// よく見るタブのグリッド列数
    static let frequentTabGridSize = "frequentTabGridSize"

    // MARK: - 並び順

    /// 全タグタブの並び順
    static let allTagSortOrder = "allTagSortOrder"
    /// タグなしタブの並び順
    static let noTagSortOrder = "noTagSortOrder"
    /// よく見るタブの並び順
    static let frequentTagSortOrder = "frequentTagSortOrder"

    // MARK: - タブカスタムカラー

    /// 全タグタブのカスタムカラーインデックス
    static let allTabCustomColor = "allTabCustomColor"
    /// よく見るタブのカスタムカラーインデックス
    static let frequentTabCustomColor = "frequentTabCustomColor"

    // MARK: - 編集状態

    /// 最後に編集していたメモのID
    static let lastEditingMemoID = "lastEditingMemoID"

    // MARK: - ダミーデータ投入フラグ（開発用）

    /// サンプルデータ投入済みフラグ
    static let sampleDataV10 = "sampleDataV10"
    /// 長文テストメモ投入済みフラグ
    static let longTextTestV2 = "longTextTestV2"
    /// 子タグバッジテスト投入済みフラグ
    static let childTagBadgeTestV1 = "childTagBadgeTestV1"
    /// タグ履歴ダミーデータ投入済みフラグ
    static let dummyTagHistoryV1 = "dummyTagHistoryV1"
}
