import SwiftUI
import SwiftData

struct TagFilterPickerView: View {
    @Binding var selectedTag: Tag?
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var selectedTagID: String = ""

    var body: some View {
        if !tags.isEmpty {
            Picker("タグフィルター", selection: $selectedTagID) {
                Text("すべて").tag("")
                ForEach(tags) { tag in
                    Text(tag.name).tag(tag.id.uuidString)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .onChange(of: selectedTagID) { _, newValue in
                if newValue.isEmpty {
                    selectedTag = nil
                } else {
                    selectedTag = tags.first { $0.id.uuidString == newValue }
                }
            }
        }
    }
}
