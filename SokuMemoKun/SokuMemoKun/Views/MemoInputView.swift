import SwiftUI
import SwiftData

struct MemoInputView: View {
    @Bindable var viewModel: MemoInputViewModel
    var isInputFocused: FocusState<Bool>.Binding
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 8) {
            TextEditor(text: $viewModel.inputText)
                .focused(isInputFocused)
                .frame(minHeight: 100, maxHeight: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
                .overlay(alignment: .topLeading) {
                    // プレースホルダー
                    if viewModel.inputText.isEmpty {
                        Text("メモを入力...")
                            .foregroundStyle(.gray.opacity(0.5))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Spacer()

                // コピーボタン
                Button {
                    UIPasteboard.general.string = viewModel.inputText
                } label: {
                    Label("コピー", systemImage: "doc.on.doc")
                        .font(.callout)
                }
                .disabled(viewModel.inputText.isEmpty)

                // 保存ボタン
                Button {
                    viewModel.save(context: modelContext)
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .font(.callout)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
