"""把 Higgsfield（Mirelo SFX）生的史萊姆音效切成 app 各層用的短音（2026-11-19，多米：AI 版的都 OK）。

原始檔在專案外面 `E:\\捏捏史萊姆\\素材\\higgsfield\\slime\\`（00 到 18，各 3 到 4 秒的 mp3）。
app 的聲音是分層的（engine.js、SlimeAudio.swift），每層要的是 0.06 到 1 秒的短音、隨機挑一個播，
所以這支照「起音」一顆一顆切，音量對齊同一層現有合成音的 RMS，再把 manifest.json 裡那幾層換成 AI 版：

  換成 AI：press.wet、press.air、release.wet、release.air、settle.bubble、pull.loop、pull.strand、
          voice.poke、voice.happy、voice.giggle、voice.protest，加一層新的 voice.tear（撕開）
  留著合成：press.body、release.body（份量，手機喇叭靠缺基音才聽得到）、rub.loop、settle.hiss、
          voice.mmm／ask／gulp／hello（這幾種沒有生 AI 版）、prop、ding

檔名一律 ai-<類>-<層>-NN.wav，design_sfx.py 的清理只刪 press/pull/release/rub/settle 開頭的，不會刪到。
**design_sfx.py 重跑會把 manifest.json 改回全合成，重跑之後要再跑這支。**
用法：python make_ai_sfx.py [--src 素材資料夾]      寫進 prototype/web/sfx/ 與 ios/NieNie/Resources/
每次結果都一樣（固定挑法，沒有亂數）。
"""
import json
import os
import subprocess
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfiltfilt

sys.stdout.reconfigure(encoding='utf-8')
SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
WEB = os.path.join(ROOT, 'prototype', 'web', 'sfx')
IOS = os.path.join(ROOT, 'ios', 'NieNie', 'Resources')
SRC = os.path.join(os.path.dirname(ROOT), '素材', 'higgsfield', 'slime')
PEAK_CAP_DB = -8.0


def load(path):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '1', '-ar', str(SR), '-'],
                       capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float64 if False else np.float32).astype(np.float64)


def db(x):
    return 20 * np.log10(np.maximum(x, 1e-12))


def rms(x):
    return float(np.sqrt(np.mean(x ** 2)))


def hp(x, f):
    return sosfiltfilt(butter(4, f, 'hp', fs=SR, output='sos'), x)


def env_db(x, hop_s=0.005):
    hop = int(hop_s * SR)
    n = len(x) // hop
    return db(np.sqrt((x[:n * hop].reshape(n, hop) ** 2).mean(axis=1))), hop


def onsets(x, thresh_db, min_gap):
    """包絡比前後 0.25 秒中位數大 thresh_db 的峰（5 毫秒一格）。回傳 (樣本位置, 突出多少 dB)。"""
    env, hop = env_db(x)
    k = int(0.25 / 0.005)
    floor = env.max() - 45   # 太小聲的不要（多半是雜訊）
    out, i = [], 0
    while i < len(env):
        lo, hi = max(0, i - k), min(len(env), i + k)
        loc = np.median(env[lo:hi])
        if env[i] > floor and env[i] - loc > thresh_db and env[i] == env[max(0, i - 4):i + 5].max():
            out.append((i * hop, float(env[i] - loc)))
            i += int(min_gap / 0.005)
        else:
            i += 1
    return out


def segments(x, below_db, gap_s, min_s, max_s):
    """有聲音的片段：比峰值小 below_db 以內算有聲音，中間空不到 gap_s 的接起來。"""
    env, hop = env_db(x)
    on = env > env.max() - below_db
    segs, i = [], 0
    while i < len(on):
        if not on[i]:
            i += 1
            continue
        j = i
        while j < len(on):
            if on[j]:
                j += 1
                continue
            g = j
            while g < len(on) and not on[g]:
                g += 1
            if g < len(on) and (g - j) * 0.005 < gap_s:
                j = g
            else:
                break
        a, b = i * hop, j * hop
        if (b - a) / SR >= min_s:
            segs.append((a, min(b, a + int(max_s * SR))))
        i = j
    return segs


