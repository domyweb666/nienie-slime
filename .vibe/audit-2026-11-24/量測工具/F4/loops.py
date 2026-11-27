import sys, json
import numpy as np
from scipy.signal import find_peaks
sys.stdout.reconfigure(encoding='utf-8')
from onset import load, env, m, base
for key in ['pull.loop', 'rub.loop']:
    k, l = key.split('.')
    for f in m[k][l]:
        sr, x = load(f); e = env(x, sr, 0.008); p = e.max(); med = np.median(e)
        hop = int(sr * 0.1); blk = np.array([np.sqrt(np.mean(x[i:i + hop] ** 2)) for i in range(0, len(x) - hop, hop)]); db = 20 * np.log10(blk + 1e-9)
        pk, _ = find_peaks(e, height=p * 10 ** (-9 / 20), distance=int(sr * 0.05))
        # seam: difference of level across the loop point (last 20ms vs first 20ms)
        a = np.sqrt(np.mean(x[:int(sr * .02)] ** 2)); z = np.sqrt(np.mean(x[-int(sr * .02):] ** 2))
        print('%-22s len %.2fs rms %.1f peak %.1f crest %.1f dB | 100ms blocks: min %.0f med %.0f max %.0f dB | loud pops(>-9dB of max): %d at %s | seam %.1f / %.1f dB' % (
            f, len(x) / sr, 20 * np.log10(np.sqrt(np.mean(x ** 2))), 20 * np.log10(np.abs(x).max()), 20 * np.log10(np.abs(x).max() / np.sqrt(np.mean(x ** 2))), db.min(), np.median(db), db.max(), len(pk), ['%.2f' % (q / sr) for q in pk], 20 * np.log10(a + 1e-9), 20 * np.log10(z + 1e-9)))
