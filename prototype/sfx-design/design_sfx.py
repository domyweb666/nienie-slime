"""捏捏史萊姆的音效設計（離線產生 wav，不是 app 裡即時合成）。

2026-11-01 多米：史萊姆不是真實存在的，要 Agent 配音。10-31 放棄的是 app 裡即時算的合成音（難聽）；
這裡改成在電腦上一段一段做好、每類做多個版本，app 照原本的錄音切片流程播（隨機挑、音高 ±8%、音量跟動作）。

四類，跟 sfx/manifest.json 一樣：
  press   手指按到身上：低沉的「噗」＋悶悶的濕聲＋一顆小氣泡
  pull    拉長的過程（每拉長約三分之一個身體響一段）：黏絲被拉開的嘶聲，共鳴越拉越高，加細碎的黏絲斷裂聲
  release 放手：「啵」（音高往上滑的氣泡聲）＋濕濕的拍擊＋幾顆小氣泡
  rub     持續揉，循環播：咕啾咕啾的連續濕聲，頭尾交叉淡化成無縫循環

用法：python design_sfx.py            產生全部，寫進 prototype/web/sfx/ 與 ios/NieNie/Resources/，更新兩邊的 manifest.json
      python design_sfx.py --preview  另外畫每段的波形與頻譜到 prototype/sfx-design/preview/（Agent 自己檢查用）
每次產生結果都一樣（固定亂數種子），改參數後重跑即可。
"""
import json
import os
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt, sosfilt_zi

SR = 48000  # iOS 端的音訊引擎是 48k，直接對上不用轉
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT_DIRS = [os.path.join(ROOT, 'prototype', 'web', 'sfx'), os.path.join(ROOT, 'ios', 'NieNie', 'Resources')]


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


def sweep_band(x, f0, f1, q=3.0, chunk=0.008):
    """共鳴頻率從 f0 滑到 f1 的帶通（分小段換係數，濾波狀態接續，聽起來是連續的滑音）。"""
    n = len(x)
    out = np.zeros(n)
    step = int(chunk * SR)
    zi = None
    for s in range(0, n, step):
        e = min(n, s + step)
        p = (s + e) / 2 / n
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


def bubble(f0, rise, tau, dur, rng=None):
    """氣泡聲（Minnaert 共振）：一個音高往上滑的衰減正弦。rise＝滑到幾倍，tau＝衰減時間常數。"""
    t = t_axis(dur)
    f = f0 * (1 + (rise - 1) * (1 - np.exp(-t / (tau * 0.8))))
    ph = 2 * np.pi * np.cumsum(f) / SR
    a = np.exp(-t / tau) * np.clip(t / 0.0015, 0, 1)
    return np.sin(ph) * a


def thump(f0, f1, tau, dur):
    """低沉的悶擊：音高從 f0 往下掉到 f1 的正弦，很快衰減。"""
    t = t_axis(dur)
    f = f1 + (f0 - f1) * np.exp(-t / (tau * 0.6))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t / tau) * np.clip(t / 0.002, 0, 1)


def click(fc, tau):
    """一顆黏絲斷掉的細碎聲：很短的衰減正弦。"""
    t = t_axis(tau * 6)
    return np.sin(2 * np.pi * fc * t) * np.exp(-t / tau)


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


# ---------- 四類 ----------

def make_press(rng, k):
    dur = 0.38
    n = int(dur * SR)
    x = np.zeros(n)
    heavy = 0.6 + 0.4 * (k % 3) / 2           # 輕、中、重三種力道輪流
    # 悶擊只當底，要短：太強太長會像打鼓（第一版看頻譜，低頻正弦拖了 0.15 秒蓋掉濕聲）
    place(x, 0.45 * heavy * thump(rng.uniform(120, 150), rng.uniform(55, 70), rng.uniform(0.025, 0.04), 0.2), 0)
    # 濕聲：共鳴從高往低滑（被壓扁、空間變小），加一串很密的小濕響
    sq = sweep_band(rng.standard_normal(n), rng.uniform(1100, 1500), rng.uniform(380, 520), q=3.5) * env_ad(n, 0.004, rng.uniform(0.045, 0.07))
    place(x, 0.8 * sq, 0.002)
    for j in range(rng.integers(3, 6)):
        place(x, rng.uniform(0.1, 0.22) * bubble(rng.uniform(700, 1400), rng.uniform(1.2, 1.5), rng.uniform(0.003, 0.006), 0.03), 0.004 + j * rng.uniform(0.006, 0.012))
    # 被壓出去的空氣：一顆小氣泡，在按下去後 25 到 60 毫秒
    place(x, 0.32 * bubble(rng.uniform(320, 520), rng.uniform(1.4, 1.9), rng.uniform(0.018, 0.03), 0.12), rng.uniform(0.025, 0.06))
    if k % 2:
        place(x, 0.18 * bubble(rng.uniform(600, 900), 1.6, 0.012, 0.06), rng.uniform(0.07, 0.11))
    x = lowpass(x, 3800)
    return norm(fade(x), -3)