def shape(y, fin=0.005, fout=0.06):
    y = y.copy()
    fi, fo = min(len(y) // 4, int(fin * SR)), min(len(y) // 2, int(fout * SR))
    y[:fi] *= 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, fi))   # 升餘弦起音，不喀
    y[-fo:] *= np.linspace(1, 0, fo) ** 2
    return y


def cut_at(x, p, pre, length, fout):
    a, b = max(0, p - int(pre * SR)), min(len(x), p + int(length * SR))
    return shape(x[a:b], fout=fout)


def pick_spread(cands, n):
    """大小平均挑（不全挑最大的），先照突出程度排，再等距取。"""
    if len(cands) <= n:
        return cands
    cands = sorted(cands, key=lambda c: -c[1])
    idx = np.unique(np.linspace(0, len(cands) - 1, n).round().astype(int))
    return [cands[i] for i in idx]


def make_loop(y, xf_s=0.3):
    """中間最平穩的 2.2 秒接成無縫循環（等功率交叉淡化）。"""
    L, X = int(2.2 * SR), int(xf_s * SR)
    if len(y) < L + X:
        L = len(y) - X
    env, hop = env_db(y, 0.05)
    need = (L + X) // hop
    best, start = None, 0
    for s in range(0, max(1, len(env) - need)):
        sc = np.std(env[s:s + need])
        if best is None or sc < best:
            best, start = sc, s * hop
    seg = y[start:start + L + X]
    t = np.linspace(0, np.pi / 2, X)
    out = seg[:L].copy()
    out[:X] = seg[:X] * np.sin(t) + seg[L:L + X] * np.cos(t)
    return out


def level(y, target_rms_db):
    """RMS 對齊到 target，峰值不超過 PEAK_CAP_DB（超過就整段降，不硬切）。"""
    g = 10 ** ((target_rms_db - db(rms(y))) / 20)
    y = y * g
    pk = np.max(np.abs(y))
    cap = 10 ** (PEAK_CAP_DB / 20)
    if pk > cap:
        y *= cap / pk
    return y


def ref_rms(manifest, kind, layer):
    """同一層現有合成音的 RMS 中位數（有聲音的部分），當作 AI 版的目標音量。"""
    vals = []
    for f in manifest.get(kind, {}).get(layer, []):
        p = os.path.join(WEB, f)
        if f.startswith('ai-') or not os.path.exists(p):
            continue
        sr, y = wavfile.read(p)
        y = y.astype(np.float64) / 32768
        if y.ndim == 2:
            y = y.mean(axis=1)
        env, hop = env_db(y)
        on = np.repeat(env > env.max() - 30, hop)[:len(y)]
        vals.append(db(rms(y[:len(on)][on])) if on.any() else db(rms(y)))
    return float(np.median(vals)) if vals else -30.0


