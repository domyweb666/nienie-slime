# v2.64 C8 猜隻代理量：讀 sig.js 的輸出，每個量先標準化，再用「留一個種子出來、其他種子當中心」的最近中心猜是哪一隻。
# usage: python sig.py sig.json
# 印三組：只看位置和睡（每格比例、睡、看你、閉眼）、只看動作次數、全部。亂猜是 1/10。
import sys, json, math
sys.stdout.reconfigure(encoding='utf-8')
O = [o for o in json.load(open(sys.argv[1], encoding='utf-8')) if o.get('test') == 'SIG']
POS = ['c0', 'c1', 'c2', 'c3', 'c4', 'slp', 'look', 'shut']
ACT = ['up', 'side', 'down', 'long', 'hold', 'tiny', 'lean', 'wag', 'shrink', 'shake', 'dash', 'sigh']


def vec(f):
    v = {('c%d' % i): f['cell'][i] for i in range(5)}
    for k in POS[5:] + ACT: v[k] = f[k]
    return v


def guess(rows, keys):
    mu = {k: sum(r[1][k] for r in rows) / len(rows) for k in keys}
    sd = {k: math.sqrt(sum((r[1][k] - mu[k]) ** 2 for r in rows) / len(rows)) or 1 for k in keys}
    z = [(r[0], r[2], [(r[1][k] - mu[k]) / sd[k] for k in keys]) for r in rows]
    ok = 0; conf = {}
    for who, s, v in z:
        cen = {}
        for w2, s2, v2 in z:
            if s2 == s: continue
            c = cen.setdefault(w2, [0] * len(keys) + [0])
            for i, x in enumerate(v2): c[i] += x
            c[-1] += 1
        best = min(cen, key=lambda w: sum((v[i] - cen[w][i] / cen[w][-1]) ** 2 for i in range(len(keys))))
        ok += best == who; conf[(who, best)] = conf.get((who, best), 0) + 1
    return ok, len(z), conf


for arm in sorted(set(o['arm'] for o in O)):
    rows = [(o['val']['id'], vec(o['val']['f']), o['sd']) for o in O if o['arm'] == arm]
    print('arm', arm, '樣本', len(rows), '種子', len(set(r[2] for r in rows)))
    for name, keys in [('位置和睡', POS), ('動作次數', ACT), ('全部', POS + ACT)]:
        ok, n, conf = guess(rows, keys)
        miss = sorted(((a, b), c) for (a, b), c in conf.items() if a != b)
        print('  %s：猜中 %d／%d（%.0f%%）' % (name, ok, n, 100 * ok / n), '錯的：' + '、'.join('%s→%s×%d' % (a, b, c) for (a, b), c in miss) if miss else '')
    kinds = {}
    for o in O:
        if o['arm'] == arm:
            kinds.setdefault(o['val']['id'], []).append(sum(o['val']['kinds'].values()))
    print('  招牌次數（對照，沒拿來分）：' + '、'.join('%s %s' % (k, v) for k, v in kinds.items()))
