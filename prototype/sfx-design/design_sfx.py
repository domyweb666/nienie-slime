"""捏捏史萊姆的音效設計（離線產生 wav，不是 app 裡即時合成）。

2026-11-01 多米：史萊姆不是真實存在的，要 Agent 配音。10-31 放棄的是 app 裡即時算的合成音（難聽）；
這裡在電腦上一段一段做好，app 播的時候才依物理參數調音量、音高、濾波。

v3（2026-11-02，多米 build 77：配音刺耳，要 ASMR 紓壓型）：層與檔名不變，每層換成起音慢、小聲、低通、濕細碎的版本（見下面 v3 那段）。
`--v2` 把舊的 v2 組寫到 prototype/web/sfx/v2/（只給試聽頁對照）。

v2（2026-11-01 下午，分層版）：一個動作不再是「一類一檔」，拆成幾層，每層獨立隨機挑、獨立浮音高，
app 依力道決定哪幾層響、各多大聲。對應表在 `.uiux/04-手感/音效參數對應-暫定.md`。

  press   按下去：body 肉體感的「噗」／wet 被擠壓的濕聲／air 被擠出去的一顆氣泡
  release 放手：  body 彈回去的份量／wet 拍回自己的濕拍／air 主角「啵」
  pull    拉：    loop 連續的黏絲底噪（拉越長 app 把它調越高越亮）／strand 細絲一根根斷掉的小聲
  rub     揉：    loop 咕啾咕啾的循環
  settle  餘韻：  bubble 放手後冒的小氣泡／hiss 壓久了放開、空氣回填的一聲很小的嘶

為 iPhone 喇叭設計：喇叭 250 Hz 以下幾乎出不來，所以「噗」的厚度不靠低頻，靠 200 Hz 左右的基音加飽和
產生的 400 到 900 Hz 諧波，再加一小段中頻的悶響（thock）。每段最後都切掉 120 Hz 以下（喇叭放不出，只會吃掉音量）。
`--preview` 會印出每段「300 Hz 以上的能量佔比」，低於 0.6 的標 ⚠（喇叭上會變小聲、變空）。

用法：python design_sfx.py            產生全部，寫進 prototype/web/sfx/ 與 ios/NieNie/Resources/，更新兩邊的 manifest.json，
                                     並刪掉兩邊不在 manifest 裡的舊 wav（只刪 press/pull/release/rub/settle 開頭的）
      python design_sfx.py --preview  另外畫每層的波形與頻譜到 prototype/sfx-design/preview/（Agent 自己檢查用）
每次產生結果都一樣（固定亂數種子），改參數後重跑即可。
"""
import json
import os
import re
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt, sosfilt_zi

SR = 48000  # iOS 端的音訊引擎是 48k，直接對上不用轉
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT_DIRS = [os.path.join(ROOT, 'prototype', 'web', 'sfx'), os.path.join(ROOT, 'ios', 'NieNie', 'Resources')]
OURS = re.compile(r'^(press|pull|release|rub|settle|voice)-.*\.wav$')


# ---------- 積木 ----------

def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def band(x, lo, hi, order=2):
    sos = butter(order, [lo, hi], btype='band', fs=SR, output='sos')
    return sosfilt(sos, x)


def lowpass(x, fc, order=2):
    return sosfilt(butter(order, fc, btype='low', fs=SR, output='sos'), x)


def highpass(x, fc, order=2):
    return sosfilt(butter(order, fc, btype='high', fs=SR, output='sos'), x)


def sweep_band(x, f0, f1, q=3.0, chunk=0.008, curve=None):
    """共鳴頻率從 f0 滑到 f1 的帶通（分小段換係數，濾波狀態接續，聽起來是連續的滑音）。
    curve(p) 可以換掉預設的等比滑動，p 是 0 到 1 的進度，回傳 0 到 1。"""
    n = len(x)
    out = np.zeros(n)
    step = int(chunk * SR)
    zi = None
    for s in range(0, n, step):
        e = min(n, s + step)
        p = (s + e) / 2 / n
        if curve:
            p = curve(p)
        fc = f0 * (f1 / f0) ** p
        bw = fc / q
        sos = butter(2, [max(30, fc - bw / 2), min(SR / 2 - 100, fc + bw / 2)], btype='band', fs=SR, output='sos')
        if zi is None:
            zi = sosfilt_zi(sos) * 0
        out[s:e], zi = sosfilt(sos, x[s:e], zi=zi)
    return out


def env_ad(n, attack, decay):
    """attack 秒線性上升，之後時間常數 decay 秒的指數下降。"""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-np.maximum(0, t - attack) / decay)
    return a * d


def bubble(f0, rise, tau, dur):
    """氣泡聲（Minnaert 共振）：一個音高往上滑的衰減正弦。rise＝滑到幾倍，tau＝衰減時間常數。"""
    t = t_axis(dur)
    f = f0 * (1 + (rise - 1) * (1 - np.exp(-t / (tau * 0.8))))
    ph = 2 * np.pi * np.cumsum(f) / SR
    a = np.exp(-t / tau) * np.clip(t / 0.0015, 0, 1)
    return np.sin(ph) * a


def thump(f0, f1, tau, dur):
    """悶擊：音高從 f0 往下掉到 f1 的正弦，很快衰減。"""
    t = t_axis(dur)
    f = f1 + (f0 - f1) * np.exp(-t / (tau * 0.6))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t / tau) * np.clip(t / 0.002, 0, 1)


