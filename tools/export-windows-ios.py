# 把網頁的 12 扇窗景（22 種狀態）輸出成 iOS 用的圖層和時間表。畫布改過：先跑 tools/extract-windows.mjs，再跑這支，再跑 tools/check-windows-ios.py。
# 用法：python tools/export-windows-ios.py            （需要 playwright、Pillow、本機 Chrome）
# 輸出：ios/NieNie/Resources/win/windows.json 和 win-<扇>-<day|night>-<n>.webp
#
# windows.json：wins（名字、一句話、day 是白天染牆的顏色）＋ scenes["Shancheng|day"] = 由下往上的層。一層：
#   i 圖檔名；b 圖在所有 m 之前的座標（設計座標 680×828）；o over／add／multiply／screen；m 依序相乘的矩陣或時間表；
#   a 透明度，全部相乘（數字或時間表）；c 裁切圓（前 n 個 m 之後的座標）；d 瀑布虛線（有 d 就沒有 i、b）。
# 時間表：d 週期秒、b 開始秒、k 時間點、v 每個時間點的值、e 每段的 cubic-bezier（沒有就是線性）。取值照網頁 windows.js 的 winTrack。
import sys, os, io, re, json, base64, hashlib, threading, http.server, socketserver, functools, glob
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB, OUT = os.path.join(ROOT, 'prototype', 'web'), os.path.join(ROOT, 'ios', 'NieNie', 'Resources', 'win')
CH = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
S = 1.5           # 匯出倍率：iPhone 最大約 1.535
LOSSLESS_K = 99    # 無損不比有損大超過這個倍數就存無損（現在全部無損，合計兩三 MB，邊和漸層都乾淨）
Q = 92
JS = """async (S)=>{const g={s:S,gx:0,gy:0,gw:680*S,gh:828*S,w:680*S,h:828*S},out={};
 for(const d of WINS)for(const kind of d.only?['night']:['day','night']){const v=await winCompile(d,kind,g);
  out[d.id+'|'+kind]=v.items.map(L=>{const o={o:L.op,
    m:L.px?[]:L.ops.map(q=>q.fn?{k:q.ty,t:q.tk}:{k:'m',v:q.m}),
    a:L.al.map(q=>q.fn?{t:q.tk}:q.v),c:L.clip||null};
   if(L.ops.some(q=>q.fn&&!q.tk)||L.al.some(q=>q.fn&&!q.tk)||(L.dash&&!L.dash.tk))throw new Error(d.id+' no raw');
   if(L.path){o.d={pd:L.pd,stroke:L.stroke,w:L.lw,cap:L.cap,p:L.pat,t:L.dash.tk};return o}
   o.b=L.px?[L.x/S,L.y/S,L.c.width/S,L.c.height/S]:[L.bx,L.by,L.bw,L.bh];o.png=L.c.toDataURL('image/png').split(',')[1];return o})}
 return {wins:WINS.map(w=>({id:w.id,set:w.set,name:w.name,line:w.line,only:!!w.only,day:w.day||''})),scenes:out}}"""


class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *x):
        pass


def serve(d):
    s = socketserver.ThreadingTCPServer(('127.0.0.1', 0), functools.partial(H, directory=d))
    s.daemon_threads = True
    threading.Thread(target=s.serve_forever, daemon=True).start()
    return s


def r(x, n):
    x = round(float(x), n)
    return int(x) if x == int(x) else x


def track(t, kind=None):
    vals = [list(v) for v in t['v']]
    for v in vals:   # 補滿，Swift 不用猜：translate、scale 兩個數，rotate 三個（角度、圓心）
        if kind == 'translate':
            v += [0] * (2 - len(v))
        elif kind == 'rotate':
            v += [0] * (3 - len(v))
        elif kind == 'scale' and len(v) < 2:
            v.append(v[0])
    n = len(vals)
    assert len(t['k']) == n, t
    o = {'d': r(t['d'], 4), 'b': r(t['b'], 4), 'k': [r(x, 6) for x in t['k']], 'v': [[r(x, 4) for x in v] for v in vals]}
    if t['e']:
        assert len(t['e']) >= n - 1 and all(len(e) == 4 for e in t['e'][:n - 1]), t
        o['e'] = [[r(x, 4) for x in e] for e in t['e'][:n - 1]]
    return o


def rgba(s):
    if not s:
        return None
    q = [float(x) for x in re.findall(r'[\d.]+', s)]
    return [r(q[0] / 255, 4), r(q[1] / 255, 4), r(q[2] / 255, 4), r(q[3], 4)]


def hexc(h):
    v = int(h[1:7], 16)
    return [r((v >> 16) / 255, 4), r((v >> 8 & 255) / 255, 4), r((v & 255) / 255, 4), 1]


