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

/// v2.52 B7 (多米 11-22 交辦: 上架版本拿掉「調」按鈕，隱藏面板照舊). The 調 button is for 多米's own tuning: there in a development build and on TestFlight,
/// gone in the App Store's build. The hidden panel (long-press the title) stays in every build and can open the desk from there.
enum AppChannel {
    static let showsFeelButton: Bool = {
        #if DEBUG
        return true
        #else
        // a TestFlight install carries a receipt named sandboxReceipt; the App Store's is named receipt
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }()
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
    @State private var showFeel = false
    @State private var hintText = "捏它、拉它、揉它。放著不管它也會自己動"
    @State private var hintGen = 0

    var body: some View {
        ZStack {
            SlimeCanvas(controller: controller)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                // v2.39 手感調節台: over the sky, the slime stays squishable below it
                if showFeel {
                    FeelDesk(isPresented: $showFeel)
                        .padding(.top, 10)
                        .transition(.opacity)
                }
                Text(hintText)
                    .font(.rounded(14))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
                    .padding(.top, 14)
                    .opacity(showHint && !showFeel ? 1 : 0)
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
                if showTune {
                    TunePanel(isPresented: $showTune, openFeel: {
                        withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showTune = false; showFeel = true }
                    })
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .onChange(of: controller.toastGen) { _, _ in showTimedHint(controller.toastText) }   // v2.59 窗景
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
                withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showTune.toggle(); if showTune { showFeel = false } }
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
            // v2.40 環境音: long press to choose rain, a wood fire or lofi
            .contextMenu {
                Picker("背景聲音", selection: $controller.ambience) {
                    Text("雨").tag("rain")
                    Text("柴火").tag("fire")
                    Text("白噪音").tag("noise")
                    Text("lofi").tag("lofi")
                }
            }
            .accessibilityLabel(["環境音和音效", "只有捏的聲音", "全部靜音"][controller.soundMode])
            .accessibilityHint("點一下換下一種，長按選雨、柴火或 lofi")
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // v2.23 收集 (多米 11-02: all of them there from the start): four slimes; the material moved to the panel
            // v2.33 一隻為主: hidden while the panel's 一隻為主 is 1
            if controller.current.one < 0.5 {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(76), spacing: 2), count: 3), spacing: 2) {   // v2.57 ten do not fit in a row: three to a row, like the web
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
            .background(RoundedRectangle(cornerRadius: 22).fill(Palette.chip).overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 2.5)))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("選史萊姆")
            }

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

            // v2.39 手感調節台 (多米 11-16: 要有個操控數值的地方); v2.52 B7: not in the App Store's build
            if AppChannel.showsFeelButton {
            Button {
                withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showFeel.toggle(); if showFeel { showTune = false } }
            } label: {
                Text("調").font(.rounded(18, .heavy))
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(ChipStyle(circle: true))
            .accessibilityLabel(showFeel ? "收起手感調節台" : "打開手感調節台")
            }
        }
    }

    /// Its name and personality for 2.6 s.
    private func showSlimeHint(_ k: SlimeKind) { showTimedHint("\(k.name)：\(k.desc)") }

    private func showTimedHint(_ text: String) {
        hintText = text
        hintGen += 1
        let gen = hintGen
        withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.2)) { showHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard gen == hintGen else { return }
            withAnimation(controller.reduceMotion ? nil : .easeOut(duration: 0.6)) { showHint = false }
        }
    }
}