def phantom(f0, f1, tau, dur, weights=(0.1, 0.55, 1.0, 0.75, 0.5, 0.3)):
    """缺基音的悶擊：音高從 f0 掉到 f1，但基音只留一點點，能量放在 2 到 5 倍諧波。
    手機喇叭放不出 150 Hz，耳朵聽到 300、450、600… 會自己補出 150 的音高，聽起來還是低、還是有份量。"""
    t = t_axis(dur)
    f = f1 + (f0 - f1) * np.exp(-t / (tau * 0.6))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = sum(w * np.sin((h + 1) * ph) * np.exp(-t / (tau * (1 - 0.12 * h))) for h, w in enumerate(weights))
    return x * np.clip(t / 0.002, 0, 1)


def sat(x, drive):
    """軟飽和：把基音推出 2、3 倍的諧波，手機喇叭放不出基音也聽得到「有份量」。"""
    return np.tanh(x * drive) / np.tanh(drive)


def place(dst, src, at):
    i = int(at * SR)
    if i >= len(dst):
        return
    e = min(len(dst), i + len(src))
    dst[i:e] += src[:e - i]


def fade(x, fin=0.002, fout=0.03):
    n = len(x)
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[n - b:] *= np.linspace(1, 0, b) ** 2
    return x


def norm(x, peak_db):
    p = np.max(np.abs(x)) or 1
    return x / p * 10 ** (peak_db / 20)


def finish(x, lp, peak_db, fin=0.001, fout=0.03):
    """每段最後一道：低通、切 120 Hz 以下、淡入淡出、拉到指定峰值。"""
    x = highpass(lowpass(x, lp), 120)
    return norm(fade(x, fin, fout), peak_db)


def loopify(x, loop, xf):
    """做 loop+xf 秒的素材，最後 xf 秒等功率交叉淡化接回開頭，成為 loop 秒的無縫循環。"""
    a, xn = int(loop * SR), int(xf * SR)
    w = np.linspace(0, 1, xn)
    head = x[:xn] * np.sqrt(w) + x[a:a + xn] * np.sqrt(1 - w)
    return np.concatenate([head, x[xn:a]])


# ---------- 按 press ----------
# 三層的峰值刻意不一樣：body 跟 wet 是主體，air 是點綴。app 再依力道乘上各層音量。

def press_body(rng, k):
    """肉體感的「噗」：聽起來 130 到 200 Hz 往下掉的悶音（缺基音做法，能量在 300 到 900 Hz）；加一小段中頻的悶響。
    第一版用真的 200 Hz 正弦加飽和，量過 9 成以上能量在 300 Hz 以下，手機喇叭上幾乎沒聲音。"""
    dur = 0.2
    n = int(dur * SR)
    x = 0.8 * phantom(rng.uniform(170, 210), rng.uniform(110, 130), rng.uniform(0.024, 0.034), dur)
    thock = band(rng.standard_normal(n), 280, 900) * env_ad(n, 0.002, rng.uniform(0.012, 0.02))
    x += 0.5 * thock / (np.max(np.abs(thock)) or 1)
    return finish(x, 2600, -3, fout=0.04)


def press_wet(rng, k):
    """被擠壓的濕聲：共鳴從高往低滑（被壓扁、空間變小），加一串很密的小濕響。"""
    dur = 0.18
    n = int(dur * SR)
    x = sweep_band(rng.standard_normal(n), rng.uniform(1200, 1600), rng.uniform(400, 520), q=3.5) * env_ad(n, 0.004, rng.uniform(0.04, 0.06))
    x = 0.9 * x / (np.max(np.abs(x)) or 1)
    for j in range(rng.integers(3, 6)):
        place(x, rng.uniform(0.12, 0.25) * bubble(rng.uniform(700, 1400), rng.uniform(1.2, 1.5), rng.uniform(0.003, 0.006), 0.03),
              0.004 + j * rng.uniform(0.006, 0.012))
    return finish(x, 4200, -3)


def press_air(rng, k):
    """被擠出去的空氣：一顆小氣泡，偶爾跟一顆更小的。app 會晚 15 到 45 毫秒才放，不跟按下那一下黏在一起。"""
    dur = 0.16
    x = np.zeros(int(dur * SR))
    place(x, bubble(rng.uniform(380, 640), rng.uniform(1.4, 1.9), rng.uniform(0.016, 0.026), 0.12), 0)
    if k % 2:
        place(x, 0.5 * bubble(rng.uniform(700, 1000), 1.6, 0.01, 0.05), rng.uniform(0.03, 0.06))
    return finish(x, 4500, -4)


# ---------- 放手 release ----------

def release_air(rng, k):
    """主角「啵」：音高往上滑的氣泡。有的大顆低沉、有的小顆清脆；加一點飽和讓 250 Hz 的基音在喇叭上也聽得到。"""
    dur = 0.26
    x = np.zeros(int(dur * SR))
    size = k % 4                      # 0 最大顆 ... 3 最小顆，輪流
    f0 = [rng.uniform(210, 250), rng.uniform(250, 300), rng.uniform(300, 360), rng.uniform(360, 440)][size]
    tau = [0.045, 0.038, 0.032, 0.026][size] * rng.uniform(0.9, 1.1)
    place(x, sat(bubble(f0, rng.uniform(2.0, 2.6), tau, 0.25), 1.8), 0.002)
    return finish(x, 5000, -1, fout=0.05)


