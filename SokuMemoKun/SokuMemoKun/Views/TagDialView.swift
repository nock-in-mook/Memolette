import SwiftUI
import SwiftData

// カジノルーレット風タグ選択（巨大な円の左端の弧だけ見える）
// 円の中心は画面右の外。選択中のアイテムが一番左に突出する。
struct TagDialView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Binding var selectedTagID: UUID?

    private var options: [(id: String, name: String, color: Color)] {
        var list: [(String, String, Color)] = [("none", "なし", tagColor(for: 0))]
        for (i, tag) in tags.enumerated() {
            list.append((tag.id.uuidString, tag.name, tagColor(for: i + 1)))
        }
        return list
    }

    // 円の半径（大きいほど緩やかな弧）
    private let wheelRadius: CGFloat = 300
    // 各タグ間の角度（度）
    private let itemAngle: CGFloat = 8

    @State private var rotation: CGFloat = 0
    @State private var dragStart: CGFloat = 0

    private var currentIndex: Int {
        let count = options.count
        guard count > 0 else { return 0 }
        let raw = Int(round(rotation / itemAngle))
        return ((raw % count) + count) % count
    }

    // ダイヤルの描画高さ
    private let dialHeight: CGFloat = 160

    var body: some View {
        let count = options.count

        ZStack {
            ForEach(-4...4, id: \.self) { offset in
                let index = ((currentIndex - offset) % count + count) % count
                if index < options.count {
                    let option = options[index]
                    let angle = CGFloat(offset) * itemAngle
                        - (rotation - CGFloat(currentIndex) * itemAngle)
                    let rad = angle * .pi / 180

                    // 弧のX: cos(0)=1で最も左、角度が増えると右へ
                    let arcX = wheelRadius * (1 - cos(rad))
                    // 弧のY: 中心からの上下方向
                    let arcY = wheelRadius * sin(rad)

                    let dist = abs(angle)
                    let maxDist = itemAngle * 4
                    let fade = max(0, 1 - dist / maxDist)
                    let isSelected = dist < itemAngle / 2

                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(option.color)
                            .frame(width: 4, height: 18)
                        Text(option.name)
                            .font(.system(
                                size: isSelected ? 12 : 10,
                                weight: isSelected ? .bold : .regular,
                                design: .rounded
                            ))
                            .lineLimit(1)
                    }
                    .padding(.trailing, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(option.color.opacity(isSelected ? 0.25 : 0.12))
                    )
                    .offset(x: arcX, y: arcY)
                    .opacity(Double(fade))
                }
            }
        }
        .frame(width: 72, height: dialHeight, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    rotation = dragStart - value.translation.height * 0.3
                }
                .onEnded { _ in
                    let snapped = round(rotation / itemAngle) * itemAngle
                    withAnimation(.easeOut(duration: 0.15)) {
                        rotation = snapped
                    }
                    dragStart = snapped
                    updateSelection()
                }
        )
        .onAppear {
            dragStart = rotation
        }
    }

    private func updateSelection() {
        let index = currentIndex
        if index < options.count {
            let option = options[index]
            selectedTagID = option.id == "none" ? nil : UUID(uuidString: option.id)
        }
    }
}
