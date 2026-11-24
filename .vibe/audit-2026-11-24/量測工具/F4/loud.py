import sys, json, os
import numpy as np
from scipy.signal import bilinear, lfilter, butter, sosfilt
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
# BS.1770 K weighting (48k) coefficients
def kw(x, sr):
    assert sr == 48000
    b1, a1 = [1.53512485958697, -2.69169618940638, 1.19839281085285], [1.0, -1.69065929318241, 0.73248077421585]
    b2, a2 = [1.0, -2.0, 1.0], [1.0, -1.99004745483398, 0.99007225036621]
    return lfilter(b2, a2, lfilter(b1, a1, x))
def mom(x, sr, win):  # max momentary loudness over windows `win` s
    y = kw(x, sr); n = int(win * sr); c = np.concatenate([[0], np.cumsum(y * y)])
    if len(y) < n: return -0.691 + 10 * np.log10(np.mean(y * y) + 1e-12)
    ms = (c[n:] - c[:-n]) / n
    return -0.691 + 10 * np.log10(ms.max() + 1e-12)
def phone(x, sr):  # a crude phone speaker: nothing below about 300 Hz
    return sosfilt(butter(4, 300, 'highpass', fs=sr, output='sos'), x)
x = np.load(os.path.join(HERE, 'rt_direct.npy')).astype(np.float64); J = json.load(open(os.path.join(HERE, 'rt_direct.json'))); sr = J['sr']; m = J['marks']
D = {}
for (t, l), (t2, _) in zip(m, m[1:]):
    seg = x[int(t * sr):int(t2 * sr)]
    p = phone(seg, sr)
    e = np.convolve(seg ** 2, np.ones(int(sr * .005)) / int(sr * .005), 'same'); pk = np.argmax(e) / sr * 1000
    k = np.argmax(np.sqrt(e) > np.sqrt(e.max()) * 10 ** (-6 / 20)) / sr * 1000
    D.setdefault(l, []).append((mom(seg, sr, .4), mom(seg, sr, .05), 20 * np.log10(np.abs(seg).max() + 1e-9), mom(p, sr, .4), k, pk))
print('%-14s n | loudest 0.4 s (LUFS) | loudest 50 ms | peak dBFS | on a phone speaker (>300Hz) 0.4 s | to -6dB of its loudest (ms) med/max' % 'event')
for l, a in sorted(D.items(), key=lambda q: -np.mean([r[0] for r in q[1]])):
    a = np.array(a); print('%-14s %d | %6.1f | %6.1f | %6.1f | %6.1f (%+.1f) | %4.0f / %4.0f' % (l, len(a), a[:, 0].mean(), a[:, 1].mean(), a[:, 2].max(), a[:, 3].mean(), a[:, 3].mean() - a[:, 0].mean(), np.median(a[:, 4]), a[:, 4].max()))