def release_wet(rng, k):
    """拍回自己的濕拍：很短的寬頻濕聲，加一小段共鳴往上開（彈開、空間變大）。"""
    dur = 0.12
    n = int(dur * SR)
    m = int(0.03 * SR)
    x = np.zeros(n)
    slap = band(rng.standard_normal(m), 600, 2800) * env_ad(m, 0.001, rng.uniform(0.005, 0.008))
    place(x, slap / (np.max(np.abs(slap)) or 1), 0)
    op = sweep_band(rng.standard_normal(n), rng.uniform(600, 800), rng.uniform(1500, 2000), q=4) * env_ad(n, 0.003, rng.uniform(0.02, 0.03))
    place(x, 0.6 * op / (np.max(np.abs(op)) or 1), 0.002)
    return finish(x, 5500, -3)


def release_body(rng, k):
    """彈回去的份量：比按的 body 再低一點、短一點，只有重的放手才會加這層。"""
    dur = 0.18
    x = phantom(rng.uniform(160, 190), rng.uniform(115, 130), rng.uniform(0.026, 0.036), dur, (0.08, 0.5, 1.0, 0.8, 0.55, 0.35))
    return finish(x, 2400, -3, fout=0.05)


# ---------- 拉 pull ----------

def pull_loop(rng, k):
    """連續的黏絲底噪，2 秒無縫循環。兩個窄共鳴（大約 650 與 1200 Hz）中心慢慢晃，加很密很小的細碎黏響。
    app 拉越長把它播越快（音高升）、低通開越大（越亮），拉的速度決定音量：拉著不動就幾乎沒聲音。"""
    loop, xf = 2.0, 0.4
    dur = loop + xf
    n = int(dur * SR)
    t = np.arange(n) / SR
    wob = lambda: (lambda ph, fr: (lambda p: 0.5 + 0.5 * np.sin(2 * np.pi * fr * p * dur + ph)))(rng.uniform(0, 6), rng.uniform(0.6, 1.4))
    a = sweep_band(rng.standard_normal(n), 560, 760, q=9, curve=wob())
    b = sweep_band(rng.standard_normal(n), 1050, 1350, q=8, curve=wob())
    x = a / np.std(a) + 0.6 * b / np.std(b)
    x *= 0.75 + 0.25 * np.sin(2 * np.pi * rng.uniform(2.5, 4.0) * t + rng.uniform(0, 6))   # 一點點不均勻的起伏，不像穩定的風聲
    x *= 0.08
    tt = 0.0
    while tt < dur - 0.03:
        place(x, rng.uniform(0.05, 0.12) * bubble(rng.uniform(900, 2200), rng.uniform(1.2, 1.5), rng.uniform(0.002, 0.004), 0.02), tt)
        tt += rng.exponential(1 / 45)
    x = highpass(lowpass(x, 4000), 200)
    return norm(loopify(x, loop, xf), -8)


def pull_strand(rng, k):
    """一根細絲斷掉：很小、很短、有音高的「滴」。拉越長 app 放越密、音高越高。
    第一版的黏絲斷裂用尖的喀聲，頻譜整條拉滿像雜訊；這裡用極短的上滑氣泡。"""
    dur = 0.05
    x = np.zeros(int(dur * SR))
    place(x, bubble(rng.uniform(1000, 2200), rng.uniform(1.2, 1.6), rng.uniform(0.0025, 0.005), 0.04), 0)
    if k % 3 == 0:
        place(x, 0.5 * bubble(rng.uniform(1500, 2600), 1.3, 0.002, 0.02), rng.uniform(0.006, 0.012))
    return finish(x, 6000, -4, fout=0.01)


# ---------- 揉 rub ----------

def rub_loop(rng, k):
    """持續揉：3 秒無縫循環，咕啾咕啾的連續濕聲。底噪只留很小（第一版 0.35 整片雜訊像刮風）。"""
    loop, xf = 3.0, 0.6
    dur = loop + xf
    n = int(dur * SR)
    t = np.arange(n) / SR
    base = band(rng.standard_normal(n), 250, 900)
    squeeze = 0.55 + 0.45 * np.sin(2 * np.pi * rng.uniform(1.6, 2.4) * t + rng.uniform(0, 6)) ** 2
    x = 0.1 * base / np.std(base) * 0.3 * squeeze
    tt = 0.02
    while tt < dur - 0.1:
        m = int(0.09 * SR)
        sq = sweep_band(rng.standard_normal(m), rng.uniform(1000, 1400), rng.uniform(380, 520), q=3.5) * env_ad(m, 0.006, rng.uniform(0.02, 0.035))
        place(x, rng.uniform(0.3, 0.55) * sq / (np.max(np.abs(sq)) or 1) * 0.35, tt)
        if rng.random() < 0.85:
            place(x, rng.uniform(0.18, 0.35) * bubble(rng.uniform(300, 700), rng.uniform(1.3, 1.9), rng.uniform(0.012, 0.025), 0.08),
                  tt + rng.uniform(0.01, 0.05))
        tt += rng.uniform(0.1, 0.25)
    x = highpass(lowpass(x, 3500), 150)
    return norm(loopify(x, loop, xf), -6)


# ---------- 餘韻 settle ----------

