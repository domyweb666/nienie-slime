import sys, json, os
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
def rmsenv(x, sr, w=0.02, hop=0.005):
    n = int(sr * w); h = int(sr * hop)
    c = np.concatenate([[0], np.cumsum(x * x)]); idx = np.arange(0, len(x) - n, h)
    return np.sqrt((c[idx + n] - c[idx]) / n), idx / sr + w / 2
def db(v): return 20 * np.log10(np.maximum(v, 1e-7))
def rms(x): return float(db(np.sqrt(np.mean(x ** 2) + 1e-14))) if len(x) else -140
for name in sys.argv[1].split(','):
    x = np.load(os.path.join(HERE, 'rt_%s.npy' % name)).astype(np.float64); J = json.load(open(os.path.join(HERE, 'rt_%s.json' % name))); sr = J['sr']
    marks = J['marks']; print('==', name)
    agg = {}
    T = {}
    for i, (tm, lab) in enumerate(marks):
        t1 = marks[i + 1][0] if i + 1 < len(marks) else len(x) / sr
        agg.setdefault(lab, []).append((tm, t1))
    for lab, L in agg.items():
        full = [rms(x[int(a * sr):int(b * sr)]) for a, b in L]
        f3 = [rms(x[int(a * sr):int((a + .3) * sr)]) for a, b in L]
        l3 = [rms(x[int(max(a, b - .3) * sr):int(b * sr)]) for a, b in L]
        print('  %-6s n=%2d dur %.2f | rms median %.1f  range %.1f..%.1f | first 0.3 s median %.1f (range %.1f..%.1f) | last 0.3 s median %.1f' % (lab, len(L), np.mean([b - a for a, b in L]), np.median(full), min(full), max(full), np.median(f3), min(f3), max(f3), np.median(l3)))
    # how the sound follows the hand: per trial correlation in the moving+stopped window
    H = np.array(J['hand']); e, te = rmsenv(x, sr)
    mv = [m for m in marks if m[1] in ('rub', 'pull')]; st = [m for m in marks if m[1] == 'stop']; up = [m for m in marks if m[1] == 'up']
    cs = []; lags = []; tails = []; ratio = []
    for a, b, u in zip(mv, st, up):
        g = (te >= a[0] - .2) & (te < u[0] - .02)
        hs = np.interp(te[g], H[:, 0], H[:, 1]); L = np.maximum(db(e[g]), -75); best = (-9, 0)
        for d in range(0, 80, 2):
            if d == 0: c = np.corrcoef(np.log10(hs + .05), L)[0, 1]
            else: c = np.corrcoef(np.log10(hs[:-d] + .05), L[d:])[0, 1]
            if c > best[0]: best = (c, d * 5)
        cs.append(np.corrcoef(np.log10(hs + .05), L)[0, 1]); lags.append(best)
        m1 = rms(x[int(a[0] * sr):int(b[0] * sr)]); s1 = rms(x[int((b[0] + .15) * sr):int(u[0] * sr)]); ratio.append(m1 - s1)
    print('  per-trial corr(level, hand speed): median %.2f (range %.2f..%.2f); best lag median %d ms (corr %.2f)' % (np.median(cs), min(cs), max(cs), np.median([l[1] for l in lags]), np.median([l[0] for l in lags])))
    print('  moving level minus stopped level (after 0.15 s): median %.1f dB, trials where stopped is as loud or louder than moving: %d of %d' % (np.median(ratio), sum(r <= 0 for r in ratio), len(ratio)))
    print('  per-trial moving - stopped:', [round(r, 1) for r in ratio])
