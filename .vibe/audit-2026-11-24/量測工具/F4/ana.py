import sys, json, os
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
def rmsenv(x, sr, w=0.02, hop=0.01):
    n = int(sr * w); h = int(sr * hop); out = []
    for i in range(0, len(x) - n, h): out.append(np.sqrt(np.mean(x[i:i + n] ** 2)))
    return np.array(out), np.arange(len(out)) * hop + w / 2
def db(v): return 20 * np.log10(np.maximum(v, 1e-7))
for name in sys.argv[1].split(','):
    x = np.load(os.path.join(HERE, 'rt_%s.npy' % name)).astype(np.float64); J = json.load(open(os.path.join(HERE, 'rt_%s.json' % name))); sr = J['sr']
    e, te = rmsenv(x, sr); marks = J['marks']; H = np.array(J['hand']) if J['hand'] else np.zeros((1, 4))
    print('==', name, 'dur %.2f s' % (len(x) / sr), 'overall rms %.1f dBFS, peak %.1f' % (db(np.sqrt(np.mean(x ** 2))), db(np.abs(x).max())))
    for i, (tm, lab) in enumerate(marks):
        t1 = marks[i + 1][0] if i + 1 < len(marks) else te[-1]
        sel = (te >= tm) & (te < t1)
        if sel.sum() < 2: continue
        seg = e[sel]
        a = (te >= tm) & (te < min(t1, tm + .3)); b = (te >= max(tm, t1 - .5)) & (te < t1)
        print('  %6.2f %-5s %.2fs | rms %.1f  max %.1f  first0.3s %.1f  last0.5s %.1f dBFS' % (tm, lab, t1 - tm, db(np.sqrt(np.mean(seg ** 2))), db(seg.max()), db(np.sqrt(np.mean(e[a] ** 2))) if a.any() else -120, db(np.sqrt(np.mean(e[b] ** 2))) if b.any() else -120))
    # correlation of hand speed and sound level while grabbing
    if len(H) > 20:
        hs = np.interp(te, H[:, 0], H[:, 1]); sv = np.interp(te, H[:, 0], H[:, 3]); st = np.interp(te, H[:, 0], H[:, 2])
        g = (te > marks[0][0] + .1) & (te < marks[-1][0])
        L = db(e)
        for lab, s in (('hand speed(R/s)', hs), ('stretch rate', sv)):
            k = np.corrcoef(np.log10(s[g] + .05), np.maximum(L[g], -80))[0, 1]
            best = max(((np.corrcoef(np.log10(s[g][:-d or None] + .05), np.maximum(L[g][d:], -80))[0, 1], d * 10) for d in range(0, 40)), key=lambda q: q[0])
            print('  corr(level dB, log %s) = %.2f  (best lag %d ms: %.2f)' % (lab, k, best[1], best[0]))