def settle_bubble(rng, k):
    """放手後冒的小氣泡：比 air 更小更輕，app 在放手後 0.12 到 0.7 秒之間隨機放 1 到 3 顆。"""
    dur = 0.08
    x = np.zeros(int(dur * SR))
    place(x, bubble(rng.uniform(500, 1300), rng.uniform(1.3, 1.8), rng.uniform(0.006, 0.014), 0.07), 0)
    return finish(x, 5000, -6, fout=0.02)


def settle_hiss(rng, k):
    """壓久了放開，空氣慢慢回填：0.3 秒很小的嘶，2 到 5 kHz，慢進慢出。"""
    dur = 0.32
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = sweep_band(rng.standard_normal(n), rng.uniform(1800, 2400), rng.uniform(3600, 4800), q=1.6)
    x *= np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5
    return finish(x, 7000, -12, fin=0.01, fout=0.06)


# ---------- v3 ASMR 紓壓版（2026-11-02，多米 build 77：配音刺耳，要 ASMR 紓壓型） ----------
# 量過 v2：按、放手、細絲從開始到最大聲只有 2 到 12 毫秒（一顆顆的喀），峰值 −1 到 −4 dB，重心擠在 500 到 1800 Hz（手機喇叭最突出的一段），
# 冒泡是正弦波的「啵」。v3：起音 6 到 40 毫秒（升餘弦，不是直線），峰值壓到 −12 dB 上下，低通多半在 1.6 到 2.6 kHz，
# 主體改成濕的細碎聲（很多很小的黏液氣泡破掉、手指慢慢壓黏土那種），拿掉卡通的啵，加一點點很短的空間感。層與檔名跟 v2 一樣，播放程式不用改。

def soft_env(n, attack, decay):
    """升餘弦起音 attack 秒，之後時間常數 decay 秒的指數下降。直線起音在 2 毫秒內一樣會喀一聲。"""
    t = np.arange(n) / SR
    a = np.where(t < attack, 0.5 - 0.5 * np.cos(np.pi * np.clip(t / max(attack, 1e-4), 0, 1)), 1.0)
    return a * np.exp(-np.maximum(0, t - attack) / decay)


def grains(n, rng, rate, lo, hi, amp, t0=0.0, t1=None):
    """細碎的黏響：每秒 rate 顆、每顆 1.5 到 4 毫秒的帶通雜訊，漢寧窗包起來（沒有硬邊）。ASMR 黏土的「細細的濕」靠這個。"""
    x = np.zeros(n)
    t1 = n / SR if t1 is None else t1
    tt = t0
    while tt < t1:
        m = int(rng.uniform(0.0015, 0.004) * SR)
        g = band(rng.standard_normal(m + 64), lo, hi)[64:] * np.hanning(m)
        place(x, rng.uniform(0.3, 1.0) * amp * g / (np.max(np.abs(g)) or 1), tt)
        tt += rng.exponential(1 / rate)
    return x


def room(x, rng, mix=0.12, tail=0.09):
    """很短的空間感：跟一段 tail 秒指數衰減的低通雜訊卷積，混一點點進去，聲音像貼在耳邊、不是乾乾的。"""
    m = int(tail * 1.6 * SR)
    ir = lowpass(rng.standard_normal(m), 2500) * np.exp(-np.arange(m) / SR / tail * 3)
    wet = np.convolve(x, ir)[:len(x)]
    return x + mix * wet / (np.max(np.abs(wet)) or 1) * (np.max(np.abs(x)) or 1)


def finish_a(x, lp, peak_db, fin=0.004, fout=0.05):
    x = highpass(lowpass(x, lp, 2), 150)
    return norm(fade(x, fin, fout), peak_db)


def press_body_a(rng, k):
    """軟軟的「嗯」一下：缺基音的悶音，起音 12 毫秒，比 v2 低、長、小聲。"""
    dur = 0.3
    n = int(dur * SR)
    x = phantom(rng.uniform(150, 180), rng.uniform(100, 115), rng.uniform(0.045, 0.06), dur, (0.1, 0.6, 1.0, 0.6, 0.3, 0.12))
    x *= soft_env(n, 0.012, 1e9)
    return finish_a(x, 1600, -12, fout=0.08)


def press_wet_a(rng, k):
    """手指慢慢壓進黏土：共鳴從 900 Hz 慢慢滑到 300（空間被壓小），起音 20 毫秒；前 0.15 秒加細碎的濕響。"""
    dur = 0.32
    n = int(dur * SR)
    x = sweep_band(rng.standard_normal(n), rng.uniform(800, 1000), rng.uniform(280, 340), q=2.5) * soft_env(n, 0.02, rng.uniform(0.07, 0.1))
    x = x / (np.max(np.abs(x)) or 1)
    x += grains(n, rng, rng.uniform(90, 140), 1100, 2600, 0.18, 0.01, 0.17) * soft_env(n, 0.02, 0.08)
    return finish_a(room(x, rng), 2600, -12, fout=0.08)


def press_air_a(rng, k):
    """被擠出去的一點空氣：很輕的「呼」，帶通雜訊，起音 30 毫秒（v2 是一顆正弦氣泡）。"""
    dur = 0.26
    n = int(dur * SR)
    x = band(rng.standard_normal(n), rng.uniform(300, 400), rng.uniform(1100, 1400)) * soft_env(n, 0.03, rng.uniform(0.05, 0.08))
    return finish_a(x, 1800, -18, fin=0.01, fout=0.08)


