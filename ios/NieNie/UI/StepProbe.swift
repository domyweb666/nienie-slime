import CoreMotion
import SwiftUI

/// 走路提案第 4 片的前哨：只確認這支手機讀不讀得到步數、查得到多久以前。玩法還沒接上，手機版還沒有窗台。
/// 按了才問權限，步數只顯示在面板上，不存、不傳。
struct StepProbe: View {
    @State private var pedometer = CMPedometer()
    @State private var lines: [String] = []

    /// 今天算 0，往回查這幾天，看哪一天開始變 0
    private let daysBack = [0, 1, 3, 6, 7, 8, 14]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                read()
            } label: {
                Text("走路：讀步數").font(.rounded(13))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .foregroundStyle(Palette.ink)
                    .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2)))
            }
            .buttonStyle(.plain)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private func read() {
        guard CMPedometer.isStepCountingAvailable() else {
            lines = ["這支手機不能計步"]
            return
        }
        lines = []
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var results: [Int: String] = [:]
        for back in daysBack {
            guard let from = cal.date(byAdding: .day, value: -back, to: today),
                  let next = cal.date(byAdding: .day, value: 1, to: from) else { continue }
            let to = min(next, Date())
            pedometer.queryPedometerData(from: from, to: to) { data, error in
                DispatchQueue.main.async {
                    if let error {
                        results[back] = "\(back) 天前：讀不到（\(error.localizedDescription)）"
                    } else {
                        results[back] = "\(back) 天前：\(data?.numberOfSteps.intValue ?? 0) 步"
                    }
                    lines = daysBack.compactMap { results[$0] }
                }
            }
        }
    }
}
