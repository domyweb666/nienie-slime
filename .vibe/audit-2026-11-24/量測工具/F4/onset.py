import sys, json, os
import numpy as np
from scipy.io import wavfile
sys.stdout.reconfigure(encoding='utf-8')
base = r'C:\Users\fcharlie\AppData\Local\Temp\claude\667dbbd50c5b7948\415881cf-6a7b-41c2-85af-00bf46311a7d\scratchpad\audit\f4src\prototype\web\sfx' + '\\'
m = json.load(open(base + 'manifest.json', encoding='utf-8'))

def load(f):
    sr, x = wavfile.read(base + f)
    if x.dtype == np.int16: x = x / 32768.0
    elif x.dtype == np.int32: x = x / 2147483648.0
    x = x.astype(np.float64)
    if x.ndim > 1: x = x.mean(1)
    return sr, x

def env(x, sr, w=0.004):
    n = max(1, int(sr * w)); k = np.ones(n) / n
    e = np.sqrt(np.convolve(x * x, k, 'same')); return e

if __name__ == '__main__':
    want = sys.argv[1].split(',') if len(sys.argv) > 1 else None
    rows = []
    for k, v in m.items():
        if not isinstance(v, dict): continue
        for l, fs in v.items():
            key = k + '.' + l
            if want and key not in want: continue
            T = []
            for f in fs:
                sr, x = load(f); e = env(x, sr); p = e.max()
                on = np.argmax(e > p * 10 ** (-26 / 20)) / sr * 1000      # first time within 26 dB of its own loudest moment
                h = np.argmax(e > p * 10 ** (-6 / 20)) / sr * 1000        # first time within 6 dB of its own loudest moment
                pk = np.argmax(e) / sr * 1000
                # absolute audible: -45 dBFS rms
                ab = np.argmax(e > 10 ** (-45 / 20)) / sr * 1000 if (e > 10 ** (-45 / 20)).any() else -1
                T.append((f, on, h, pk, ab, len(x) / sr))
            on = [a[1] for a in T]; h = [a[2] for a in T]; pk = [a[3] for a in T]
            rows.append((key, len(T), np.median(on), max(on), np.median(h), max(h), np.median(pk), max(pk)))
            if want:
                for a in T: print('  %-28s onset %5.0f  -6dB %5.0f  peak %5.0f  >-45dBFS %5.0f  len %.2f' % a)
    print('%-15s n | onset med/max | reach -6dB med/max | loudest med/max (ms)' % 'layer')
    for r in rows: print('%-15s %2d | %4.0f %4.0f | %4.0f %4.0f | %4.0f %4.0f' % r)