def release_air_a(rng, k):
    """放手的「噗」：圓圓的、往上滑一點點的軟泡（滑 1.25 倍，v2 滑 2 到 2.6 倍像卡通），起音 6 毫秒、不加飽和，加一點低通雜訊當肉。"""
    dur = 0.3
    n = int(dur * SR)
    size = k % 4
    f0 = [rng.uniform(180, 210), rng.uniform(210, 250), rng.uniform(250, 290), rng.uniform(290, 330)][size]   # 聽起來的音高（實際能量在 2 倍上下）
    tau = [0.06, 0.052, 0.045, 0.038][size] * rng.uniform(0.9, 1.1)
    # 第一版用 f0 本身的正弦泡加 900 Hz 低通雜訊，量過有一段 300 Hz 以上只佔 2%，手機上聽不到：改成泡在兩倍音高、肉用 1.6 到 2.4 倍往上開的共鳴
    x = bubble(2 * f0, rng.uniform(1.18, 1.3), tau, dur) * soft_env(n, 0.006, 1e9)
    body = sweep_band(rng.standard_normal(n), 1.6 * f0, 2.4 * f0, q=4) * soft_env(n, 0.008, tau * 0.7)
    x = 0.6 * x / (np.max(np.abs(x)) or 1) + body / (np.max(np.abs(body)) or 1)
    return finish_a(room(x, rng, 0.1), 2000, -12, fout=0.08)


def release_wet_a(rng, k):
    """拍回自己：很輕的濕「啪」，300 到 1500 Hz，起音 6 毫秒，後面跟幾顆細碎的濕響。"""
    dur = 0.2
    n = int(dur * SR)
    x = band(rng.standard_normal(n), 300, 1500) * soft_env(n, 0.006, rng.uniform(0.025, 0.035))
    x = x / (np.max(np.abs(x)) or 1)
    x += grains(n, rng, 70, 1000, 2400, 0.14, 0.01, 0.1) * soft_env(n, 0.01, 0.06)
    return finish_a(room(x, rng), 2400, -14, fout=0.06)


def release_body_a(rng, k):
    """重的放手才有的份量：比 press_body_a 再短一點、再小一點。"""
    dur = 0.24
    n = int(dur * SR)
    x = phantom(rng.uniform(150, 170), rng.uniform(105, 115), rng.uniform(0.035, 0.05), dur, (0.08, 0.55, 1.0, 0.6, 0.3, 0.1))
    x *= soft_env(n, 0.01, 1e9)
    return finish_a(x, 1500, -14, fout=0.07)


def pull_loop_a(rng, k):
    """被拉開的黏液：3 秒無縫循環，低的濕底（250 到 700 Hz 的共鳴慢慢晃）加稀稀的細碎黏響。app 照舊依拉長調音高、低通、音量。"""
    loop, xf = 3.0, 0.6
    dur = loop + xf
    n = int(dur * SR)
    t = np.arange(n) / SR
    wob = lambda: (lambda ph, fr: (lambda p: 0.5 + 0.5 * np.sin(2 * np.pi * fr * p * dur + ph)))(rng.uniform(0, 6), rng.uniform(0.4, 0.9))
    a = sweep_band(rng.standard_normal(n), 260, 480, q=4, curve=wob())
    b = sweep_band(rng.standard_normal(n), 600, 900, q=5, curve=wob())
    x = a / np.std(a) + 0.4 * b / np.std(b)
    x *= 0.7 + 0.3 * np.sin(2 * np.pi * rng.uniform(0.8, 1.4) * t + rng.uniform(0, 6))
    x *= 0.1
    x += grains(n, rng, 22, 1000, 2400, 0.12)
    x = highpass(lowpass(x, 2200), 180)
    return norm(loopify(x, loop, xf), -14)


def pull_strand_a(rng, k):
    """一根細絲斷掉：很輕的「滋」，3 毫秒升起、12 毫秒退，沒有音高（v2 是上滑的「滴」）。"""
    dur = 0.06
    n = int(dur * SR)
    x = band(rng.standard_normal(n), rng.uniform(900, 1200), rng.uniform(2000, 2400)) * soft_env(n, 0.003, rng.uniform(0.008, 0.014))
    return finish_a(x, 2800, -18, fin=0.002, fout=0.02)


def rub_loop_a(rng, k):
    """持續揉：3 秒無縫循環，一下一下慢慢的擠壓聲（起音 25 毫秒），間隔 0.15 到 0.3 秒，每下帶一點細碎濕響。"""
    loop, xf = 3.0, 0.6
    dur = loop + xf
    n = int(dur * SR)
    x = 0.03 * band(rng.standard_normal(n), 200, 600)
    tt = 0.02
    while tt < dur - 0.15:
        m = int(0.16 * SR)
        sq = sweep_band(rng.standard_normal(m), rng.uniform(650, 850), rng.uniform(230, 300), q=2.5) * soft_env(m, 0.025, rng.uniform(0.04, 0.06))
        sq = sq / (np.max(np.abs(sq)) or 1)
        sq += grains(m, rng, 80, 1000, 2400, 0.15, 0.005, 0.08) * soft_env(m, 0.02, 0.05)
        place(x, rng.uniform(0.35, 0.6) * sq, tt)
        tt += rng.uniform(0.15, 0.3)
    x = highpass(lowpass(room(x, rng, 0.1), 2200), 150)
    return norm(loopify(x, loop, xf), -12)


