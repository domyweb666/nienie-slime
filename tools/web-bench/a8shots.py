# A8 現況圖（batch3 #9）：無頭 Chrome 跑兩指 45 度、三指拉，存定時截圖和破的那一格。
# usage: python a8shots.py <web 資料夾> <輸出資料夾> [--procs 6] [--seeds 6] [--only id1,id2] [--scale 1]
# 先載 .vibe/audit-2026-11-24/patches/F1-量測工具/probe.js（F1 的破皮判定），再載 a8.js。
# 輸出：<輸出>/<id>/*.png、<輸出>/a8.json（每組的統計、時間軸、圖檔名）
import sys, os, json, time, base64, argparse, multiprocessing as mp
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
PROBE = os.path.join(ROOT, '.vibe', 'audit-2026-11-24', 'patches', 'F1-量測工具', 'probe.js')
sys.path.insert(0, HERE)
from st import SV, Q, CH
import threading, functools

def cells(seeds):
    o = []
    for r in range(seeds):
        sd = 201 + 41 * r   # 前三顆跟 F1 的 cells.py 一樣
        for ds in (3, 'edge'):
            for sp in ('slow', 'fast'):
                for fr in ('mid', 'edge'):
                    o.append(dict(k='opp', ang=45, dist=ds, sp=sp, **{'from': fr}, seed=sd, id=f'O45_{ds}_{sp}_{fr}_{sd}',
                                  label='兩指 45 度往反方向' + ('拉到螢幕邊' if ds == 'edge' else f'各 {ds}R') + ('快' if sp == 'fast' else '慢') + ('（從邊緣起）' if fr == 'edge' else '（從中間起）')))
        for ds in (2, 3):
            for sp in ('slow', 'fast'):
                o.append(dict(k='three', dist=ds, sp=sp, seed=sd, id=f'T3_{ds}_{sp}_{sd}', label=f'三指各拉開 {ds}R' + ('快' if sp == 'fast' else '慢')))
    return o

def save(d, name, url):
    fn = os.path.join(d, name); open(fn, 'wb').write(base64.b64decode(url.split(',', 1)[1])); return name

def work(a):
    wid, cs, port, out, scale = a
    from playwright.sync_api import sync_playwright
    js = open(PROBE, encoding='utf-8').read(), open(os.path.join(HERE, 'a8.js'), encoding='utf-8').read()
    R = []
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio'])
        for i in range(0, len(cs), 12):
            cx = b.new_context(viewport={'width': 393, 'height': 852}, device_scale_factor=2, has_touch=True); pg = cx.new_page(); pg.set_default_timeout(0)
            errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
            pg.goto(f'http://127.0.0.1:{port}/index.html', wait_until='load'); pg.wait_for_timeout(2500)
            pg.evaluate(js[0]); init = pg.evaluate('PB.init()'); pg.evaluate(js[1])
            for c in cs[i:i + 12]:
                c = dict(c, scale=scale)
                try: m = pg.evaluate('c=>A8.run(c)', c)
                except Exception as e: R.append({'id': c['id'], 'c': c, 'err': str(e)[:400]}); continue
                d = os.path.join(out, c['id']); os.makedirs(d, exist_ok=True)
                for s in m['shots']: s['img'] = save(d, s['tag'] + '.png', s['img'])
                for w in m['worst']: w['img'] = save(d, 'worst_' + w['ty'] + '.png', w['img'])
                m['init'] = init
                if errs: m['perr'] = errs[:3]; errs.clear()
                R.append(m); print(wid, c['id'], {k: (v['cFr'], v['hFr'], v['popN']) for k, v in m['ph'].items()}, flush=True)
            cx.close()
        b.close()
    return R

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('webdir'); ap.add_argument('out'); ap.add_argument('--procs', type=int, default=6); ap.add_argument('--seeds', type=int, default=6)
    ap.add_argument('--only', default=''); ap.add_argument('--port', type=int, default=8961); ap.add_argument('--scale', type=float, default=1); ap.add_argument('--burst', default=''); ap.add_argument('--swap', action='store_true')
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True)
    C = cells(a.seeds)
    if a.only: C = [c for c in C if c['id'] in a.only.split(',')]
    if a.swap: C = [dict(c, swap=1) for c in C]
    if a.burst: C = [dict(c, burst=[int(v) for v in a.burst.split(',')]) for c in C]
    srv = SV(('127.0.0.1', a.port), functools.partial(Q, directory=a.webdir)); threading.Thread(target=srv.serve_forever, daemon=True).start()
    t0 = time.time(); n = max(1, min(a.procs, len(C)))
    with mp.Pool(n) as P: RR = P.map(work, [(w, C[w::n], a.port, a.out, a.scale) for w in range(n)], chunksize=1)
    O = [x for r in RR for x in r]
    json.dump(O, open(os.path.join(a.out, 'a8.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    print('done', len(O), 'err', sum(1 for x in O if x.get('err')), 'secs', round(time.time() - t0)); srv.shutdown()