def main():
    src = SRC
    if '--src' in sys.argv:
        src = sys.argv[sys.argv.index('--src') + 1]
    S = {n.split('-', 1)[0]: load(os.path.join(src, n)) for n in sorted(os.listdir(src)) if n.endswith('.mp3')}
    with open(os.path.join(WEB, 'manifest.json'), encoding='utf-8') as f:
        manifest = json.load(f)
    # 同一層的參考音量先量（換掉之前）
    plan = {}   # (kind, layer) -> [音訊]

    def onset_layer(kind, layer, ids, n, length, thresh, gap, band=None, pre=0.01, fout=0.05):
        cands = []
        for i in ids:
            x = S[i]
            xx = hp(x, band) if band else x
            for p, s in onsets(xx, thresh, gap):
                cands.append((i, p, s))
        chosen = pick_spread([(c, c[2]) for c in cands], n)
        outs = [cut_at(hp(S[c[0]], band) if band else S[c[0]], c[1], pre, length, fout) for c, _ in chosen]
        print('%-14s 起音 %3d 顆，用 %2d 顆（來源 %s）' % (kind + '.' + layer, len(cands), len(outs), '、'.join(ids)))
        plan[(kind, layer)] = outs

    def seg_layer(kind, layer, ids, n, below, gap, min_s, max_s):
        segs = []
        for i in ids:
            x = S[i]
            for a, b in segments(x, below, gap, min_s, max_s):
                segs.append(((i, a, b), db(rms(x[a:b]))))
        chosen = pick_spread(segs, n)
        chosen = sorted(chosen, key=lambda c: (c[0][0], c[0][1]))
        outs = [shape(S[i][max(0, a - int(0.01 * SR)):b + int(0.03 * SR)], fout=0.08) for (i, a, b), _ in chosen]
        print('%-14s 片段 %3d 段，用 %2d 段（%s 秒）' % (kind + '.' + layer, len(segs), len(outs), '、'.join('%.2f' % (len(o) / SR) for o in outs)))
        plan[(kind, layer)] = outs

    # 按：濕聲從三段按壓（含多米說 OK 的第一段），氣泡是同樣三段的高頻起音
    onset_layer('press', 'wet', ['00', '01', '02'], 6, 0.35, 6, 0.2)
    onset_layer('press', 'air', ['00', '02'], 6, 0.12, 8, 0.1, band=2000)
    # 放手：濕聲、啵、餘韻的小氣泡
    onset_layer('release', 'wet', ['09', '10'], 6, 0.28, 6, 0.15)
    onset_layer('release', 'air', ['09', '10'], 8, 0.12, 8, 0.1, band=2000)
    onset_layer('settle', 'bubble', ['00', '09', '10'], 10, 0.1, 9, 0.08, band=2500)
    # 拉：細絲一根根斷；拉絲 loop 兩條
    onset_layer('pull', 'strand', ['05', '06'], 10, 0.1, 7, 0.06, fout=0.04)
    loops = []
    for i in ('03', '04'):
        a, b = segments(S[i], 40, 0.5, 0.5, 9)[0]
        loops.append(make_loop(S[i][a:b]))
    plan[('pull', 'loop')] = loops
    print('pull.loop      兩條，各 %s 秒' % '、'.join('%.2f' % (len(l) / SR) for l in loops))
    # 它的聲音：一句一句切（中間空 0.12 秒以上算下一句）
    seg_layer('voice', 'poke', ['11', '12'], 4, 30, 0.08, 0.05, 0.45)
    seg_layer('voice', 'happy', ['13', '14'], 4, 30, 0.12, 0.15, 1.1)
    seg_layer('voice', 'giggle', ['15', '16'], 4, 30, 0.15, 0.2, 1.2)
    seg_layer('voice', 'protest', ['17', '18'], 4, 30, 0.12, 0.15, 1.1)
    seg_layer('voice', 'tear', ['07', '08'], 2, 35, 0.4, 0.3, 1.6)

    # 音量：對齊同一層現有合成音；撕開沒有對照，用放手濕聲的音量再大 3 dB（最重的放手）
    files, layers = {}, {}
    for (kind, layer), outs in plan.items():
        tgt = ref_rms(manifest, 'release', 'wet') + 3 if (kind, layer) == ('voice', 'tear') else ref_rms(manifest, kind, layer)
        names = []
        for k, y in enumerate(outs):
            name = 'ai-%s-%s-%02d.wav' % (kind, layer, k + 1)
            files[name] = level(y, tgt)
            names.append(name)
        layers[(kind, layer)] = names
        print('  %-14s 目標 RMS %.1f dB' % (kind + '.' + layer, tgt))

    # 網頁與 iOS 的 manifest 本來就不一樣（網頁有 prop、iOS 有 ding），各自讀自己的、只換上面那幾層
    for d in (WEB, IOS):
        for old in os.listdir(d):
            if old.startswith('ai-') and old.endswith('.wav') and old not in files:
                os.remove(os.path.join(d, old))
        for name, y in files.items():
            wavfile.write(os.path.join(d, name), SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))
        mp = os.path.join(d, 'manifest.json')
        with open(mp, encoding='utf-8') as f:
            m = json.load(f)
        for (kind, layer), names in layers.items():
            m.setdefault(kind, {})[layer] = names
        with open(mp, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(m, f, ensure_ascii=False, indent=2)
    tot = sum(os.path.getsize(os.path.join(WEB, n)) for n in files)
    print('寫了 %d 個檔（%.2f MB）到網頁與 iOS，manifest.json 兩邊都更新' % (len(files), tot / 1e6))


if __name__ == '__main__':
    main()
