# 擺飾的聲音（2026-11-06，環境互動）：陶盆、石頭盤碰到木頭窗台或互撞的那一聲。
# 用法：python -I design_props.py <輸出資料夾> [manifest.json 路徑]
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
    for kind, fn in (('pot', pot), ('dish', dish)):
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
