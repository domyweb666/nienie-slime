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

/// Chunky cartoon chip: white fill, thick ink outline.
struct ChipStyle: ButtonStyle {
    var circle = false
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundStyle(Palette.ink)
            // no hard drop under the outline: 多米 2026-11-01 saw it as two rings stacked; pressing scales down a little instead
            .background(Group {
                if circle {
                    Circle().fill(Palette.chip).overlay(Circle().stroke(Palette.ink, lineWidth: 2.5))
                } else {
                    Capsule().fill(Palette.chip).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5))
                }
            })
            .scaleEffect(pressed ? 0.94 : 1)
    }
}

struct ContentView: View {
    @EnvironmentObject var controller: SlimeController
    @State private var showHint: Bool

    init() {
        // 提案第 32 條: the hint shows on the first three launches only
        _showHint = State(initialValue: UserDefaults.standard.integer(forKey: "launchCount") < 3)
    }
    @State private var showTune = false
    @State private var hintText = "捏它、拉它、揉它。放著不管它也會自己動"
    @State private var hintGen = 0

    var body: some View {
        ZStack {
            SlimeCanvas(controller: controller)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Text(hintText)
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
        .alert("牠想跟你出門", isPresented: $controller.walkAsk) {   // 走路: asked only when the gift stone is tapped; 先不要 keeps the stone and never asks again
            Button("先不要") { controller.walkAnswer(false) }
            Button("好") { controller.walkAnswer(true) }
        } message: {
            Text("要讓牠知道你走了多少路嗎？步數只留在這支手機上。")
        }
        .task {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "launchCount") + 1, forKey: "launchCount")
            guard showHint else { return }
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

            // v2.21: three states, music and sounds → sounds only → silent
            Button {
                controller.soundMode = (controller.soundMode + 1) % 3
            } label: {
                Image(systemName: ["music.note", "speaker.wave.2.fill", "speaker.slash.fill"][controller.soundMode])
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(ChipStyle(circle: true))
            .accessibilityLabel(["音樂和音效", "只有捏的聲音", "全部靜音"][controller.soundMode])
            .accessibilityHint("點一下換下一種")
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // v2.23 收集 (多米 11-02: all of them there from the start): four slimes; the material moved to the panel
            HStack(spacing: 2) {
                ForEach(SlimeKind.allCases) { k in
                    let on = controller.slime == k
                    Button {
                        guard !on else { return }
                        controller.select(k)
                        showSlimeHint(k)
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(Color(uiColor: k.colors.base))
                                .overlay(Circle().stroke(on ? .white : Palette.ink, lineWidth: 2))
                                .frame(width: 12, height: 12)
                            Text(k.name).font(.rounded(14))
                        }
                        .padding(.horizontal, 9).padding(.vertical, 8)
                        .foregroundStyle(on ? .white : Palette.ink)
                        .background(Capsule().fill(on ? Palette.ink : .clear))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .accessibilityHint(k.desc)
                }
            }
            .padding(3)
            .background(Capsule().fill(Palette.chip).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("選史萊姆")

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

    /// Its name and personality for 2.6 s.
    private func showSlimeHint(_ k: SlimeKind) {
        hintText = "\(k.name)：\(k.desc)"
        hintGen += 1
        let gen = hintGen
        withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard gen == hintGen else { return }
            withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.6)) { showHint = false }
        }
    }
}
