import SwiftUI
import SwiftData

struct MainView: View {
    @State private var viewModel = MemoInputViewModel()
    @State private var selectedTag: Tag?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // タグフィルター（キーボード非表示時のみ）
                if !isInputFocused {
                    TagFilterPickerView(selectedTag: $selectedTag)
                        .transition(.opacity)
                }

                // テキスト入力エリア
                MemoInputView(viewModel: viewModel, isInputFocused: $isInputFocused)

                Divider()

                // メモリスト
                MemoListView(selectedTag: selectedTag)
            }
            .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            .navigationTitle("即メモ君")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showTagTitleSheet) {
                if let memo = viewModel.savedMemo {
                    TagTitleSheetView(memo: memo)
                }
            }
            .onAppear {
                // 起動時に自動フォーカス
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
        }
    }
}