def settle_bubble_a(rng, k):
    """放手後冒的小泡：低、小、圓（350 到 700 Hz，只滑 1.15 倍，起音 4 毫秒）。"""
    dur = 0.1
    n = int(dur * SR)
    x = bubble(rng.uniform(350, 700), rng.uniform(1.1, 1.2), rng.uniform(0.012, 0.02), dur) * soft_env(n, 0.004, 1e9)
    return finish_a(x, 2000, -20, fin=0.002, fout=0.03)


def settle_hiss_a(rng, k):
    """壓久了放開，空氣慢慢回填：更小、更低的「嘶」（700 到 2200 Hz，v2 是 2 到 5 kHz）。"""
    dur = 0.4
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = band(rng.standard_normal(n), 700, 2200) * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2
    return finish_a(x, 3000, -24, fin=0.02, fout=0.08)


# ---------- v2.22 它的聲音（E1，多米 build 77：還是沒有互動的感覺；拉力互動聲音黏液提案第二節） ----------
# 沒有字的小聲音，像小動物在喉嚨裡哼：聲帶脈衝（諧波 −12 dB/八度）加一點氣聲，過兩三個共振峰（嘴巴的形狀），音高照每種情緒畫一條線。
# 基音 330 到 600 Hz（小動物，而且手機喇叭放得出來），低通 2.4 kHz、起音 15 到 30 毫秒、峰值 −16 dB 上下：跟 v3 音效一樣是貼耳的輕聲。
# app 依印象調音高（熟的高一點、長一點，戒的低、短），所以每種只做 4 到 6 段。

VOWEL = {   # 共振峰（Hz、相對大小），小動物的嘴比較小，全部往上推一點
    'm': [(320, 1.0), (1150, 0.25)],                 # 閉嘴哼
    'u': [(380, 1.0), (950, 0.5), (2300, 0.08)],
    'o': [(520, 1.0), (980, 0.6), (2500, 0.08)],
    'i': [(330, 1.0), (2100, 0.35), (2900, 0.1)],
}


def glottal(f0_curve, breath=0.08, jitter=0.006, rng=None):
    """聲帶：照音高曲線產生 30 個諧波（每八度 −12 dB），加一點點音高抖動和氣聲。f0_curve 是每個樣本的 Hz。"""
    n = len(f0_curve)
    f = f0_curve * (1 + jitter * lowpass(rng.standard_normal(n), 12))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.zeros(n)
    for h in range(1, 31):
        amp = 1.0 / h ** 2
        mask = (h * f) < 4000
        x += amp * np.sin(h * ph) * mask
    x += breath * band(rng.standard_normal(n), 800, 3500)
    return x


def mouth(x, vowel, vowel2=None):
    """過共振峰；有 vowel2 就從 vowel 慢慢滑到 vowel2（嘴型在變）。"""
    a = sum(g * band(x, max(80, fc * 0.85), fc * 1.15) for fc, g in VOWEL[vowel])
    if vowel2 is None:
        return a
    b = sum(g * band(x, max(80, fc * 0.85), fc * 1.15) for fc, g in VOWEL[vowel2])
    w = np.linspace(0, 1, len(x))
    return a * (1 - w) + b * w


def contour(dur, pts):
    """音高曲線：pts 是 [(時間比例 0..1, Hz)]，中間用平滑插值。"""
    n = int(dur * SR)
    t = np.linspace(0, 1, n)
    ts, fs = zip(*pts)
    return np.interp(t, ts, fs)


def hum(rng, dur, pts, vowel, vowel2=None, attack=0.02, decay_tail=0.08, vib=0.0, breath=0.08):
    n = int(dur * SR)
    f0 = contour(dur, pts)
    if vib:
        f0 = f0 * (1 + vib * np.sin(2 * np.pi * rng.uniform(4.5, 6) * np.arange(n) / SR))
    x = mouth(glottal(f0, breath, rng=rng), vowel, vowel2)
    t = np.arange(n) / SR
    env = np.where(t < attack, 0.5 - 0.5 * np.cos(np.pi * t / attack), 1.0)
    env *= np.where(t > dur - decay_tail, np.clip((dur - t) / decay_tail, 0, 1) ** 1.5, 1.0)
    return x * env


def voice_poke(rng, k):
    """被戳一下：「噗」，0.12 秒，音高很快往下掉，前面一點點軟的氣音。"""
    f = rng.uniform(500, 580)
    x = hum(rng, 0.13, [(0, f), (0.3, f * 0.92), (1, f * 0.75)], 'u', attack=0.012, decay_tail=0.06, breath=0.12)
    puff = lowpass(rng.standard_normal(len(x)), 1500) * soft_env(len(x), 0.004, 0.015)
    x = x / (np.max(np.abs(x)) or 1) + 0.25 * puff / (np.max(np.abs(puff)) or 1)
    return finish_a(x, 2400, -16, fin=0.004, fout=0.04)


def voice_mmm(rng, k):
    """被摸得舒服：「嗯～」，0.6 秒閉嘴哼，音高先微微上去再慢慢下來，有一點點顫音。"""
    f = rng.uniform(340, 400)
    x = hum(rng, rng.uniform(0.55, 0.7), [(0, f * 0.95), (0.25, f * 1.06), (1, f * 0.9)], 'm', attack=0.03, decay_tail=0.2, vib=0.012, breath=0.06)
    return finish_a(x, 2000, -16, fin=0.01, fout=0.1)


