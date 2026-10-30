import SwiftUI

/// Hidden tuning panel: one slider per feel parameter, live while you squish, copyable values.
struct TunePanel: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("調手感").font(.rounded(17, .heavy))
                Text(controller.material.name).font(.rounded(13)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Button("收起") { isPresented = false }
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
            }

            HStack(spacing: 6) {
                Text("音效").font(.rounded(14))
                Spacer()
                ForEach(SoundStyle.allCases) { s in
                    let on = controller.soundStyle == s
                    Button(s.name) { controller.previewSoundStyle(s) }
                        .font(.rounded(13))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .foregroundStyle(on ? .white : Palette.ink)
                        .background(Capsule().fill(on ? Palette.ink : .white))
                        .overlay(Capsule().stroke(Palette.ink, lineWidth: 2))
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TuneField.all) { f in
                        let value = controller.binding(for: f)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(f.name).font(.rounded(14))
                                Spacer()
                                Text(String(format: "%.2f", value.wrappedValue))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Text(f.hint).font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
                            Slider(value: value, in: f.range, step: f.step)
                                .tint(Palette.ink)
                                .accessibilityLabel(f.name)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = controller.exportText
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
                } label: {
                    Text(copied ? "已複製" : "複製數值").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(Palette.ink))
                }
                Button {
                    controller.restoreDefaults()
                } label: {
                    Text("恢復預設").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(Palette.ink)
                        .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
                }
            }
            .font(.rounded(14))
            .buttonStyle(.plain)

            Text(controller.exportText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.8), lineWidth: 1.5))
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 2.5)))
        .shadow(color: Palette.ink, radius: 0, x: 0, y: 4)
        .frame(maxWidth: 460)
    }
}
