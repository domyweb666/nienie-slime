"""捏捏史萊姆「禪模式」的聲音（2026-11-08，多米：背景放佛經、捏史萊姆發出木魚聲，做個切換鍵看效果）。

跟 design_sfx.py 一樣離線做好，不在 app 裡即時合成。全部程式合成，沒有取樣、沒有別人的錄音，所以沒有授權問題。

  muyu-01..05.wav   木魚「叩」。中空木頭：主共鳴 600 多 Hz、腔體 340 Hz、兩個不和諧的上方模態，加 3 毫秒的敲擊聲；
                    起音 1 毫秒、120 毫秒左右收掉。五個音高差一點點，app 隨機挑，連敲不會像機關槍
  chant-loop.m4a    合成的佛號唱誦「南無阿彌陀佛」：三個男聲（主音、低八度、錯開一點的第二人）用共振峰合成母音，
                    鼻音 n／m 是悶的哼、t 是一小段停頓加氣聲、f 是嘶聲。一句 8 拍（佛字兩拍、留一拍換氣），
                    0.6 秒一拍，8 句約 38 秒一輪，第 1、5 句開頭敲一聲磬。整段加約 2.5 秒的殿堂殘響。
                    殘響與磬的尾巴都繞回開頭（環狀疊加），頭尾接得起來；AAC 頭尾會墊空白，檔案頭尾各多寫 1 秒，
                    只循環中間那段（跟 bgm-lofi-loop.m4a 同一招），長度寫在 zen/manifest.json。
  合成人聲聽得出是合成的，只是佔位。多米有授權的誦經錄音，換掉 chant-loop.m4a、改 manifest 的 loop 秒數（pad 填 0）就好。

用法：python design_zen.py   寫 prototype/web/sfx/zen/（需要 ffmpeg）。每次結果都一樣（固定亂數種子）。
只做網頁版；Swift 版要的話再照同一份檔案接 SlimeAudio.swift。
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt, fftconvolve

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'prototype', 'web', 'sfx', 'zen')
rng = np.random.default_rng(108)


def hp(x, f, sr, order=2):
    return sosfilt(butter(order, f, 'highpass', fs=sr, output='sos'), x)


def lp(x, f, sr, order=2):
    return sosfilt(butter(order, f, 'lowpass', fs=sr, output='sos'), x)


def bp(x, lo, hi, sr, order=2):
    return sosfilt(butter(order, [lo, hi], 'bandpass', fs=sr, output='sos'), x)


def peak_to(x, db):
    return x / (np.max(np.abs(x)) + 1e-12) * 10 ** (db / 20)


# ---------------- 木魚 ----------------
def muyu(f0, sr=48000):
    n = int(sr * 0.32)
    t = np.arange(n) / sr
    # (頻率倍數, 音量, 衰減秒數)：主共鳴最長，腔體悶的那聲稍短，上方模態很快消失
    modes = [(1.0, 1.0, 0.070), (0.53, 0.55, 0.055), (2.31, 0.28, 0.022), (3.86, 0.14, 0.012)]
    y = np.zeros(n)
    for r, a, d in modes:
        f = f0 * r * (1 + 0.004 * rng.standard_normal())
        # 敲下去瞬間音高略高、很快落回（木頭被敲的「咚」感）
        glide = 1 + 0.03 * np.exp(-t / 0.006)
        ph = 2 * np.pi * np.cumsum(f * glide) / sr + rng.uniform(0, 2 * np.pi)
        y += a * np.sin(ph) * np.exp(-t / d)
    # 敲擊聲：3 毫秒的帶通雜訊
    k = int(sr * 0.003)
    click = np.zeros(n)
    click[:k] = rng.standard_normal(k) * np.hanning(2 * k)[k:]
    y += 0.5 * bp(click, 1500, 5200, sr)
    # 1 毫秒起音，避免數位爆音
    a = int(sr * 0.001)
    y[:a] *= np.linspace(0, 1, a)
    y = hp(y, 150, sr)
    y = lp(y, 6500, sr)
    tail = int(sr * 0.04)
    y[-tail:] *= np.linspace(1, 0, tail)
    return peak_to(y, -8)


# ---------------- 唱誦 ----------------
SR = 44100
BEAT = 0.6
# 母音共振峰（Hz，男聲）：(F1, F2, F3)
VOW = {'a': (750, 1150, 2500), 'o': (520, 880, 2450), 'u': (340, 800, 2350), 'i': (290, 2200, 2950),
       'm': (260, 1100, 2300), 'n': (260, 1500, 2500)}
# 一句：(子音, 母音, 拍數, 相對主音的半音)。「南無阿彌陀佛」
PHRASE_A = [('n', 'a', 1, 0), ('m', 'o', 1, 0), ('', 'a', 1, 2), ('m', 'i', 1, 2), ('t', 'o', 1, 0), ('f', 'o', 2, -3)]
PHRASE_B = [('n', 'a', 1, 2), ('m', 'o', 1, 3), ('', 'a', 1, 5), ('m', 'i', 1, 3), ('t', 'o', 1, 2), ('f', 'o', 2, 0)]
PHRASES = [PHRASE_A, PHRASE_A, PHRASE_B, PHRASE_A] * 2
ROOT_HZ = 110.0  # A2；手機放不出基音，靠上面的諧波與共振峰聽得到


def score():
    """展開成一串音節：(開始秒, 長度秒, 子音, 母音, 半音)。每句 8 拍，最後一拍換氣。"""
    out, t = [], 0.0
    for ph in PHRASES:
        b = 0
        for c, v, n, s in ph:
            out.append((t + b * BEAT, n * BEAT, c, v, s))
            b += n
        t += 8 * BEAT
    return out, t


def track(syl, L, semis_shift, gain, delay, cents, seed):
    """一個人的聲音：逐樣本的基頻、共振峰軌跡、音量包絡，然後加法合成。"""
    r = np.random.default_rng(seed)
    n = int(L * SR)
    t = np.arange(n) / SR
    f0 = np.full(n, np.nan)
    F = np.zeros((3, n))
    env = np.zeros(n)
    nasal = np.zeros(n)
    noise_env = np.zeros(n)
    for (s0, dur, c, v, semi) in syl:
        s0 += delay
        i0, i1 = int(s0 * SR), int((s0 + dur * 0.92) * SR)
        i1 = min(i1, n)
        if i0 >= n:
            continue
        seg = np.arange(i0, i1)
        hz = ROOT_HZ * 2 ** ((semi + semis_shift) / 12) * 2 ** (cents / 1200)
        f0[seg] = hz
        cons_len = {'n': 0.09, 'm': 0.09, 't': 0.05, 'f': 0.08, '': 0}[c]
        k = int(cons_len * SR)
        # 共振峰：子音段用鼻音的，之後 60 毫秒滑到母音
        tv = np.array(VOW[v], float)
        tc = np.array(VOW[c], float) if c in ('m', 'n') else tv
        x = np.clip((seg - i0 - k) / (0.06 * SR), 0, 1)[None, :]
        F[:, seg] = tc[:, None] * (1 - x) + tv[:, None] * x
        # 音量：起音 70 毫秒、收尾 120 毫秒；鼻音段小聲、悶；t 是一小段停頓
        e = np.ones(len(seg))
        a = int(0.07 * SR)
        e[:a] *= np.linspace(0, 1, min(a, len(e)))[:len(e[:a])]
        rl = int(0.12 * SR)
        e[-rl:] *= np.linspace(1, 0, rl)[-len(e[-rl:]):]
        if c in ('m', 'n'):
            e[:k] *= 0.45
            nasal[i0:i0 + k] = 1
        if c == 't':
            e[:k] = 0
            noise_env[i0 + k - int(0.012 * SR):i0 + k] = 0.5
        if c == 'f':
            e[:k] *= 0.15
            noise_env[i0:i0 + k] = np.hanning(2 * k)[:k] * 0.9
        env[seg] = np.maximum(env[seg], e)
    # 句與句之間的空檔：沿用前一個值，免得 nan
    last = ROOT_HZ
    for i in range(n):
        if np.isnan(f0[i]):
            f0[i] = last
        else:
            last = f0[i]
    # 共振峰空檔也沿用
    for j in range(3):
        fj = F[j]
        z = fj == 0
        idx = np.where(~z, np.arange(n), 0)
        np.maximum.accumulate(idx, out=idx)
        F[j] = np.where(z, fj[idx], fj)
        F[j][F[j] == 0] = VOW['o'][j]
    # 自然的晃：4.8 Hz 顫音（慢慢出來）＋很慢的漂移
    vib = 1 + 0.004 * np.sin(2 * np.pi * 4.8 * t + r.uniform(0, 6)) + 0.002 * np.sin(2 * np.pi * 0.23 * t + r.uniform(0, 6))
    f0 = f0 * vib
    # 平滑轉音 40 毫秒
    f0 = lp(f0 - f0.mean(), 25, SR, 1) + f0.mean()
    phase = 2 * np.pi * np.cumsum(f0) / SR
    BW = (90, 110, 160)
    AMP = (1.0, 0.55, 0.3)
    y = np.zeros(n)
    for h in range(1, 48):
        fh = h * f0
        if fh.min() > 5000:
            break
        e = sum(AMP[j] / (1 + ((fh - F[j]) / BW[j]) ** 2) for j in range(3))
        e = e + 0.04  # 底，免得母音之間全空
        tilt = 1 / h ** 0.7
        mask = fh < 5000
        y += np.sin(h * phase) * e * tilt * mask
    y *= env
    # 鼻音段再低通（悶）
    y = y * (1 - 0.6 * nasal) + lp(y, 700, SR) * 0.6 * nasal
    # 子音的氣聲、嘶聲
    nz = bp(r.standard_normal(n), 2500, 7000, SR) * noise_env * 0.06
    # 氣聲：整段帶一點點
    br = bp(r.standard_normal(n), 400, 3000, SR) * env * 0.008
    return (y + nz + br) * gain


def bell(L, at_list):
    """引磬：不和諧的模態，長尾巴；環狀疊加，尾巴繞回開頭。"""
    n = int(L * SR)
    out = np.zeros(n)
    m = int(5.0 * SR)
    t = np.arange(m) / SR
    modes = [(1.0, 1.0, 3.8), (2.76, 0.42, 2.2), (5.40, 0.2, 1.1), (8.9, 0.07, 0.5)]
    b = np.zeros(m)
    for r, a, d in modes:
        b += a * np.sin(2 * np.pi * 523 * r * t + rng.uniform(0, 6)) * np.exp(-t / d)
    k = int(0.002 * SR)
    b[:k] *= np.linspace(0, 1, k)
    b = peak_to(hp(b, 200, SR), -1)
    for s in at_list:
        i = int(s * SR)
        idx = (np.arange(m) + i) % n
        np.add.at(out, idx, b)
    return out


def reverb_ir(rt60=2.6, length=3.2):
    n = int(length * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-6.9 * t / rt60)
    ir = lp(ir, 3500, SR)
    ir[:int(0.02 * SR)] *= np.linspace(0, 1, int(0.02 * SR))   # 20 毫秒預延遲感
    return ir / np.sqrt(np.sum(ir ** 2))


def circular_wet(x, ir):
    n = len(x)
    y = fftconvolve(np.concatenate([x, x]), ir)[:2 * n]
    return y[n:2 * n]


def chant():
    syl, L = score()
    voices = [
        track(syl, L, 0, 1.0, 0.0, 0, 1),
        track(syl, L, -12, 0.75, 0.035, -7, 2),    # 低八度
        track(syl, L, 0, 0.6, 0.06, 9, 3),          # 第二個人，晚一點、高一點點
        track(syl, L, 7, 0.22, 0.02, -4, 4),        # 很小聲的五度，像殿裡的泛音
    ]
    dry = sum(voices)
    dry = hp(dry, 90, SR)
    dry = peak_to(dry, -6)
    bl = bell(L, [0.0, 4 * 8 * BEAT]) * 0.45
    mix = dry + bl
    wet = circular_wet(mix, reverb_ir())
    y = 0.55 * mix + 0.75 * peak_to(wet, -6) * 1.0
    y = lp(y, 6000, SR)
    return peak_to(y, -4), L


def main():
    os.makedirs(OUT, exist_ok=True)
    files = []
    for i, f0 in enumerate([600, 622, 645, 668, 690]):
        x = muyu(f0)
        name = f'muyu-{i + 1:02d}.wav'
        wavfile.write(os.path.join(OUT, name), 48000, (x * 32767).astype(np.int16))
        files.append(name)
    y, L = chant()
    pad = int(1.0 * SR)
    n = len(y)
    padded = np.concatenate([y[-pad:], y, y[:pad]])
    with tempfile.TemporaryDirectory() as d:
        w = os.path.join(d, 'chant.wav')
        wavfile.write(w, SR, (padded * 32767).astype(np.int16))
        out = os.path.join(OUT, 'chant-loop.m4a')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'aac', '-b:a', '96k', out], check=True)
    man = {'muyu': files, 'chant': 'chant-loop.m4a', 'loop': n / SR, 'pad': 1.0}
    with open(os.path.join(OUT, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(man, f, ensure_ascii=False, indent=1)
    if '--preview' in sys.argv:
        wavfile.write(os.path.join(HERE, 'preview', 'zen-chant-preview.wav'), SR, (y * 32767).astype(np.int16))
    print(f'muyu x{len(files)}, chant {n / SR:.2f}s ({n} samples) -> {OUT}')


if __name__ == '__main__':
    main()