def voice_protest(rng, k):
    """被用力扯：「嗯嗯」，兩下短而有點緊的哼（諧波多一點），第二下高一點。"""
    f = rng.uniform(420, 480)
    a = hum(rng, 0.15, [(0, f), (1, f * 0.88)], 'u', attack=0.012, decay_tail=0.05, breath=0.1)
    b = hum(rng, 0.17, [(0, f * 1.08), (1, f * 0.9)], 'u', attack=0.012, decay_tail=0.07, breath=0.1)
    x = np.zeros(int(0.42 * SR))
    place(x, a, 0)
    place(x, b, rng.uniform(0.19, 0.23))
    return finish_a(sat(x / (np.max(np.abs(x)) or 1), 1.4), 2400, -16, fout=0.05)


def voice_happy(rng, k):
    """揉完放手、開心：「噗咿」，嘴型從 u 滑到 i，音高往上揚。"""
    f = rng.uniform(390, 440)
    x = hum(rng, rng.uniform(0.32, 0.4), [(0, f), (0.35, f * 1.05), (1, f * 1.38)], 'u', 'i', attack=0.015, decay_tail=0.1)
    return finish_a(x, 2400, -16, fout=0.08)


def voice_ask(rng, k):
    """伸偽足討摸、探你：「嗯？」，短短的閉嘴哼，尾巴往上問。"""
    f = rng.uniform(360, 410)
    x = hum(rng, rng.uniform(0.22, 0.28), [(0, f), (0.5, f * 1.02), (1, f * 1.32)], 'm', 'u', attack=0.02, decay_tail=0.06)
    return finish_a(x, 2200, -16, fout=0.06)


def voice_giggle(rng, k):
    """被搔癢：咯咯咯，4 到 6 下很短的「i」，一下比一下低一點，間隔 85 到 110 毫秒。"""
    m = int(rng.integers(4, 7))
    f = rng.uniform(540, 600)
    x = np.zeros(int((0.12 + m * 0.11) * SR))
    tt = 0.0
    for j in range(m):
        g = hum(rng, 0.06, [(0, f * (1 - 0.03 * j)), (1, f * (0.9 - 0.03 * j))], 'i', attack=0.008, decay_tail=0.03, breath=0.14)
        place(x, (1 - 0.08 * j) * g, tt)
        tt += rng.uniform(0.085, 0.11)
    return finish_a(x, 2200, -17, fout=0.05)


def voice_gulp(rng, k):
    """把黏液吸回去：「咕嚕」，低一點的哼（缺基音，手機也聽得到）加嘴型 o → u，後面一顆軟泡。"""
    f = rng.uniform(300, 340)
    x = hum(rng, 0.26, [(0, f), (0.4, f * 0.82), (1, f * 0.7)], 'o', 'u', attack=0.015, decay_tail=0.08)
    x = x / (np.max(np.abs(x)) or 1)
    place(x, 0.4 * bubble(rng.uniform(420, 560), 1.2, 0.02, 0.08) * soft_env(int(0.08 * SR), 0.004, 1e9), rng.uniform(0.15, 0.2))
    return finish_a(x, 2000, -15, fout=0.06)


def voice_hello(rng, k):
    """游到前面跟你打招呼：「嗯～嗯」，上去再下來的兩個音，像在叫你。"""
    f = rng.uniform(380, 430)
    a = hum(rng, 0.26, [(0, f), (1, f * 1.2)], 'm', 'u', attack=0.02, decay_tail=0.05)
    b = hum(rng, 0.3, [(0, f * 1.15), (1, f * 0.95)], 'u', attack=0.015, decay_tail=0.12, vib=0.01)
    x = np.zeros(int(0.62 * SR))
    place(x, a, 0)
    place(x, b, 0.27)
    return finish_a(x, 2300, -16, fout=0.1)


# (類別, 層, 產生函式, 段數)。段數 × 層數 × 浮音高，組合比 v1 的「一類 8 段」多上百倍。LAYERS_V2 是 v2（刺耳的那組，留著對照）
LAYERS_V2 = [
    ('press', 'body', press_body, 6), ('press', 'wet', press_wet, 6), ('press', 'air', press_air, 6),
    ('release', 'air', release_air, 8), ('release', 'wet', release_wet, 6), ('release', 'body', release_body, 5),
    ('pull', 'loop', pull_loop, 2), ('pull', 'strand', pull_strand, 10),
    ('rub', 'loop', rub_loop, 3),
    ('settle', 'bubble', settle_bubble, 10), ('settle', 'hiss', settle_hiss, 3),
]
LAYERS = [
    ('press', 'body', press_body_a, 6), ('press', 'wet', press_wet_a, 6), ('press', 'air', press_air_a, 6),
    ('release', 'air', release_air_a, 8), ('release', 'wet', release_wet_a, 6), ('release', 'body', release_body_a, 5),
    ('pull', 'loop', pull_loop_a, 2), ('pull', 'strand', pull_strand_a, 10),
    ('rub', 'loop', rub_loop_a, 3),
    ('settle', 'bubble', settle_bubble_a, 10), ('settle', 'hiss', settle_hiss_a, 3),
    ('voice', 'poke', voice_poke, 5), ('voice', 'mmm', voice_mmm, 4), ('voice', 'protest', voice_protest, 4), ('voice', 'happy', voice_happy, 4),
    ('voice', 'ask', voice_ask, 4), ('voice', 'giggle', voice_giggle, 4), ('voice', 'gulp', voice_gulp, 4), ('voice', 'hello', voice_hello, 3),
]


