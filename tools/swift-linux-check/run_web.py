#!/usr/bin/env python3
"""Headless runs of the web prototype's selftest.js / fuzz.js at 393x852.
usage: run_web.py <webdir> selftest|fuzz|eval [--seeds 1000-1029] [--over '{"k":v}'] [--js file] [--out file] [--port N]"""
import sys, json, time, argparse, threading, http.server, socketserver, functools, os
from playwright.sync_api import sync_playwright

ap = argparse.ArgumentParser()
ap.add_argument('webdir'); ap.add_argument('mode')
ap.add_argument('--seeds', default='1000-1029'); ap.add_argument('--over', default='{}')
ap.add_argument('--js'); ap.add_argument('--out'); ap.add_argument('--port', type=int, default=8931)
ap.add_argument('--query', default='')
ap.add_argument('--shot')
a = ap.parse_args()

class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *x): pass
socketserver.TCPServer.allow_reuse_address = True
srv = socketserver.ThreadingTCPServer(('127.0.0.1', a.port), functools.partial(Q, directory=a.webdir))
threading.Thread(target=srv.serve_forever, daemon=True).start()

with sync_playwright() as p:
    b = p.chromium.launch(executable_path='/usr/bin/google-chrome', headless=True,
                          args=['--autoplay-policy=no-user-gesture-required', '--mute-audio', '--disable-gpu-vsync'])
    ctx = b.new_context(viewport={'width': 393, 'height': 852}, device_scale_factor=2, has_touch=True)
    pg = ctx.new_page()
    errs = []
    pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.on('console', lambda m: errs.append('console.error: ' + m.text) if m.type == 'error' else None)
    pg.goto(f'http://127.0.0.1:{a.port}/index.html{a.query}', wait_until='load')
    pg.wait_for_timeout(1500)
    t0 = time.time()
    if a.mode == 'selftest':
        src = open(a.js or os.path.join(a.webdir, 'selftest.js'), encoding='utf-8').read()
        res = pg.evaluate(src)
        out = {'ALL_PASS': res.get('ALL_PASS'), 'PASS': res.get('PASS'), 'fail': [k for k, v in (res.get('PASS') or {}).items() if not v], 'res': res}
    elif a.mode == 'fuzz':
        lo, hi = a.seeds.split('-') if '-' in a.seeds else (a.seeds, a.seeds)
        seeds = list(range(int(lo), int(hi) + 1))
        pg.evaluate('(c)=>{window.FZ=c}', {'seeds': seeds, 'over': json.loads(a.over)})
        pg.evaluate(open(os.path.join(a.webdir, 'fuzz.js'), encoding='utf-8').read())
        pg.wait_for_function('window.__fz && window.__fz.done', timeout=1800000, polling=500)
        out = pg.evaluate('({sum:window.__fz.sum,out:window.__fz.out.map(o=>({seed:o.seed,flipFr:o.flipFr,frames:o.frames,flipMax:o.flipMax,qFlipMax:o.qFlipMax,strainMax:o.strainMax,qStrainMax:o.qStrainMax,jerkHold:o.jerkHold,jerkHoldMean:o.jerkHoldMean,endSharp:o.endSharp,endSpikes:o.endSpikes,endFlip:o.endFlip,endQFlip:o.endQFlip,endX:o.endX,grd:o.grd,physMs:o.physMs,physMsMax:o.physMsMax})),extra:window.__fz.extra})')
    else:
        out = pg.evaluate(open(a.js, encoding='utf-8').read())
    if a.shot: pg.wait_for_timeout(600); pg.screenshot(path=a.shot)
    out = {'secs': round(time.time() - t0, 1), 'errors': errs[:20], **(out if isinstance(out, dict) else {'value': out})}
    if a.out: json.dump(out, open(a.out, 'w'), ensure_ascii=False, indent=1)
    brief = {k: v for k, v in out.items() if k not in ('res', 'out', 'PASS')}
    print(json.dumps(brief, ensure_ascii=False))
    b.close()
srv.shutdown()
