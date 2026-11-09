"""捏捏史萊姆的環境音：雨、柴火（2026-11-09，多米：背景音改成真實環境聲，比如下雨聲、木材燃燒聲的白噪音）。

素材是 Freesound 上 CC0 的真錄音（`.uiux/04-手感/素材授權紀錄.md`），原始檔在專案外面 `E:\\捏捏史萊姆\\素材\\freesound\\`。
這支只做剪接，不合成：

  底（bed）：在原始錄音裡找最平穩的一段（0.4 秒一格量音量，扣分給「比中位數大 6 dB 以上的格子」與音量起伏，
            低頻 150 Hz 以下另外扣分，那多半是車、風、冷氣），頭尾 4 秒等功率交叉淡化，接成無縫循環。
            AAC 解碼會在頭尾多墊空白，所以檔案頭尾各多寫 1 秒循環裡的內容（跟 lofi 同一招），播放時只循環中間。
  事件（events）：偶爾冒出來的聲音，讓循環聽不出來。劈啪、滴水用起音偵測一顆一顆切；陣雨（雨忽然大一點）
            和遠雷切成幾秒長、慢進慢出的片段。

輸出到 prototype/web/sfx/（網頁）與 ios/NieNie/Resources/（加 --ios）：
  amb-<場景>-bed.m4a、amb-<場景>-<事件>-NN.wav／.m4a、amb.json（循環長度、事件清單、出現頻率、音量、左右）
用法：python make_ambience.py [--ios] [--src 素材資料夾]
每次結果都一樣（固定亂數種子）。
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt, sosfiltfilt

sys.stdout.reconfigure(encoding='utf-8')
SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WEB = os.path.join(ROOT, 'prototype', 'web', 'sfx')
IOS = os.path.join(ROOT, 'ios', 'NieNie', 'Resources')
SRC = os.path.join(os.path.dirname(ROOT), '素材', 'freesound')
rng = np.random.default_rng(20261109)

BED_LEN = 120.0     # 秒；兩分鐘一輪，加上隨機事件聽不出循環，m4a 約 2.4 MB
XF = 4.0            # 頭尾交叉淡化秒數
PAD = 1.0           # AAC 頭尾墊的秒數（播放端只循環 PAD 到 PAD+LOOP）


def load(path):
    """任何格式 → 44.1 kHz 立體聲 float32（ffmpeg 解碼，單聲道複製成兩聲道）。"""
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'],
                       capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float32).reshape(-1, 2).astype(np.float64)


def find(cat, sid):
    d = os.path.join(SRC, cat, str(sid))
    return os.path.join(d, os.listdir(d)[0])


def db(x):
    return 20 * np.log10(np.maximum(x, 1e-9))


def rms(x):
    return float(np.sqrt(np.mean(x ** 2)))


def hp(x, f, order=2):
    return sosfiltfilt(butter(order, f, 'hp', fs=SR, output='sos'), x, axis=0)


def lp(x, f, order=2):
    return sosfiltfilt(butter(order, f, 'lp', fs=SR, output='sos'), x, axis=0)


def frames_db(x, hop):
    m = x.mean(axis=1) if x.ndim == 2 else x
    n = len(m) // hop
    return db(np.sqrt((m[:n * hop].reshape(n, hop) ** 2).mean(axis=1)))


def pick_bed(x, length):
    """最平穩的一段：回傳起點（樣本）與分數明細。"""
    hop = int(0.4 * SR)
    full = frames_db(x, hop)
    low = frames_db(lp(x, 150), hop)
    need = int((length + XF) / 0.4) + 1
    best = None
    for s in range(0, len(full) - need, 2):   # 0.8 秒一步
        w, lw = full[s:s + need], low[s:s + need]
        med = np.median(w)
        spikes = np.sum(np.maximum(0, w - med - 6))     # 突出的事件（鳥叫、碰撞、人聲）
        score = np.std(w) + 0.15 * spikes + 0.5 * np.std(lw)
        if best is None or score < best[0]:
            best = (score, s, float(np.std(w)), float(spikes), float(np.std(lw)), float(med))
    return best[1] * hop, {'score': round(best[0], 2), 'std_db': round(best[2], 2), 'spikes': round(best[3], 1),
                            'low_std_db': round(best[4], 2), 'median_db': round(best[5], 1)}


def make_loop(x, start, length):
    L, X = int(length * SR), int(XF * SR)
    seg = x[start:start + L + X].copy()
    t = np.linspace(0, np.pi / 2, X)[:, None]
    out = seg[:L].copy()
    out[:X] = seg[:X] * np.sin(t) + seg[L:L + X] * np.cos(t)   # 等功率：兩段不相關的雜訊加起來音量不掉
    return out


def norm_rms(x, target_db, peak_db=-3.0):
    g = 10 ** ((target_db - db(rms(x))) / 20)
    y = x * g
    pk = np.max(np.abs(y))
    lim = 10 ** (peak_db / 20)
    if pk > lim:   # 柔性限制：只壓超過的那幾個尖峰（tanh），不整段變小
        y = np.where(np.abs(y) > lim * 0.7, np.sign(y) * (lim * 0.7 + lim * 0.3 * np.tanh((np.abs(y) - lim * 0.7) / (lim * 0.3))), y)
    return y


def onsets(x, band, thresh_db, min_gap):
    """起音：帶通後 5 毫秒包絡，比前後 0.5 秒中位數大 thresh_db 的峰。"""
    m = x.mean(axis=1)
    y = hp(m, band[0], 4)
    if band[1]:
        y = lp(y, band[1], 4)
    hop = int(0.005 * SR)
    n = len(y) // hop
    env = db(np.sqrt((y[:n * hop].reshape(n, hop) ** 2).mean(axis=1)))
    k = int(0.5 / 0.005)
    out = []
    i = k
    while i < n - k:
        loc = np.median(env[i - k:i + k])
        if env[i] - loc > thresh_db and env[i] == env[max(0, i - 4):i + 5].max():
            out.append((i * hop, env[i] - loc))
            i += int(min_gap / 0.005)
        else:
            i += 1
    return out


def cut(x, s, pre, post, fin=0.003, fout=0.06):
    a, b = max(0, s - int(pre * SR)), min(len(x), s + int(post * SR))
    y = x[a:b].copy()
    fi, fo = int(fin * SR), int(fout * SR)
    y[:fi] *= np.linspace(0, 1, fi)[:, None]
    y[-fo:] *= np.linspace(1, 0, fo)[:, None] ** 2
    return y


def slow_cut(x, s, length, fade):
    y = x[s:s + int(length * SR)].copy()
    f = int(fade * SR)
    y[:f] *= np.sin(np.linspace(0, np.pi / 2, f))[:, None] ** 2
    y[-f:] *= np.cos(np.linspace(0, np.pi / 2, f))[:, None] ** 2
    return y


def write_wav(path, x, mono=False):
    y = x.mean(axis=1) if mono else x
    wavfile.write(path, SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))


def write_m4a(path, x, kbps=160):
    with tempfile.TemporaryDirectory() as td:
        w = os.path.join(td, 'a.wav')
        write_wav(w, x)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'aac', '-b:a', f'{kbps}k', path], check=True)


def pick_spread(cands, n, x, pre, post):
    """從起音裡挑 n 顆：大小平均分布（不全挑最大的），彼此不重疊。"""
    cands = sorted(cands, key=lambda c: -c[1])
    if len(cands) <= n:
        return cands
    idx = np.linspace(0, len(cands) - 1, n * 2).astype(int)
    out = []
    for i in idx:
        c = cands[i]
        if all(abs(c[0] - o[0]) > (pre + post) * SR for o in out):
            out.append(c)
        if len(out) >= n:
            break
    return out


def main():
    ios = '--ios' in sys.argv
    if '--src' in sys.argv:
        global SRC
        SRC = sys.argv[sys.argv.index('--src') + 1]
    outs = [WEB] + ([IOS] if ios else [])
    meta = {'version': 1, 'sr': SR, 'pad': PAD, 'scenes': {}}
    files = {}   # 檔名 → 音訊

    # ---------- 雨 ----------
    rain = load(find('rain', 399072))   # 後院門廊，中側立體聲
    rain = hp(rain, 60)
    s, info = pick_bed(rain, BED_LEN)
    print('雨的底 399072 起點 %.1f 秒' % (s / SR), info)
    loop = norm_rms(make_loop(rain, s, BED_LEN), -26)
    L = len(loop)
    files['amb-rain-bed.m4a'] = np.concatenate([loop[-int(PAD * SR):], loop, loop[:int(PAD * SR)]])
    ev = {}
    # 陣雨：雨打窗的近距離錄音，挑幾段 5 到 7 秒、慢進慢出，聽起來像雨忽然大一點
    win = hp(load(find('rain', 869851)), 120)
    hop = int(0.4 * SR)
    fd = frames_db(win, hop)
    gust = []
    for k, start in enumerate(np.linspace(2, len(win) / SR - 9, 4)):
        length = 5 + 2 * rng.random()
        y = norm_rms(slow_cut(win, int(start * SR), length, 1.8), -30)
        name = 'amb-rain-gust-%02d.m4a' % (k + 1)
        files[name] = y
        gust.append(name)
    ev['gust'] = {'files': gust, 'perMin': 1.5, 'gain': [0.35, 0.7], 'pan': 0.35, 'minGap': 12}
    # 滴水：陽台滴水的起音，一顆一顆
    drip_src = hp(load(find('rain', 592345)), 300)
    cands = onsets(drip_src, (1200, 9000), 7, 0.25)   # 9 dB 只抓到 2 顆
    chosen = pick_spread(cands, 8, drip_src, 0.02, 0.35)
    print('滴水起音 %d 顆，用 %d 顆' % (len(cands), len(chosen)))
    drip = []
    for k, (p, _) in enumerate(sorted(chosen)):
        y = cut(drip_src, p, 0.02, 0.35)
        y = y / max(1e-6, np.max(np.abs(y))) * 10 ** (-14 / 20)
        name = 'amb-rain-drip-%02d.wav' % (k + 1)
        files[name] = ('mono', y)
        drip.append(name)
    ev['drip'] = {'files': drip, 'perMin': 7, 'gain': [0.25, 0.6], 'pan': 0.7, 'minGap': 1.5}
    # 雨珠打玻璃：近距離雨打窗的起音，一顆一顆，偶爾連著兩三顆（最像 ASMR 的那種細碎）
    tap_src = hp(win, 300)
    cands = onsets(tap_src, (1500, 9000), 9, 0.2)
    chosen = pick_spread(cands, 10, tap_src, 0.01, 0.25)
    print('雨珠打玻璃 869851 起音 %d 顆，用 %d 顆' % (len(cands), len(chosen)))
    tap = []
    for k, (p, _) in enumerate(sorted(chosen)):
        y = cut(tap_src, p, 0.01, 0.25, 0.002, 0.1)
        y = y / max(1e-6, np.max(np.abs(y))) * 10 ** (-16 / 20)
        name = 'amb-rain-tap-%02d.wav' % (k + 1)
        files[name] = y
        tap.append(name)
    ev['tap'] = {'files': tap, 'perMin': 10, 'gain': [0.2, 0.55], 'pan': 0.8, 'minGap': 0.4, 'burst': [1, 3]}
    # 遠雷：半開窗的錄音，低頻最大的那一段
    th = load(find('rain', 158692))
    low = frames_db(lp(th, 200), int(0.25 * SR))
    pk = int(np.argmax(low)) * int(0.25 * SR)
    st = max(0, pk - int(3 * SR))
    y = norm_rms(slow_cut(th, st, 9, 2.5), -30, -6)
    print('遠雷 158692 在 %.1f 秒' % (pk / SR))
    files['amb-rain-thunder-01.m4a'] = y
    ev['thunder'] = {'files': ['amb-rain-thunder-01.m4a'], 'perMin': 0.12, 'gain': [0.4, 0.7], 'pan': 0.2, 'minGap': 300}
    meta['scenes']['rain'] = {'bed': 'amb-rain-bed.m4a', 'loopFrames': L, 'events': ev, 'src': {'bed': 399072, 'gust': 869851, 'tap': 869851, 'drip': 592345, 'thunder': 158692}}

    # ---------- 柴火 ----------
    fire = load(find('fire', 501417))   # 客廳壁爐，中等火勢
    fire = hp(fire, 50)
    s, info = pick_bed(fire, BED_LEN)
    print('柴火的底 501417 起點 %.1f 秒' % (s / SR), info)
    loop = norm_rms(make_loop(fire, s, BED_LEN), -28)
    L = len(loop)
    files['amb-fire-bed.m4a'] = np.concatenate([loop[-int(PAD * SR):], loop, loop[:int(PAD * SR)]])
    ev = {}
    # 劈啪：兩段錄音的起音（小顆）
    crack = []
    k = 0
    for sid, n in ((370938, 8), (563766, 6)):
        src = hp(load(find('fire', sid)), 400)
        cands = onsets(src, (1500, 0), 12, 0.15)
        chosen = pick_spread(cands, n, src, 0.01, 0.18)
        print('劈啪 %d 起音 %d 顆，用 %d 顆' % (sid, len(cands), len(chosen)))
        for p, _ in sorted(chosen):
            y = cut(src, p, 0.01, 0.18, 0.002, 0.08)
            y = y / max(1e-6, np.max(np.abs(y))) * 10 ** (-12 / 20)
            k += 1
            name = 'amb-fire-crack-%02d.wav' % k
            files[name] = ('mono', y)
            crack.append(name)
    ev['crack'] = {'files': crack, 'perMin': 16, 'gain': [0.2, 0.65], 'pan': 0.45, 'minGap': 0.25, 'burst': [1, 4]}
    # 木柴塌：小火錄音裡低頻帶最大的幾個起音，留長一點（0.8 秒）
    small = hp(load(find('fire', 484338)), 60)
    cands = onsets(small, (80, 1500), 10, 2.0)
    chosen = pick_spread(cands, 4, small, 0.03, 0.8)
    print('木柴 484338 起音 %d 顆，用 %d 顆' % (len(cands), len(chosen)))
    settle = []
    for k, (p, _) in enumerate(sorted(chosen)):
        y = cut(small, p, 0.03, 0.8, 0.004, 0.3)
        y = norm_rms(y, -30, -8)
        name = 'amb-fire-settle-%02d.wav' % (k + 1)
        files[name] = y
        settle.append(name)
    ev['settle'] = {'files': settle, 'perMin': 0.8, 'gain': [0.45, 0.8], 'pan': 0.25, 'minGap': 25}
    meta['scenes']['fire'] = {'bed': 'amb-fire-bed.m4a', 'loopFrames': L, 'events': ev, 'src': {'bed': 501417, 'crack': [370938, 563766], 'settle': 484338}}

    for d in outs:
        for name, y in files.items():
            p = os.path.join(d, name)
            if name.endswith('.m4a'):
                write_m4a(p, y)
            elif isinstance(y, tuple):
                write_wav(p, y[1], mono=True)
            else:
                write_wav(p, y)
        with open(os.path.join(d, 'amb.json'), 'w', encoding='utf-8') as f:
            json.dump(meta, f, ensure_ascii=False, indent=1)
    tot = sum(os.path.getsize(os.path.join(WEB, n)) for n in files)
    print('寫了 %d 個檔（%.1f MB）到 %s' % (len(files) + 1, tot / 1e6, '、'.join(outs)))


if __name__ == '__main__':
    main()
