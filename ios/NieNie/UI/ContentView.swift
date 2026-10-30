import SwiftUI

enum Palette {
    static let ink = Color(red: 0x2E / 255, green: 0x3A / 255, blue: 0x2A / 255)
    static let inkSoft = Color(red: 0x5E / 255, green: 0x74 / 255, blue: 0x58 / 255)
    static let chip = Color.white
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Chunky cartoon chip: white fill, thick ink outline, solid drop.
struct ChipStyle: ButtonStyle {
    var circle = false
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundStyle(Palette.ink)
            .background(Group {
                if circle {
                    Circle().fill(Palette.chip).overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
                } else {
                    Capsule().fill(Palette.chip).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
                }
            })
            .shadow(color: Palette.ink, radius: 0, x: 0, y: pressed ? 1 : 3)
            .offset(y: pressed ? 2 : 0)
    }
}

struct ContentView: View {
    @EnvironmentObject var controller: SlimeController
    @State private var showHint = true
    @State private var showTune = false

    var body: some View {
        ZStack {
            SlimeCanvas(controller: controller)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Text("抓住拉・按住壓・從旁邊推")
                    .font(.rounded(14))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
                    .padding(.top, 14)
                    .opacity(showHint ? 1 : 0)
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
                if showTune {
                    TunePanel(isPresented: $showTune)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .task {
            try? await Task.sleep(nanoseconds: 7_000_000_000)
            withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.6)) { showHint = false }
        }
    }

    private var topBar: some View {
        HStack {
            // hidden tuning panel: long-press the title (no clash with system three-finger gestures)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("捏捏").font(.rounded(26, .heavy))
                Text("史萊姆").font(.rounded(13)).foregroundStyle(Palette.inkSoft).tracking(1.8)
            }
            .foregroundStyle(Palette.ink)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1.2) {
                withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showTune.toggle() }
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: "調手感") { showTune.toggle() }

            Spacer()

            Button {
                controller.muted.toggle()
            } label: {
                Image(systemName: controller.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(ChipStyle(circle: true))
            .accessibilityLabel(controller.muted ? "打開聲音" : "關閉聲音")
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(SlimeMaterial.allCases) { m in
                    let on = controller.material == m
                    Button {
                        controller.select(m)
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(Color(uiColor: m.colors.base))
                                .overlay(Circle().stroke(on ? .white : Palette.ink, lineWidth: 2))
                                .frame(width: 12, height: 12)
                            Text(m.name).font(.rounded(14))
                        }
                        .padding(.horizontal, 11).padding(.vertical, 8)
                        .foregroundStyle(on ? .white : Palette.ink)
                        .background(Capsule().fill(on ? Palette.ink : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(3)
            .background(Capsule().fill(Palette.chip).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
            .shadow(color: Palette.ink, radius: 0, x: 0, y: 3)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("史萊姆手感")

            Button {
                controller.resetShape()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(ChipStyle(circle: true))
            .accessibilityLabel("揉回原形")

            Spacer(minLength: 0)
        }
    }
}
