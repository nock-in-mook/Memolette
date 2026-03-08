import SwiftUI

// 台形タブの形状（上が広く、下が狭い → ファイルのインデックスタブ風）
struct TrapezoidTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 8 // 台形の傾き量
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))           // 左下
        path.addLine(to: CGPoint(x: inset, y: 0))            // 左上
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: 0)) // 右上
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 右下
        path.closeSubpath()
        return path
    }
}
