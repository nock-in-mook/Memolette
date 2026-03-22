# 引き継ぎメモ

## 現在の状況
- **feature/uikit-carousel** ブランチで作業中（mainにはまだマージしていない）
- セッション044で**爆速メモ整理モードのUI大改修第3弾**を実施

### セッション044の主な変更点

#### トグルボタン二重発火バグ修正
- TapPressableViewの `onTapGesture` + `simultaneousGesture(LongPressGesture)` が両方発火する問題を `DragGesture(minimumDistance: 0)` 1本に統合して修正

#### カードUI改善
- タイトルタブ: デフォルトでオレンジ背景（常時）、編集時は濃いオレンジ+白インナーシャドウ
- タグフッター: デフォルトで薄い水色背景（常時）、タップでルーレットトグル
- 本文: 閲覧時もScrollViewで全文スクロール可能に
- 閲覧時拡大ボタン: スクロールで青い拡大ボタン出現 → カード80%に拡大、状態保持（編集抜けても拡大維持）
- 鉛筆ボタン＋編集画面を完全削除（インライン編集に統合済み）
- scaleEffect拡大を削除（はみ出し・帯の問題解消）

#### コントローラーエリア固定化
- 弧の仕切り線 + 3つの編集ボタン + 操作パネル（前へ/ゴミ箱/次へ）をセル外に移動
- カルーセルスクロールに追従しなくなった
- 編集モードを `CellEditMode` enumで一元管理（@Binding）

#### ナビゲーション再設計
- 最上段: ✕丸囲み / 枚数(中央) / 整理をおわる
- 上部ページ送り削除（操作パネルに集約）
- ✕ → フィルター画面に戻す（変更保存なし）
- 整理をおわる/完了 → フィルター画面に戻す（変更保存あり）
- 戦績画面に「整理画面にもどる」ボタン追加
- 最終ページの次へ → オレンジ「完了▶」ボタンに変化

#### ボタンデザイン
- すりガラス風（A15パターン）に変更
- ボタンラボをアニメ塗り特化に全面刷新（16パターン×3色）

#### 操作パネル改善
- 削除: 中央固定、少し下に配置
- ロックボタン: 削除右寄りに小さく配置（丸囲み）、ダイアログ確認方式
- カードにロックアイコン（右上端、出現時フラッシュアニメ）

#### キーボード対応
- 本文編集時: キーボード高さに応じてカード高さ自動調整
- 全ダイアログ表示前にキーボードを閉じる対応（全画面横断で実施）

#### 長文テストメモ生成
- 「長文テスト」タグに1000〜20000文字のメモ20枚（千文字刻み、1000文字から順）

#### その他
- APP_RELEASE_GUIDE.md / APP_RELEASE_GUIDE_ANDROID.md に「キーボードとダイアログの干渉チェック」追記
- 実機ビルド用の証明書セットアップ（Mac②で.p12インポート済み）
- 証明書.p12をgitignoreに追加

## 次のアクション（優先順）
1. **実機で長文テストメモのパフォーマンス検証**（別のMacで実機ビルド）
2. 長文メモの読み込み中スピナー or 遅延表示の実装
3. ボタンラボでA7（不透明ベース+色）も実機で比較検討
4. feature/uikit-carousel → main にマージ
5. アプリアイコン

## 主要ファイル（爆速モード関連）
- **QuickSortCellView.swift**: セル（カード+ルーレットのみ、コントローラーは外）
- **QuickSortView.swift**: メイン画面（フェーズ管理・カルーセル・コントローラーエリア・操作パネル・各種ダイアログ）
- **QuickSortFilterView.swift**: 事前フィルタ選択シート
- **ButtonLabView.swift**: アニメ塗りボタンラボ（16パターン×3色）+ PressableButtonStyle / TapPressableView定義
- **QuickSortResultView.swift**: 戦績画面
- **CarouselView.swift**: UICollectionViewベースのカルーセル
- **TagDialView.swift**: ルーレット
- **TrapezoidTabShape.swift**: 各種Shape定義

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3.1)
- 実機: 15promax (26.3.1) — デバイスID: 00008130-0006252E2E40001C
- **実機ビルド**: 証明書は別Macから.p12エクスポートでインポート済み、`-allowProvisioningUpdates` フラグ必要
- **ブランチ**: feature/uikit-carousel（mainにマージ前）

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **テストデータバージョン**: sampleDataV10 + longTextTestV2
- **押せるボタンの影**: 薄い色のボタンは不透明ベース(Color(white: 0.95))を敷かないと影が透過して見えない
