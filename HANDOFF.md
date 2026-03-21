# 引き継ぎメモ

## 現在の状況
- **feature/uikit-carousel** ブランチで作業中（mainにはまだマージしていない）
- セッション042で**爆速モードのUI大改修**を実施

### セッション042の主な変更点

#### サジェスト完全削除
- suggestPanel / suggestSection / applySuggestion を QuickSortCellView から削除
- suggestCache / suggestEngine / prepareAll() を QuickSortView から削除
- ローディング画面（Phase.loading）を廃止 → フィルタ選択後すぐカルーセル表示

#### レイアウト大改修（最終形）
- セルレイアウト: メモカード（上）→ ルーレット（中）→ 仕切り線 → コントロールパネル（下）
- メモカード: **CardWithTabShape一体成型**デザイン復活（タブ形状タイトル + 鉛筆ボタン横付き）
- カード横幅80%、上下幅35%、Spacerで各要素間にゆとりを確保
- タイトル: TextFieldでタップ直接編集（Returnで確定）
- 本文: タップで編集画面へ（カーソルは本文末尾にフォーカス）
- タグフッター: ルーレット連動のバッジ表示

#### スワイプ全廃・タップ操作のみ
- フリックでのページ送り無効化（CarouselView の isScrollDisabled: true）
- コントロールパネル: ◁前へ / ゴミ箱（確認ダイアログ付き）/ ▷次へ
- 削除はゴミ箱ボタンタップ → リッチ確認ダイアログ

#### ジェスチャーブロック
- CarouselCollectionView サブクラスでルーレット領域の横スワイプをブロック（gestureRecognizerShouldBegin）
- ※現在はスクロール自体が無効のため実質未使用だが、将来フリック復活時に有効

#### リッチダイアログ統一
- 削除確認: trash.fillアイコン +「メモを削除します / よろしいですか？」
- 編集破棄確認: pencil.slashアイコン +「編集を破棄しますか？」
- 終了確認: 三角警告アイコン（元々リッチだった）
- 全ダイアログ: 背景グレーアウト・角丸カード・影・フェードアニメーション統一

#### ピカピカアニメーション
- タグなし・タイトルなし時にオレンジ枠が点滅（isActive変更時にトリガー）

#### 試みたが撤去したもの
- ルーレット回転演出（ページ切替時に「タグなし」→実タグへ回転）
  - TagDialViewの構造的制約（parentRotationが@Stateで外部アクセス不可）で動作せず
  - ROADMAPに将来タスクとして追記済み

## 次のアクション（優先順）
1. **ルーレット回転演出の設計**（TagDialViewにリセット＆回転用インターフェース追加）
2. **feature/uikit-carousel → main にマージ**
3. 実機テストでパフォーマンス確認
4. アプリアイコン
5. 編集時/閲覧時の文字サイズ変更

## 主要ファイル（爆速モード関連）
- **QuickSortCellView.swift**: セル内包ビュー（カード+ルーレット+コントロールパネル統合）
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
