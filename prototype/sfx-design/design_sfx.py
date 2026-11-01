"""捏捏史萊姆的音效設計（離線產生 wav，不是 app 裡即時合成）。

2026-11-01 多米：史萊姆不是真實存在的，要 Agent 配音。10-31 放棄的是 app 裡即時算的合成音（難聽）；
這裡在電腦上一段一段做好，app 播的時候才依物理參數調音量、音高、濾波。

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
OURS = re.compile(r'^(press|pull|release|rub|settle)-.*\.wav$')


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


# (類別, 層, 產生函式, 段數)。段數 × 層數 × 浮音高，組合比 v1 的「一類 8 段」多上百倍
LAYERS = [
    ('press', 'body', press_body, 6), ('press', 'wet', press_wet, 6), ('press', 'air', press_air, 6),
    ('release', 'air', release_air, 8), ('release', 'wet', release_wet, 6), ('release', 'body', release_body, 5),
    ('pull', 'loop', pull_loop, 2), ('pull', 'strand', pull_strand, 10),
    ('rub', 'loop', rub_loop, 3),
    ('settle', 'bubble', settle_bubble, 10), ('settle', 'hiss', settle_hiss, 3),
]


def speaker_ratio(y):
    """300 Hz 以上的能量佔比：手機喇叭大概只放得出這部分。"""
    spec = np.abs(np.fft.rfft(y)) ** 2
    f = np.fft.rfftfreq(len(y), 1 / SR)
    return float(spec[f >= 300].sum() / (spec.sum() or 1))


def main():
    preview = '--preview' in sys.argv
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
            print(f'  {kind:7s} {layer:6s} 喇叭頻段佔比 {min(r):.2f} 到 {max(r):.2f}', '⚠' if min(r) < 0.6 else '')
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
