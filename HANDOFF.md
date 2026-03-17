# 引き継ぎメモ

## 現在の状況
- **feature/roulette-swiftui-views** ブランチで作業開始（feature/roulette-size-testから分岐）
- **目的**: TagDialViewをCanvasからSwiftUIビューベースに書き直す
- feature/roulette-size-testには024セッションの変更がコミット済み

### セッション024の変更点
- トレー右端に「しまう」矢印ボタン追加（36pt幅、引き出し時のみ表示）
- チラ見せ状態でルーレットタッチ無効（.allowsHitTesting）
- トレー余白タップで閉じる機能
- 取っ手スワイプジェスチャー廃止
- タイトル欄上部拡大（top 6→10pt、トレー下端 10→6ptで吸収）
- 親タグラベル・ボタン位置を矢印ボタン分(+36pt)ずらし
- 子タグ追加時の親タグ未選択警告アラート
- ルーレット長押しでタグ編集/削除（位置判定が不安定→SwiftUI化で解決予定）

## ★ ルーレットSwiftUI化 改修プラン

### 背景
- 現在のTagDialViewはCanvas（drawSectors等）で描画
- Canvasはタッチ位置からタグを特定する手段がない
- 個別パネルのタップ・長押し・contextMenuが実装できない

### ゴール
- 各タグパネルが独立したSwiftUI Viewになる
- パネルタップ → そのタグに移動（針の位置に回転）
- パネル長押し → .contextMenuで編集/削除メニュー
- 見た目は現在のCanvasと完全に同じ

### 改修手順

#### Step 1: セクタービューの作成
- `TagSectorView`: 1つのタグパネル（扇形）を描画するView
- Path + Shape で弧を描画（drawSectorsのロジックを移植）
- テキスト配置: overlay + rotationEffect
- フォントサイズの動的計算（現在のmaxCharsロジック移植）
- テキスト色の自動判定（luminance計算移植）

#### Step 2: ルーレットの構造
- `TagDialView` のbodyを VStack/ZStack ベースに変更
- ForEach で ±10スロット分のTagSectorViewを生成
- 親リング（outerR=350, innerR=240）と子リング（outerR=240, innerR=130）
- 各セクターの位置: rotationEffectでdisplayAngleを適用
- フェード: opacityをdisplayAngleから計算

#### Step 3: ジェスチャーの移植
- DragGesture: 既存ロジックをそのまま適用
  - y方向ドラッグ → 回転量計算（translation.height * -0.3）
  - ゴムバンド: clampedRotation()
  - スナップ: clampedSnap() + .spring(response: 0.3)
- 各セクターに .onTapGesture → そのタグにスナップ回転
- 各セクターに .contextMenu → 編集/削除メニュー

#### Step 4: 縁取り・シャドウ・ポインター
- 縁取り: 弧のStroke（3本: 親外周3pt、境界1.5pt、子内周1.5pt）
- 選択ポインター: 赤三角（overlay）
- インナーシャドウ: LinearGradientのoverlayで再現
- .clipped() でCanvas外をクリップ

#### Step 5: 外部インターフェース維持
- Binding（parentSelectedID, childSelectedID, showChild等）はそのまま
- onLongPressコールバック → .contextMenuに置き換え
- MemoInputViewの呼び出し側は変更最小限

### 現在のジオメトリ定数（変更しない）
- wheelRadius: 350, parentThickness: 110, childThickness: 110
- itemAngle: 8°, dialHeight: 211
- parentOuterR: 350, parentInnerR: 240
- childOuterR: 240, childInnerR: 130
- canvasWidth: 動的（cos計算、約460pt）

### リスク
- パフォーマンス: ForEachで大量のViewを生成するため、Canvas比で重くなる可能性
  → 対策: 表示範囲外のViewはEmptyView化、lazy描画
- 弧の見た目の差異: PathとCanvasで微妙にレンダリングが異なる可能性
  → 対策: 最初にShapeを作って見比べる

## ブランチ構成
- **main**: セッション020までの全機能統合済み + トレー方式基本実装
- **feature/roulette-size-test**: セッション024まで（トレーUI改善、長押し暫定版）
- **feature/roulette-swiftui-views**: ルーレットSwiftUI化（新規、これから実装）

## 主要ファイル
- **TagDialView.swift**: Canvas描画（これをSwiftUIビューに書き換え）
- MemoInputView.swift: トレー方式、長押し編集UI、子タグ追加警告
- SettingsView.swift: タグトレー起動時状態設定
- TagDetailEditView.swift: タグ名・色の編集（長押し→編集で再利用）
- TagEditView.swift: タグ削除ロジック（deleteSelected参考）

## 環境
- **Mac①（旧）**: MacBook Air M2 — Xcode旧版, シミュレータ iPhone 15 Pro Max (iOS 17.2)
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro Max (iOS 26.3.1)
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)
- 2台体制でiOS 17 / iOS 26 両方の互換性テストが可能

## 次のアクション
1. **TagDialViewのSwiftUI化**（上記プランに沿って実装）
2. パネルタップでタグ移動、長押しで編集/削除
3. 動作確認後 → feature/roulette-size-test にマージ
4. その後のタスク: タグサジェストUI、学習機能、Specialメニュー等

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **子タグ連打フリーズ**: withAnimationの競合が原因。解決済み
- **バンドルID**: com.sokumemokun.app
