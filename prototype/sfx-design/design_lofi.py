"""捏捏史萊姆的背景音樂：一首原創的 lofi，離線做好、可以無縫循環（2026-11-02，多米：背景要放 lofi 音樂）。

不是取樣、不是別人的曲子：和弦、鼓、貝斯、旋律全部在這裡用程式合成，所以沒有授權問題。品質像試聽版；
多米有自己的曲子（Suno 做的、買的授權音樂）就直接換掉輸出的檔案，播放的程式不用改。

  76 BPM，F 大調，8 小節一輪：Fmaj9 Em7 Dm9 Cmaj9 / B♭maj9 Am7 Gm9 C9
  40 小節約 126 秒：A 8 小節（電鋼琴＋貝斯＋輕的 hi-hat）、B 16 小節（全鼓＋旋律）、C 8 小節（全鼓）、D 8 小節（只剩 hi-hat 跟電鋼琴，接回 A）
  電鋼琴：FM 合成（調變器 1 倍頻，打擊時亮、慢慢變圓），和弦每個音錯開 10 到 25 毫秒像手彈，左右聲道各偏一點音高（寬）
  鼓：悶的 boom-bap，8 分音符搖擺 58%，整組低通 4.5 kHz、輕微降位元
  黑膠：很小的沙沙聲與偶爾一顆喀；磁帶：0.4 Hz 的慢晃（音高 ±4 cents 左右）
  為手機喇叭：貝斯和大鼓的基音手機放不出來，用飽和帶出 2、3 倍諧波；整首壓在 6 kHz 以下，不跟捏的聲音搶 1 到 3 kHz

用法：python design_lofi.py   寫 prototype/web/sfx/bgm-lofi.m4a（需要 ffmpeg）；加 --ios 也寫一份到 ios/NieNie/Resources/
每次結果都一樣（固定亂數種子）。
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
BPM = 76
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 40
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
rng = np.random.default_rng(20261102)

CHORDS = [  # MIDI，電鋼琴放在中音域（手機喇叭聽得到）
    [65, 69, 72, 76, 79],      # Fmaj9
    [64, 67, 71, 74],          # Em7
    [62, 65, 69, 72, 76],      # Dm9
    [60, 64, 67, 71, 74],      # Cmaj9
    [58, 62, 65, 69, 72],      # B♭maj9
    [57, 60, 64, 67],          # Am7
    [55, 58, 62, 65, 69],      # Gm9
    [60, 64, 70, 74, 79],      # C9
]
ROOTS = [41, 40, 38, 36, 34, 33, 31, 36]   # 貝斯的根音（F2 E2 D2 C2 B♭1 A1 G1 C2）
PENTA = [72, 74, 77, 79, 81, 84, 86]       # F 大調五聲（C5 D5 F5 G5 A5 C6 D6）


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def lp(x, fc, order=2):
    return sosfilt(butter(order, fc, btype='low', fs=SR, output='sos'), x)


def hp(x, fc, order=2):
    return sosfilt(butter(order, fc, btype='high', fs=SR, output='sos'), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype='band', fs=SR, output='sos'), x)


def add(dst, src, at):
    i = int(round(at * SR))
    if i >= len(dst):
        return
    e = min(len(dst), i + len(src))
    dst[i:e] += src[:e - i]


def rhodes(f, dur, vel, detune=0.0):
    """FM 電鋼琴：調變器 1 倍頻，調變深度一開始 1.6、0.6 秒時間常數降到 0.3（打擊亮、之後變圓）；4.5 Hz 的輕微 tremolo；放開後 0.25 秒收掉。"""
    n = int((dur + 0.6) * SR)
    t = np.arange(n) / SR
    f = f * 2 ** (detune / 1200)
    idx = 0.3 + 1.3 * np.exp(-t / 0.6) * vel
    mod = np.sin(2 * np.pi * f * t)
    x = np.sin(2 * np.pi * f * t + idx * mod)
    x += 0.08 * vel * np.sin(2 * np.pi * f * 14 * t) * np.exp(-t / 0.03)   # 一點點金屬感的敲擊
    env = np.clip(t / 0.004, 0, 1) * np.exp(-t / 1.8) * np.where(t < dur, 1.0, np.exp(-(t - dur) / 0.25))
    return x * env * (1 + 0.08 * np.sin(2 * np.pi * 4.5 * t)) * vel


def bell(f, vel):
    """旋律：很軟的鈴聲（FM，調變器 3.5 倍頻、深度很小），1.2 秒衰減。"""
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t + 0.5 * np.exp(-t / 0.3) * np.sin(2 * np.pi * 3.5 * f * t))
    return x * np.clip(t / 0.006, 0, 1) * np.exp(-t / 0.7) * vel


def bass(f, dur, vel):
    """貝斯：正弦加飽和（帶出 2、3 倍諧波，手機才聽得到），低通 700 Hz。"""
    n = int((dur + 0.15) * SR)
    t = np.arange(n) / SR
    x = np.tanh(2.2 * np.sin(2 * np.pi * f * t)) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 0.9)
    x *= np.where(t < dur, 1.0, np.exp(-(t - dur) / 0.06))
    return lp(x, 700) * vel


def kick(vel):
    n = int(0.4 * SR)
    t = np.arange(n) / SR
    f = 48 + 70 * np.exp(-t / 0.03)
    x = np.tanh(2.5 * np.sin(2 * np.pi * np.cumsum(f) / SR)) * np.exp(-t / 0.16)
    x += 0.15 * lp(rng.standard_normal(n), 2500) * np.exp(-t / 0.006)
    return x * vel


def snare(vel):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    x = 0.7 * bp(rng.standard_normal(n), 900, 4500) * np.exp(-t / 0.09)
    x += 0.5 * np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.05)
    return x * np.clip(t / 0.002, 0, 1) * vel


def hat(vel, open_=False):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    return bp(rng.standard_normal(n), 5000, 9000) * np.exp(-t / (0.09 if open_ else 0.025)) * vel


def reverb(x, secs=1.4, mix=0.25):
    """卷積殘響：指數衰減的低通雜訊當脈衝響應，左右各一條（有空間）。"""
    m = int(secs * SR)
    out = []
    for ch in range(2):
        ir = lp(rng.standard_normal(m), 3500) * np.exp(-np.arange(m) / SR / secs * 4)
        ir /= np.sqrt(np.sum(ir ** 2))
        wet = np.fft.irfft(np.fft.rfft(x, len(x) + m) * np.fft.rfft(ir, len(x) + m))[:len(x)]
        out.append(x + mix * wet)
    return np.stack(out)


def main():
    L = int(BARS * BAR * SR)
    tail = int(2 * BAR * SR)
    keysL, keysR = np.zeros(L + tail), np.zeros(L + tail)
    mel = np.zeros(L + tail)
    bas = np.zeros(L + tail)
    drm = np.zeros(L + tail)
    swing = lambda eighth: eighth * BEAT / 2 + (0.08 * BEAT if eighth % 2 else 0)   # 58% 搖擺：後半拍晚一點

    for b in range(BARS):
        sec = 'A' if b < 8 else 'B' if b < 24 else 'C' if b < 32 else 'D'
        c = CHORDS[b % 8]
        t0 = b * BAR
        # 電鋼琴：第一拍彈整個和弦（每個音錯開一點），偶爾在第 3 拍後半拍輕輕補一下
        hits = [(0.0, 1.0, 0.75)]
        if rng.random() < 0.45:
            hits.append((2.5 * BEAT + 0.08 * BEAT, BAR - 2.5 * BEAT - 0.1, 0.45))
        for at, dur, v in hits:
            for j, m in enumerate(c):
                vel = v * rng.uniform(0.8, 1.0) * (0.75 if j == 0 else 1.0)
                st = t0 + at + j * rng.uniform(0.01, 0.025)
                d = (BAR - at if at == 0 else dur) - 0.05
                add(keysL, rhodes(hz(m), d, vel, -4), st)
                add(keysR, rhodes(hz(m), d, vel, +4), st + 0.004)
        # 貝斯（D 段休息）：第 1 拍根音、第 3 拍後半拍根音或五度
        if sec != 'D':
            r = ROOTS[b % 8]
            add(bas, bass(hz(r), 1.5 * BEAT, 0.8), t0)
            add(bas, bass(hz(r + (7 if rng.random() < 0.4 else 0)), 1.2 * BEAT, 0.6), t0 + swing(5))
        # 鼓
        for e in range(8):
            at = t0 + swing(e)
            add(drm, hat(rng.uniform(0.18, 0.3) * (1.0 if e % 2 == 0 else 0.7), open_=(e == 7 and rng.random() < 0.15)), at)
            if sec in 'BC':
                if e in (0, 4) or (e == 3 and rng.random() < 0.35) or (e == 5 and rng.random() < 0.25):
                    add(drm, kick(0.9 if e in (0, 4) else 0.6), at)
                if e in (2, 6):
                    add(drm, snare(0.55 * rng.uniform(0.9, 1.0)), at)
                elif e == 7 and rng.random() < 0.2:
                    add(drm, snare(0.15), at)   # 小小的鬼音
        # 旋律（B 段）：每兩小節 2 到 4 個五聲音，落在搖擺的 8 分音符上
        if sec == 'B' and b % 2 == 0:
            spots = sorted(rng.choice(16, size=rng.integers(2, 5), replace=False))
            prev = int(rng.integers(1, 5))
            for s in spots:
                prev = int(np.clip(prev + rng.integers(-2, 3), 0, len(PENTA) - 1))
                add(mel, bell(hz(PENTA[prev]), rng.uniform(0.25, 0.38)), t0 + (s // 8) * BAR + swing(s % 8))

    # 混音：電鋼琴與旋律進殘響；鼓整組低通、輕微降位元；貝斯照舊
    keys = np.stack([keysL, keysR])
    keys = np.stack([lp(ch, 3200) for ch in keys])
    keys = keys * 0.5 + reverb(0.5 * (keysL + keysR), 1.6, 0.22)[:, :keys.shape[1]] * 0.5
    melw = reverb(lp(mel, 4000), 1.8, 0.35)
    drm = lp(np.round(drm * 1024) / 1024, 4500)
    mix = 0.42 * keys + 0.3 * melw + 0.45 * np.stack([bas, bas]) + 0.5 * np.stack([drm, drm])

    # 無縫循環：最後 2 小節以後拖出來的尾巴（殘響、延音）疊回開頭，第 40 小節接回第 1 小節
    loop = mix[:, :L].copy()
    loop[:, :tail] += mix[:, L:L + tail]

    # 黑膠：沙沙聲與偶爾一顆喀（整條都有，開頭結尾一樣密）
    n = loop.shape[1]
    hiss = lp(hp(rng.standard_normal(n), 800), 6000) * 0.006
    cr = np.zeros(n)
    for i in rng.integers(0, n - 200, size=int(n / SR * 5)):
        cr[i:i + 120] += rng.uniform(0.01, 0.04) * np.hanning(120) * rng.choice([-1, 1])
    loop += np.stack([hiss + lp(cr, 5000), hiss + lp(cr, 5000)])

    # 磁帶慢晃：0.4 Hz（兩秒半一圈）的可變延遲，±1.2 毫秒；整數圈數才接得起來
    cycles = round(n / SR * 0.4)
    ph = 2 * np.pi * cycles * np.arange(n) / n
    dl = (2.0 + 1.2 * np.sin(ph)) * SR / 1000
    idx = np.arange(n) - dl
    loop = np.stack([np.interp(idx % n, np.arange(n), ch) for ch in loop])

    # 主控：整首低通 6 kHz、軟壓縮、峰值 −3 dB
    loop = np.stack([lp(ch, 6000) for ch in loop])
    loop = np.tanh(1.6 * loop / (np.max(np.abs(loop)) or 1)) / np.tanh(1.6)
    loop *= 10 ** (-3 / 20)

    outs = [os.path.join(ROOT, 'prototype', 'web', 'sfx', 'bgm-lofi.m4a')]
    if '--ios' in sys.argv:
        outs.append(os.path.join(ROOT, 'ios', 'NieNie', 'Resources', 'bgm-lofi.m4a'))
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, 'bgm.wav')
        wavfile.write(wav, SR, (np.clip(loop.T, -1, 1) * 32767).astype(np.int16))
        for o in outs:
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', wav, '-c:a', 'aac', '-b:a', '128k', o], check=True)
            print('wrote', o, f'{n / SR:.1f}s', f'{os.path.getsize(o) / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
