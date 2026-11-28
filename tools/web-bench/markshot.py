# v2.65 #9 markStyle（按壓、拉扯的痕跡）：無頭 Chrome 截圖，B 壓薄透光（2）跟 v2.63（0）對照。
# usage: python markshot.py <web 資料夾> <輸出資料夾> [--slimes xiancao,peach,tangyuan] [--arms '[{"markStyle":0},{"markStyle":2}]'] [--crop 1]
# 每隻、每組截四張：按住 0.3 秒（白圈是手指）、放手 0.15 秒、拉長 1.5R 撐住、放手 0.3 秒。輸出 <輸出>/<隻>_<開關>_*.png 和 markshot.json
import sys, os, json, base64, argparse, threading, functools
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from st import SV, Q, CH

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('webdir'); ap.add_argument('out'); ap.add_argument('--slimes', default='xiancao,peach,tangyuan')
    ap.add_argument('--arms', default='[{"markStyle":0},{"markStyle":2}]'); ap.add_argument('--crop', type=int, default=1); ap.add_argument('--port', type=int, default=8973); ap.add_argument('--pull', type=float, default=1.5); ap.add_argument('--dir', default='.45,-.89')
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True); arms = json.loads(a.arms)
    srv = SV(('127.0.0.1', a.port), functools.partial(Q, directory=a.webdir)); threading.Thread(target=srv.serve_forever, daemon=True).start()
    js = open(os.path.join(HERE, 'markshot.js'), encoding='utf-8').read(); out = []
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio'])
        for sl in a.slimes.split(','):
            for arm in arms:
                cx = b.new_context(viewport={'width': 393, 'height': 852}, device_scale_factor=2, has_touch=True); pg = cx.new_page(); pg.set_default_timeout(0)
                errs = []; pg.on('pageerror', lambda e: errs.append(str(e))); pg.on('console', lambda m: errs.append(m.text) if m.type in ('error', 'warning') else None)
                pg.goto(f'http://127.0.0.1:{a.port}/index.html', wait_until='load'); pg.wait_for_timeout(2500); pg.evaluate(js)
                tag = sl + '_' + ('_'.join(f'{k}{v}' for k, v in arm.items()) or 'default') + '_'
                m = pg.evaluate('c=>MS.run(c)', dict(slime=sl, over=arm, tag=tag, crop=a.crop, pull=a.pull, ux=float(a.dir.split(',')[0]), uy=float(a.dir.split(',')[1])))
                for s in m['shots']:
                    fn = s['tag'] + '.png'; open(os.path.join(a.out, fn), 'wb').write(base64.b64decode(s['img'].split(',', 1)[1])); s['img'] = fn
                if errs: m['perr'] = errs[:3]
                m['slime'] = sl; m['arm'] = arm; out.append(m); print(tag, m['info'], m.get('perr', ''), flush=True)
                cx.close()
        b.close()
    json.dump(out, open(os.path.join(a.out, 'markshot.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
