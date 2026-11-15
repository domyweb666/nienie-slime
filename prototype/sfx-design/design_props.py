# 擺飾的聲音（2026-11-06，環境互動）：陶盆、石頭盤碰到木頭窗台或互撞的那一聲。
# 用法：python -I design_props.py <輸出資料夾> [manifest.json 路徑]
# 2026-11-15 加玻璃（蠟燭杯、玻璃罐）、書、風鈴。
# 跟 design_sfx.py v3 同一個方向：不刺耳、起音別太硬、低通、峰值壓低。陶器短促、悶一點，石頭盤多一點清脆的小顆粒。
import json
import os
import sys
import wave

import numpy as np

SR = 44100


def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x)
    v = 0.0
    for i in range(len(x)):
        v = (1 - a) * x[i] + a * v
        y[i] = v
    return y


def partials(rng, dur, freqs, taus, amps, jitter=0.03):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for f, tau, a in zip(freqs, taus, amps):
        f2 = f * (1 + rng.uniform(-jitter, jitter))
        x += a * np.sin(2 * np.pi * f2 * t + rng.uniform(0, 6.28)) * np.exp(-t / tau)
    return x, t


def finish(x, attack, peak_db, fc):
    n = len(x)
    a = min(n, int(attack * SR))
    x = x.copy()
    x[:a] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(a) / a)
    tail = int(0.012 * SR)
    x[-tail:] *= np.linspace(1, 0, tail)
    x = lowpass(x, fc)
    x = lowpass(x, fc * 1.5)
    m = np.max(np.abs(x)) or 1
    return x / m * 10 ** (peak_db / 20)


def pot(rng):
    # 陶盆放在木頭上：低的咚加一點陶的共鳴，很快收掉
    x, t = partials(rng, 0.22, [150, 310, 640, 1180], [0.045, 0.03, 0.018, 0.009], [1.0, 0.55, 0.3, 0.14])
    noise = rng.standard_normal(len(x)) * np.exp(-t / 0.006) * 0.25
    return finish(x + noise, 0.003, -15, 2600)


def dish(rng):
    # 石頭盤：盤子的短響加石頭碰在一起的兩三顆小顆粒
    x, t = partials(rng, 0.2, [260, 720, 1450, 2300], [0.03, 0.022, 0.012, 0.007], [0.8, 0.6, 0.35, 0.15])
    for _ in range(rng.integers(2, 4)):
        at = int(rng.uniform(0.012, 0.075) * SR)
        g, _t = partials(rng, 0.05, [rng.uniform(1100, 1900), rng.uniform(2200, 3100)], [0.007, 0.004], [1, 0.5])
        end = min(len(x), at + len(g))
        x[at:end] += 0.5 * g[: end - at]
    return finish(x, 0.003, -16, 3200)


def glass(rng):
    # 玻璃杯、玻璃罐碰到木頭（2026-11-15 擺飾變真第 1 片）：短的悶咚加一點玻璃的亮，亮的那層壓得很低、很快收掉
    x, t = partials(rng, 0.26, [210, 880, 1760, 2640], [0.03, 0.05, 0.035, 0.02], [0.9, 0.5, 0.28, 0.1])
    noise = rng.standard_normal(len(x)) * np.exp(-t / 0.005) * 0.18
    return finish(x + noise, 0.004, -17, 3400)


def book(rng):
    # 書堆在木頭上滑一下、頓一下：只有低的悶聲和一點紙的沙
    x, t = partials(rng, 0.2, [95, 180, 330], [0.05, 0.035, 0.02], [1.0, 0.6, 0.25])
    noise = lowpass(rng.standard_normal(len(x)), 1800) * np.exp(-t / 0.03) * 0.5
    return finish(x + noise, 0.006, -16, 1500)


def bell(rng):
    # 玻璃風鈴的叮：起音軟（8 毫秒）、餘音約一秒、峰值比撞擊聲再低一截。四個音高略不同，連著響不會像同一顆
    f = rng.uniform(1480, 1720)
    x, t = partials(rng, 1.3, [f, f * 2.02, f * 2.71, f * 3.6], [0.42, 0.25, 0.14, 0.07], [1.0, 0.3, 0.16, 0.05], jitter=0.004)
    return finish(x, 0.008, -21, 4200)


def save(path, x):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())


def main():
    out = sys.argv[1]
    rng = np.random.default_rng(20261106)
    names = {'pot': [], 'dish': []}
    names.update({'glass': [], 'book': [], 'bell': []})
    for kind, fn in (('pot', pot), ('dish', dish), ('glass', glass), ('book', book), ('bell', bell)):   # 新的接在後面，前面兩種的亂數順序不變
        for k in range(1, 5):
            name = f'prop-{kind}-{k:02d}.wav'
            save(os.path.join(out, name), fn(rng))
            names[kind].append(name)
    if len(sys.argv) > 2:
        with open(sys.argv[2], encoding='utf-8') as f:
            m = json.load(f)
        m['prop'] = names
        with open(sys.argv[2], 'w', encoding='utf-8', newline='\n') as f:
            json.dump(m, f, ensure_ascii=False, indent=2)
            f.write('\n')
    print(names)


if __name__ == '__main__':
    main()