def make_pull(rng, k):
    dur = rng.uniform(0.6, 0.8)
    n = int(dur * SR)
    noise = rng.standard_normal(n)
    # 黏絲被拉開的嘶聲：共鳴從低滑到高
    f0, f1 = rng.uniform(320, 420), rng.uniform(900, 1300)
    s = sweep_band(noise, f0, f1, q=rng.uniform(7, 10))
    t = np.arange(n) / SR
    e = np.clip(t / 0.07, 0, 1) * np.clip((dur - t) / 0.18, 0, 1) ** 1.5
    x = 0.9 * s * e
    # 第二層比較寬的嘶聲，讓它不像單一個音
    x += 0.18 * sweep_band(rng.standard_normal(n), f0 * 1.8, f1 * 1.6, q=2.0) * e
    # 細碎的黏絲斷裂：越拉越密。用很小的氣泡（有音高、會滑），不用尖的喀聲：第一版喀聲在頻譜上整條拉滿，聽起來是雜訊
    tt = 0.03
    while tt < dur - 0.05:
        p = tt / dur
        place(x, rng.uniform(0.06, 0.14) * bubble(rng.uniform(600, 1600), rng.uniform(1.2, 1.5), rng.uniform(0.003, 0.007), 0.04), tt)
        tt += rng.exponential(1 / (18 + 70 * p))
    # 偶爾一顆小氣泡被拉破
    for _ in range(rng.integers(1, 3)):
        place(x, 0.22 * bubble(rng.uniform(450, 800), 1.5, 0.015, 0.07), rng.uniform(0.15, dur - 0.15))
    x = highpass(lowpass(x, 3500), 120)
    return norm(fade(x, 0.004, 0.06), -5)


def make_release(rng, k):
    dur = 0.5
    n = int(dur * SR)
    x = np.zeros(n)
    heavy = [0.55, 0.75, 1.0][k % 3]
    # 主角：「啵」，音高往上滑的氣泡，重的比較低、比較長
    f0 = rng.uniform(170, 230) if heavy > 0.9 else rng.uniform(230, 330)
    place(x, 1.0 * bubble(f0, rng.uniform(2.0, 2.6), rng.uniform(0.03, 0.045) * (0.8 + 0.4 * heavy), 0.25), 0.004)
    # 濕濕的拍擊（彈回去碰到自己）
    slap = band(rng.standard_normal(int(0.03 * SR)), 600, 2600) * env_ad(int(0.03 * SR), 0.001, 0.006)
    place(x, 0.4 * heavy * slap, 0)
    # 低低的一下，讓重的那種有份量
    place(x, 0.45 * heavy * thump(95, 55, 0.04, 0.2), 0.002)
    # 跟著冒出來的小氣泡
    tt = rng.uniform(0.035, 0.06)
    for _ in range(rng.integers(2, 5)):
        place(x, rng.uniform(0.15, 0.35) * bubble(rng.uniform(480, 1100), rng.uniform(1.4, 2.0), rng.uniform(0.01, 0.02), 0.08), tt)
        tt += rng.uniform(0.025, 0.07)
    x = lowpass(x, 5000)
    return norm(fade(x, 0.001, 0.05), -1)