def speaker_ratio(y):
    """300 Hz 以上的能量佔比：手機喇叭大概只放得出這部分。"""
    spec = np.abs(np.fft.rfft(y)) ** 2
    f = np.fft.rfftfreq(len(y), 1 / SR)
    return float(spec[f >= 300].sum() / (spec.sum() or 1))


def attack_ms(y):
    """從開始到包絡最大的毫秒數（1 毫秒平滑）：v2 的按、放手只有 2 到 12 毫秒。"""
    e = np.convolve(np.abs(y), np.ones(48) / 48, 'same')
    return float(np.argmax(e) / SR * 1000)


def main():
    preview = '--preview' in sys.argv
    global LAYERS, OUT_DIRS
    if '--v2' in sys.argv:   # 舊的 v2 組，只寫到網頁的 sfx/v2/（試聽頁切換對照用）
        LAYERS, OUT_DIRS = LAYERS_V2, [os.path.join(ROOT, 'prototype', 'web', 'sfx', 'v2')]
    manifest = {'version': 2}
    clips = {}
    for li, (kind, layer, fn, count) in enumerate(LAYERS):
        manifest.setdefault(kind, {})[layer] = []
        for k in range(count):
            rng = np.random.default_rng(1000 * (li + 1) + k)
            y = fn(rng, k)
            name = f'{kind}-{layer}-{k + 1:02d}.wav'
            manifest[kind][layer].append(name)
            clips[name] = y
    for d in OUT_DIRS:
        os.makedirs(d, exist_ok=True)
        for old in os.listdir(d):
            if OURS.match(old) and old not in clips:
                os.remove(os.path.join(d, old))
        for name, y in clips.items():
            wavfile.write(os.path.join(d, name), SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))
        with open(os.path.join(d, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print('wrote', len(clips), 'clips to', len(OUT_DIRS), 'folders')
    if preview:
        for kind, layer, _, _ in LAYERS:
            names = [n for n in clips if n.startswith(f'{kind}-{layer}-')]
            r = [speaker_ratio(clips[n]) for n in names]
            a = [attack_ms(clips[n]) for n in names]
            pk = [20 * np.log10(np.max(np.abs(clips[n])) + 1e-9) for n in names]
            print(f'  {kind:7s} {layer:6s} 喇叭頻段佔比 {min(r):.2f} 到 {max(r):.2f}  起音 {min(a):4.0f} 到 {max(a):4.0f} ms  峰值 {max(pk):5.1f} dB', '⚠' if min(r) < 0.6 else '')
        draw_preview(clips)


def draw_preview(clips):
    """每層前 4 段：上面波形、下面頻譜（0 到 6 kHz，越亮越大聲；虛線是 300 Hz，喇叭大概只放得出線以上）。"""
    from PIL import Image, ImageDraw
    out = os.path.join(HERE, 'preview')
    os.makedirs(out, exist_ok=True)
    for old in os.listdir(out):
        if old.endswith('.png'):
            os.remove(os.path.join(out, old))
    W, Hw, Hs, gap = 300, 90, 140, 8
    fmax = 6000
    for kind, layer, _, _ in LAYERS:
        names = [n for n in clips if n.startswith(f'{kind}-{layer}-')][:4]
        img = Image.new('RGB', (len(names) * (W + gap), Hw + Hs + 20), (20, 20, 28))
        d = ImageDraw.Draw(img)
        for c, n in enumerate(names):
            y = clips[n]
            x0 = c * (W + gap)
            d.text((x0 + 4, 2), f'{n}  {len(y) / SR:.2f}s', fill=(220, 220, 220))
            step = max(1, len(y) // W)
            for px in range(W):
                seg = y[px * step:(px + 1) * step]
                if not len(seg):
                    break
                lo, hi = float(seg.min()), float(seg.max())
                d.line([(x0 + px, 14 + Hw / 2 - hi * Hw / 2), (x0 + px, 14 + Hw / 2 - lo * Hw / 2)], fill=(120, 200, 255))
            nfft, hop = 1024, max(1, len(y) // W)
            win = np.hanning(nfft)
            fmax_bin = int(fmax / (SR / nfft))
            for px in range(W):
                s0 = px * hop
                seg = y[s0:s0 + nfft]
                if len(seg) < nfft:
                    seg = np.pad(seg, (0, nfft - len(seg)))
                mag = np.abs(np.fft.rfft(seg * win))[:fmax_bin]
                db = 20 * np.log10(mag + 1e-6)
                v = np.clip((db + 20) / 60, 0, 1)
                for py in range(Hs):
                    b = v[int((Hs - 1 - py) / Hs * fmax_bin)]
                    if b > 0.02:
                        img.putpixel((x0 + px, 14 + Hw + 4 + py), (int(255 * b), int(140 * b * b), int(60 * b ** 3)))
            ly = 14 + Hw + 4 + Hs - 1 - int(300 / fmax * Hs)
            for px in range(0, W, 6):
                d.line([(x0 + px, ly), (x0 + px + 2, ly)], fill=(90, 230, 120))
        img.save(os.path.join(out, f'{kind}-{layer}.png'))
    print('preview in', out)


if __name__ == '__main__':
    main()
