# 引き継ぎメモ

## 現在の状況
- **feature/uikit-carousel** ブランチで作業中（mainにはまだマージしていない）
- セッション039でカルーセルをUICollectionViewベースに置き換え＋カードUI改修

### セッション039の主な変更点

#### カードUI改修
- **CardWithTabShape**: タブとカード本体を1つの連続パスで描画（縁取りの途切れ解消）
- **CardTitleTabShape**: 左直角・右のみ斜め角丸（台形→フォルダタブ風に変更）
- **縁取り線**: 1.5pt → 2.5ptに太く
- **編集画面**: 「タイトル」ラベル削除、タイトルと本文の仕切り線をはっきりに
- **編集ボタン位置**: タイトルバーの上下中心に合わせ
- **枚数表示**: 一番上に移動、「1/23 枚」形式

#### カルーセル置き換え（UICollectionView化）
- **SwiftUI ScrollView → UICollectionView** に完全置き換え
- **CarouselView.swift** 新規作成（UIViewControllerRepresentable）
- **SnapCenterFlowLayout**: velocity考慮の中央スナップ（軽いフリックでもページング）
- **UIHostingConfiguration**: 既存SwiftUIカードビューをそのまま利用
- **DiffableDataSource**: アイテム追加・削除がアニメーション付き
- **初回表示ラグ・スナップ精度・スクロール滑らかさ**が大幅改善

#### レイアウト変更
- **上下入れ替え**: サジェスト+ルーレット（上）→ カード（下）の順に
- **削除方向**: 上スワイプ → **下スワイプ**に変更
- **矢印ガイド**: 横並び（←前 ↓削除 次→）→ 削除のみ残して左右は三角マークに
- **カード両脇に青い三角マーク**: 隣のカードは画面外（spacing: 200）
- **下部パネル上端固定(370pt)**: サジェスト行数変化でもレイアウト安定

### 残っている課題: 爆速スクロール（次セッションの最重要課題）

#### 問題
カード切り替え時に「ちょこちょこ固まる」現象が残っている。原因は：
1. `scrolledMemoID` が変わる → `onChange` 発火
2. `syncEditingState(for:)` が走る
3. `selectedParentTagID` / `selectedChildTagID` が変わる
4. **TagDialView（ルーレット）が再描画** ← これが重い
5. `updateSuggestions()` でサジェストパネルも再描画
6. 合計で1フレーム以上かかり、スクロールがカクつく

#### 試して効果がなかったアプローチ
- **遅延同期**: syncEditingStateを50ms/100ms遅延 → むしろ悪化（タイミングがズレてガタガタ）
- **分散更新**: ルーレットとサジェストを別フレームに分ける → 効果薄い
- **スクロール中のsync停止**: 停止後にフル同期 → 止まった瞬間にカクつく
- **登場アニメーション**: 初回表示のラグをごまかす → 根本解決にならない

#### 次セッションでの解決策: セル内包方式

**設計思想**: カード + ルーレット + サジェストを1つのUICollectionViewセルに含める。
セル単位で独立した状態を持ち、親ビューのState変更をゼロにする。

```
現在の構造（問題あり）:
┌─ QuickSortView ─────────────────────────┐
│  @State selectedParentTagID  ← 共有State │
│  @State selectedChildTagID   ← 共有State │
│  @State currentSuggestions   ← 共有State │
│                                          │
│  ┌─ CarouselView (UICollectionView) ──┐  │
│  │  [Card1] [Card2] [Card3] ...       │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌─ suggestPanel ─┐  ┌─ dialArea ─┐     │
│  │ タグ提案        │  │ ルーレット  │     │ ← カード切替ごとに再描画
│  └────────────────┘  └────────────┘     │
└──────────────────────────────────────────┘

新しい構造（セル内包方式）:
┌─ QuickSortView ─────────────────────────┐
│  （共有Stateなし or 最小限）              │
│                                          │
│  ┌─ CarouselView (UICollectionView) ──┐  │
│  │  ┌─ Cell 1 ────────────────────┐   │  │
│  │  │  カード                      │   │  │
│  │  │  サジェスト  │  ルーレット   │   │  │
│  │  └─────────────────────────────┘   │  │
│  │  ┌─ Cell 2 ────────────────────┐   │  │
│  │  │  カード                      │   │  │
│  │  │  サジェスト  │  ルーレット   │   │  │
│  │  └─────────────────────────────┘   │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**メリット**:
- カード切替時に親ビューのStateが一切変わらない → **再描画ゼロ**
- UICollectionViewのセル再利用で、画面外のセルは自動解放
- 実質同時に3枚（前・現在・次）しかメモリに乗らない
- 連続フリックで途中のセルはスキップ（描画されない）→ 今より軽い

**実装のポイント**:
1. **セルごとに独立したタグ選択状態**: `memo.tags`から直接読み込み
2. **タグ変更の反映**: セル内のルーレットで選択 → `memo.tags`に直接書き込み
3. **サジェストはキャッシュ済み**: `suggestCache[index]`をセルに渡すだけ
4. **編集モード**: セル内のカードをタップ → cardEditOverlayは親で管理（既存のまま）
5. **cardContent クロージャの拡張**: カード+サジェスト+ルーレットの縦並びビューを返す

**注意点**:
- `TagDialView` が `@Binding` で `selectedParentTagID` を受け取る設計 → セル内のローカル `@State` に変更
- `applyTagFromDial()` → セル内で `memo.tags` を直接更新
- `newTagSheet` → 親に通知するコールバックが必要
- セルの高さをカード+サジェスト+ルーレット分に拡大（CarouselViewのcardHeightを変更）

## 主要ファイル（爆速モード関連）
- **QuickSortView.swift**: メイン画面（フェーズ管理・カルーセル・編集オーバーレイ・セット管理）
- **CarouselView.swift**: UICollectionViewベースのカルーセル（UIViewControllerRepresentable + SnapCenterFlowLayout）
- **QuickSortFilterView.swift**: フィルタ選択
- **QuickSortResultView.swift**: 戦績表示
- **TrapezoidTabShape.swift**: TrapezoidTabShape, CardTitleTabShape, CardWithTabShape, Triangle の定義
- **TagDialView.swift**: ルーレット（セル内包化の主要対象）
- **MainView.swift**: ⚡ボタン→fullScreenCover起動

## 次のアクション（優先順）
1. **爆速スクロール: セル内包方式の実装**（最重要）
2. feature/uikit-carousel → main にマージ
3. 実機テストでパフォーマンス確認
4. レイアウト微調整（セル内のサジェスト+ルーレット配置）
5. アプリアイコン
6. 編集時/閲覧時の文字サイズ変更

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3.1)
- 実機: 15promax (26.3.1) — デバイスID: 30A153A2-9507-5499-8B3D-341320DA2AB3
- **ブランチ**: feature/uikit-carousel（mainにマージ前）

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **テストデータバージョン**: sampleDataV10
- **MainViewのhueFromColorIndex内RGBテーブル**: tabColorsと同じ値を維持すること
- **CarouselView.swiftのプロジェクト追加**: pbxprojに手動でfileRef/buildRef/group追加済み（ID: CAROUSEL00000000000001/2）