def make_rub(rng, k):
    """持續揉：做 3.6 秒，最後 0.6 秒交叉淡化接回開頭，成為 3 秒的無縫循環。"""
    loop, xf = 3.0, 0.6
    dur = loop + xf
    n = int(dur * SR)
    t = np.arange(n) / SR
    # 底：低沉的濕聲，用兩個慢速起伏模擬手掌一壓一放
    base = lowpass(rng.standard_normal(n), 700)
    squeeze = 0.55 + 0.45 * np.sin(2 * np.pi * rng.uniform(1.6, 2.4) * t + rng.uniform(0, 6)) ** 2
    x = 0.12 * base * squeeze   # 底噪壓低：第一版 0.35 頻譜整片都是雜訊，像刮風
    # 咕啾：每 0.1 到 0.25 秒一下小擠壓（悶濕聲＋一兩顆氣泡）
    tt = 0.02
    while tt < dur - 0.1:
        m = int(0.09 * SR)
        sq = sweep_band(rng.standard_normal(m), rng.uniform(1000, 1400), rng.uniform(350, 500), q=3.5) * env_ad(m, 0.006, rng.uniform(0.02, 0.035))
        place(x, rng.uniform(0.3, 0.55) * sq, tt)
        if rng.random() < 0.85:
            place(x, rng.uniform(0.18, 0.35) * bubble(rng.uniform(260, 700), rng.uniform(1.3, 1.9), rng.uniform(0.012, 0.025), 0.08), tt + rng.uniform(0.01, 0.05))
        tt += rng.uniform(0.1, 0.25)
    x = highpass(lowpass(x, 3500), 80)
    a, xn = int(loop * SR), int(xf * SR)
    w = np.linspace(0, 1, xn)
    head = x[:xn] * np.sqrt(w) + x[a:a + xn] * np.sqrt(1 - w)   # 等功率交叉淡化：循環接縫處音量不掉
    y = np.concatenate([head, x[xn:a]])
    return norm(y, -6)


KINDS = [('press', make_press, 8), ('pull', make_pull, 8), ('release', make_release, 10), ('rub', make_rub, 3)]


def main():
    preview = '--preview' in sys.argv
    manifest = {}
    clips = {}
    for kind, fn, count in KINDS:
        manifest[kind] = []
        for k in range(count):
            rng = np.random.default_rng(1000 * (KINDS.index((kind, fn, count)) + 1) + k)
            y = fn(rng, k)
            name = f'{kind}-{k + 1:02d}.wav'
            manifest[kind].append(name)
            clips[name] = y
    for d in OUT_DIRS:
        os.makedirs(d, exist_ok=True)
        for name, y in clips.items():
            wavfile.write(os.path.join(d, name), SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))
        with open(os.path.join(d, 'manifest.json'), 'w', encoding='utf-8', newline='\n') as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print('wrote', sum(len(v) for v in manifest.values()), 'clips to', len(OUT_DIRS), 'folders')
    if preview:
        draw_preview(clips)


def draw_preview(clips):
    """每類前 4 段：上面波形、下面頻譜（0 到 6 kHz，越亮越大聲）。用 PIL 畫，不另外裝繪圖套件。"""
    from PIL import Image, ImageDraw
    out = os.path.join(HERE, 'preview')
    os.makedirs(out, exist_ok=True)
    W, Hw, Hs, gap = 300, 90, 140, 8
    for kind in ['press', 'pull', 'release', 'rub']:
        names = [n for n in clips if n.startswith(kind)][:4]
        img = Image.new('RGB', (len(names) * (W + gap), Hw + Hs + 20), (20, 20, 28))
        d = ImageDraw.Draw(img)
        for c, n in enumerate(names):
            y = clips[n]
            x0 = c * (W + gap)
            d.text((x0 + 4, 2), n, fill=(220, 220, 220))
            step = max(1, len(y) // W)
            for px in range(W):
                seg = y[px * step:(px + 1) * step]
                if not len(seg):
                    break
                lo, hi = float(seg.min()), float(seg.max())
                d.line([(x0 + px, 14 + Hw / 2 - hi * Hw / 2), (x0 + px, 14 + Hw / 2 - lo * Hw / 2)], fill=(120, 200, 255))
            nfft, hop = 1024, max(1, len(y) // W)
            win = np.hanning(nfft)
            fmax_bin = int(6000 / (SR / nfft))
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
        img.save(os.path.join(out, f'{kind}.png'))
    print('preview in', out)


if __name__ == '__main__':
    main()
