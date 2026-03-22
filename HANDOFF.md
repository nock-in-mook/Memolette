# 引き継ぎメモ

## 現在の状況
- **feature/uikit-carousel** ブランチで作業中（mainにはまだマージしていない）
- セッション043で**爆速モードUIブラッシュアップ**を実施中

### セッション043の変更点

#### フィルター画面（QuickSortFilterView）
- 「特定のタグのメモ」の件数表示: タグ未選択時は非表示（0件も出さない）、タグ選択後に件数表示
- 「対象のメモを選んでください」の下に青字で「複数選択可」テキスト追加
- filterRow の count を `Int?` に変更（nil時は件数テキスト非表示）

#### 操作パネル（QuickSortCellView）
- 「前へ」ボタン: 1枚目でも常に青色表示（薄くしない）。最後の1枚の「次へ」だけ薄くする
- **エディットバー追加**: 仕切り線の上に3分割ボタン（タイトル/本文/タグ）
  - 左: タイトル（緑背景）→ タイトル欄にカーソルフォーカス
  - 中: 本文（白背景）→ 本文編集画面へ
  - 右: タグ（青背景）→ ルーレット出現/非表示トグル
- **ルーレットをデフォルト非表示に変更**: `showDialArea` フラグで制御、「タグ」ボタンタップで表示切替（右からスライドイン + opacity遷移）

#### ROADMAP追記
- Phase 7.5: タスクリンク機能（メモやタスクを枝のように派生させる機能）

## 次のアクション（優先順）
1. **爆速モードUIブラッシュアップ続行**（ユーザーの確認待ち → フィードバック反映）
2. ルーレット回転演出の設計（TagDialViewにリセット＆回転用インターフェース追加）
3. feature/uikit-carousel → main にマージ
4. 実機テストでパフォーマンス確認
5. アプリアイコン

## 主要ファイル（爆速モード関連）
- **QuickSortCellView.swift**: セル内包ビュー（カード+エディットバー+ルーレット+コントロールパネル統合）
- **QuickSortFilterView.swift**: 事前フィルタ選択シート
- **QuickSortView.swift**: メイン画面（フェーズ管理・カルーセル・編集オーバーレイ）
- **CarouselView.swift**: UICollectionViewベースのカルーセル（CarouselCollectionViewサブクラス付き）
- **TagDialView.swift**: ルーレット（settlingガード・snapToTagブロック）
- **TrapezoidTabShape.swift**: TrapezoidTabShape, CardTitleTabShape, CardWithTabShape, Triangle の定義

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3.1)
- 実機: 15promax (26.3.1) — デバイスID: 00008130-0006252E2E40001C
- **ブランチ**: feature/uikit-carousel（mainにマージ前）

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **テストデータバージョン**: sampleDataV10