def lines(pd):
    """只認直線路徑（M L H V，大小寫都行）→ 線段；別的指令就停下來，不要亂猜。"""
    out, x, y, tok = [], 0.0, 0.0, re.findall(r'[a-zA-Z]|-?\d*\.?\d+', pd)
    i, cmd = 0, ''
    while i < len(tok):
        if tok[i].isalpha():
            cmd = tok[i]
            i += 1
        rel, c = cmd.islower(), cmd.upper()
        if c in 'ML':
            nx, ny = float(tok[i]) + (x if rel else 0), float(tok[i + 1]) + (y if rel else 0)
            i += 2
        elif c == 'V':
            nx, ny = x, float(tok[i]) + (y if rel else 0)
            i += 1
        elif c == 'H':
            nx, ny = float(tok[i]) + (x if rel else 0), y
            i += 1
        else:
            raise SystemExit('路徑有不認得的指令：' + pd)
        if c == 'M':
            cmd = 'l' if rel else 'L'
        else:
            out.append([r(x, 3), r(y, 3), r(nx, 3), r(ny, 3)])
        x, y = nx, ny
    return out


OPS = {'source-over': 'over', 'lighter': 'add', 'multiply': 'multiply', 'screen': 'screen'}


def encode(png):
    im = Image.open(io.BytesIO(png)).convert('RGBA')
    if im.getchannel('A').getextrema()[0] == 255:
        im = im.convert('RGB')
    a, b = io.BytesIO(), io.BytesIO()
    im.save(a, 'WEBP', quality=Q, method=4, alpha_quality=100)
    im.save(b, 'WEBP', lossless=True, quality=100, method=6)
    small = b if len(b.getvalue()) <= len(a.getvalue()) * LOSSLESS_K else a
    return small.getvalue(), ('無損' if small is b else '有損'), im.size


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in glob.glob(os.path.join(OUT, 'win-*.webp')):
        os.remove(f)
    srv = serve(WEB)
    with sync_playwright() as p:
        br = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio'])
        pg = br.new_context(viewport={'width': 393, 'height': 852}).new_page()
        pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{srv.server_address[1]}/index.html', wait_until='load')
        pg.wait_for_timeout(2500)
        data = pg.evaluate(JS, S)
        br.close()
    srv.shutdown()
    seen, total, scenes = {}, 0, {}
    for key, items in data['scenes'].items():
        wid, kind = key.split('|')
        res, size = [], 0
        for n, L in enumerate(items):
            o = {}
            if 'd' in L:
                d = L['d']
                o['d'] = {'lines': lines(d['pd']), 'c': hexc(d['stroke']), 'w': r(d['w'], 3), 'cap': d['cap'], 'p': [r(x, 3) for x in d['p']], 't': track(d['t'])}
            else:
                png = base64.b64decode(L['png'])
                im = Image.open(io.BytesIO(png)).convert('RGBA')
                h = hashlib.sha1(str(im.size).encode() + im.tobytes()).hexdigest()
                if h not in seen:
                    name = f'win-{wid}-{kind}-{n}'
                    b, how, wh = encode(png)
                    with open(os.path.join(OUT, name + '.webp'), 'wb') as f:
                        f.write(b)
                    seen[h] = name
                    size += len(b)
                    if len(b) > 120000 or max(wh) > 1500:
                        print(f'   {name} {wh} {how} {len(b) // 1024} KB')
                o['i'] = seen[h]
                o['b'] = [r(x, 3) for x in L['b']]
            o['o'] = OPS[L['o']]
            o['m'] = [{'k': 'm', 'v': [r(x, 6) for x in q['v']]} if q['k'] == 'm' else {'k': q['k'], 't': track(q['t'], q['k'])} for q in L['m']]
            o['a'] = [track(q['t']) if isinstance(q, dict) else r(q, 4) for q in L['a']]
            if L['c']:
                o['c'] = {k: r(L['c'][k], 3) for k in 'nxyr'}
            res.append(o)
        scenes[key] = res
        total += size
        print(f'{key:16s} {len(res):3d} 層 {size // 1024:5d} KB')
    wins = [{**w, 'day': rgba(w['day'])} for w in data['wins']]
    js = json.dumps({'v': 1, 'w': 680, 'h': 828, 'wins': wins, 'scenes': scenes}, ensure_ascii=False, separators=(',', ':'))
    with open(os.path.join(OUT, 'windows.json'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(js)
    print(f'{len(seen)} 張圖 {total / 1048576:.2f} MB，windows.json {len(js.encode()) // 1024} KB')


if __name__ == '__main__':
    main()
