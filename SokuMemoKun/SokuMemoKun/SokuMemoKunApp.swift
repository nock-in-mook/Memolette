import SwiftUI
import SwiftData

@main
struct SokuMemoKunApp: App {
    let sharedContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: Memo.self, Tag.self)
        self.sharedContainer = container
        // データリセット＆サンプル投入（一度だけ実行）
        Self.resetAndInsertSamples(container: container)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedContainer)
    }

    // 全データ削除→きれいなタグ＆サンプルメモ投入
    private static func resetAndInsertSamples(container: ModelContainer) {
        let key = "sampleDataV3"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let context = ModelContext(container)

        // 既存データ全削除
        let allMemos = (try? context.fetch(FetchDescriptor<Memo>())) ?? []
        for memo in allMemos { context.delete(memo) }
        let allTags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        for tag in allTags { context.delete(tag) }
        try? context.save()

        // ── 親タグ作成 ──
        let shigoto = Tag(name: "仕事", colorIndex: 1)
        let idea = Tag(name: "アイデア", colorIndex: 4)
        let kaimono = Tag(name: "買い物", colorIndex: 3)
        let shumi = Tag(name: "趣味", colorIndex: 2)
        let kenkou = Tag(name: "健康", colorIndex: 5)
        for tag in [shigoto, idea, kaimono, shumi, kenkou] {
            context.insert(tag)
        }

        // ── 子タグ作成 ──
        let childShigoto: [(String, Int)] = [("会議", 8), ("タスク", 9), ("経費", 15)]
        for (name, color) in childShigoto {
            context.insert(Tag(name: name, colorIndex: color, parentTagID: shigoto.id))
        }
        let childShumi: [(String, Int)] = [("ギター", 22), ("ランニング", 23), ("映画", 24)]
        for (name, color) in childShumi {
            context.insert(Tag(name: name, colorIndex: color, parentTagID: shumi.id))
        }

        // ── サンプルメモ投入 ──

        // タグなし（5枚）
        let noTagMemos: [(String, String)] = [
            ("買い物リスト", "牛乳、卵、パン、バター、ヨーグルト"),
            ("WiFiパスワード", "自宅: hogehoge-5G / カフェ: cafe1234"),
            ("名言メモ", "明日やろうは馬鹿野郎"),
            ("銀行", "振込は月末まで。口座番号: 1234567"),
            ("映画リスト", "観たい: インターステラー、テネット、DUNE"),
        ]
        for (title, content) in noTagMemos {
            let memo = Memo(content: content)
            memo.title = title
            context.insert(memo)
        }

        // 仕事（15枚・普通）
        let shigotoMemos: [(String, String)] = [
            ("定例会議", "来週月曜14時 3F会議室。議題: Q3レビュー"),
            ("企画書", "金曜までに提出。フォーマットはSharePointから"),
            ("議事録 3/10", "Q3売上目標: 前年比120%。新規案件2件"),
            ("田中さん連絡先", "tanaka@example.com / 内線: 3456"),
            ("大阪出張", "3/25-26 新幹線のぞみ予約済み。ホテルは梅田"),
            ("交通費精算", "3月分まとめ。領収書はデスクの引き出し"),
            ("プレゼン準備", "新商品プレゼン。スライド20枚目標"),
            ("1on1メモ", "来月の目標設定。スキルアップ計画を考える"),
            ("クライアントMTG", "木曜15時 Zoom。提案書の最終確認"),
            ("研修資料", "新人向け研修スライドの更新。4月までに"),
            ("予算申請", "来期の開発費用。サーバー代+ライセンス"),
            ("日報テンプレ", "今日やったこと / 明日やること / 所感"),
            ("面接メモ", "候補者3名。技術面接のチェックリスト"),
            ("セキュリティ研修", "年1回の必須研修。期限: 3月末"),
            ("チームランチ", "金曜のランチ会。予約は駅前のイタリアン"),
        ]
        for (title, content) in shigotoMemos {
            let memo = Memo(content: content)
            memo.title = title
            memo.tags.append(shigoto)
            context.insert(memo)
        }

        // アイデア（50枚・大量）
        let ideaBase: [(String, String)] = [
            ("アプリ案", "家計簿×AIアシスタント"),
            ("新サービス", "ペット見守りカメラのサブスク"),
            ("ブログネタ", "SwiftUIの便利Tips 10選"),
            ("副業アイデア", "プログラミング教室オンライン"),
            ("デザイン案", "ミニマリスト風ポートフォリオ"),
            ("IoTプロジェクト", "スマート植木鉢で水やり自動化"),
            ("ゲーム企画", "パズル×RPGのハイブリッド"),
            ("SNSアプリ", "匿名質問箱アプリ"),
            ("教育アプリ", "子供向けプログラミング学習"),
            ("音声AI", "会議の議事録を自動生成"),
            ("健康アプリ", "睡眠トラッキング＋アドバイス"),
            ("料理AI", "冷蔵庫の中身からレシピ提案"),
            ("ARアプリ", "AR家具配置シミュレーター"),
            ("音楽AI", "AIが作曲してくれるアプリ"),
            ("翻訳デバイス", "リアルタイム翻訳メガネ"),
            ("農業テック", "ドローンで畑を自動管理"),
            ("ペットAI", "犬の感情分析カメラ"),
            ("旅行AI", "AIが旅程を組んでくれるアプリ"),
            ("読書サービス", "本の要約を3分で読める"),
            ("防災アプリ", "地域密着型の災害情報共有"),
            ("マッチング", "スキルシェアのマッチング"),
            ("フィンテック", "小銭貯金の自動投資"),
            ("ヘルスケア", "姿勢矯正AIカメラ"),
            ("エコ", "フードロス削減マッチング"),
            ("配送", "ドローン宅配の予約アプリ"),
        ]
        for i in 0..<50 {
            let base = ideaBase[i % ideaBase.count]
            let title = i < ideaBase.count ? base.0 : "\(base.0) #\(i + 1)"
            let memo = Memo(content: base.1)
            memo.title = title
            memo.tags.append(idea)
            context.insert(memo)
        }

        // 買い物（3枚・少量）
        let kaimonoMemos: [(String, String)] = [
            ("食料品", "醤油、味噌、豆腐、納豆、鶏むね肉"),
            ("日用品", "ティッシュ5箱、洗剤、ゴミ袋"),
            ("家電検討", "加湿器を比較中。ダイキン vs シャープ"),
        ]
        for (title, content) in kaimonoMemos {
            let memo = Memo(content: content)
            memo.title = title
            memo.tags.append(kaimono)
            context.insert(memo)
        }

        // 趣味（8枚）
        let shumiMemos: [(String, String)] = [
            ("ギター練習", "Fコード練習中。押さえ方のコツメモ"),
            ("ランニング", "今月の目標: 月間50km。シューズ新調"),
            ("写真スポット", "桜が咲いたら井の頭公園で撮影"),
            ("キャンプ", "テント新調したい。MSR? スノーピーク?"),
            ("映画メモ", "週末にネットフリックス新作チェック"),
            ("カルボナーラ", "パスタ200g、ベーコン100g、卵2個"),
            ("読書リスト", "「嫌われる勇気」「サピエンス全史」"),
            ("旅行計画", "夏休みに沖縄。シュノーケル予約する"),
        ]
        for (title, content) in shumiMemos {
            let memo = Memo(content: content)
            memo.title = title
            memo.tags.append(shumi)
            context.insert(memo)
        }

        // 健康（20枚・多め）
        let kenkouMemos: [(String, String)] = [
            ("体重記録", "68.5kg → 目標65kg。毎朝計測"),
            ("筋トレメニュー", "腕立て30回、スクワット50回、プランク60秒"),
            ("食事記録 月曜", "朝: ヨーグルト / 昼: サラダチキン / 夜: 鍋"),
            ("食事記録 火曜", "朝: バナナ / 昼: 蕎麦 / 夜: 焼き魚定食"),
            ("食事記録 水曜", "朝: トースト / 昼: カレー / 夜: サラダ"),
            ("サプリメント", "ビタミンD、マグネシウム、プロテイン"),
            ("睡眠メモ", "23時就寝→6時起床。7時間確保が理想"),
            ("ストレッチ", "肩回し、前屈、股関節ストレッチ"),
            ("水分摂取", "1日2L目標。ペットボトルで計測"),
            ("歯医者", "次回4/15 14:00。定期検診"),
            ("眼科", "コンタクト処方箋更新。度数: -3.5"),
            ("花粉症対策", "アレグラ、目薬、マスク。3月がピーク"),
            ("健康診断", "年1回。去年はコレステロール注意"),
            ("ランニング記録", "3/1: 5km 28分 / 3/5: 3km 17分"),
            ("瞑想メモ", "毎朝5分。呼吸に集中。雑念OK"),
            ("姿勢改善", "デスクワーク1時間ごとに立つ"),
            ("血圧記録", "朝: 125/82 夜: 118/76"),
            ("ダイエット", "糖質制限は続かない。PFCバランス重視"),
            ("予防接種", "インフルエンザ 10月。コロナ追加接種"),
            ("メンタル", "ジャーナリング始めた。寝る前に3行"),
        ]
        for (title, content) in kenkouMemos {
            let memo = Memo(content: content)
            memo.title = title
            memo.tags.append(kenkou)
            context.insert(memo)
        }

        // マークダウンメモ（タグなし 3枚）
        let mdMemos: [(String, String)] = [
            ("定例会議MD", "# 定例会議\n\n## 議題\n- 売上報告\n- 新規プロジェクト\n- **来週までの宿題**\n\n> 次回は金曜15時"),
            ("カルボナーラMD", "# カルボナーラ\n\n## 材料\n- パスタ 200g\n- ベーコン 100g\n- 卵 2個\n- **パルメザンチーズ** たっぷり\n\n## 手順\n1. パスタを茹でる\n2. ベーコンを炒める\n3. 卵とチーズを混ぜる"),
            ("Swift入門MD", "# Swift入門\n\n## 変数\n- `let` は定数\n- `var` は変数\n\n## 関数\n- `func 名前() -> 型`\n\n> SwiftUIは**宣言的UI**フレームワーク"),
        ]
        for (title, content) in mdMemos {
            let memo = Memo(content: content, isMarkdown: true)
            memo.title = title
            context.insert(memo)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
    }
}
