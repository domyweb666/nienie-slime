# v2.64 B9 rubTrail（batch3 #6）：揉的時候手指走過的痕跡，無頭 Chrome 截圖給多米看。
# usage: python rubshot.py <web 資料夾> <輸出資料夾> [--slimes taro,mimi,...] [--arms '[{"rubTrail":1},{"rubTrail":0}]'] [--scale 1]
# 每隻、每組開關截三張：揉到 3 秒（白圈是手指）、放手後 0.25 秒、0.6 秒。輸出 <輸出>/<隻>_<開關>_*.png 和 rubshot.json
import sys, os, json, base64, argparse, threading, functools
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from st import SV, Q, CH

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('webdir'); ap.add_argument('out'); ap.add_argument('--slimes', default='taro')
    ap.add_argument('--arms', default='[{"rubTrail":1},{"rubTrail":0}]'); ap.add_argument('--scale', type=float, default=1); ap.add_argument('--port', type=int, default=8971); ap.add_argument('--v', type=float, default=1.5)
    a = ap.parse_args(); os.makedirs(a.out, exist_ok=True); arms = json.loads(a.arms)
    srv = SV(('127.0.0.1', a.port), functools.partial(Q, directory=a.webdir)); threading.Thread(target=srv.serve_forever, daemon=True).start()
    js = open(os.path.join(HERE, 'rubshot.js'), encoding='utf-8').read(); out = []
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio'])
        for sl in a.slimes.split(','):
            for ai, arm in enumerate(arms):
                cx = b.new_context(viewport={'width': 393, 'height': 852}, device_scale_factor=2, has_touch=True); pg = cx.new_page(); pg.set_default_timeout(0)
                errs = []; pg.on('pageerror', lambda e: errs.append(str(e)))
                pg.goto(f'http://127.0.0.1:{a.port}/index.html', wait_until='load'); pg.wait_for_timeout(2500); pg.evaluate(js)
                tag = sl + '_' + ('_'.join(f'{k}{v}' for k, v in arm.items()) or 'default') + '_'
                m = pg.evaluate('c=>RUBS.run(c)', dict(slime=sl, over=arm, tag=tag, scale=a.scale, v=a.v))
                for s in m['shots']:
                    fn = s['tag'] + '.png'; open(os.path.join(a.out, fn), 'wb').write(base64.b64decode(s['img'].split(',', 1)[1])); s['img'] = fn
                if errs: m['perr'] = errs[:3]
                m['slime'] = sl; m['arm'] = arm; out.append(m); print(tag, m['trail'], m.get('skinUsed'), m.get('jel'), m.get('perr', ''), flush=True)
                cx.close()
        b.close()
    json.dump(out, open(os.path.join(a.out, 'rubshot.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
