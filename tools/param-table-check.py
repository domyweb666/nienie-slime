"""比對網頁 PRESETS 的鍵和參數表裡出現的參數名。

用法（在專案根目錄）：
    python tools/param-table-check.py

印三份清單：
  1. 程式有、表上沒有：PRESETS（jelly、mochi、clay）任何一個材質有、參數表沒寫到的鍵
  2. 表上有、程式沒有：參數表表格第一欄寫的程式名，PRESETS 和面板清單 F 都沒有
     （「三、只在 Swift 的」那一節是觸覺、聲音，本來就不在 PRESETS，分開算）
  3. 預設值不同：參數表寫的預設跟 PRESETS 不一樣
     （第二節三欄對 clay／mochi／jelly，「同」= 跟黏土一樣；其他表只有一欄「預設」，對三個材質）
另外列：面板清單 F 有、PRESETS 沒有的鍵（換隻、換材質留著的外觀開關，例如 v2.61b 的 coreSoft）。

只讀檔，不改任何東西。讀檔一律 utf-8。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HTML = ROOT / 'prototype' / 'web' / 'index.html'
TABLE = ROOT / '.uiux' / '04-手感' / '參數表-暫定.md'
MATS = ['jelly', 'mochi', 'clay']
IDENT = re.compile(r'\b[a-z][A-Za-z0-9]*\b')
NUM = re.compile(r'^\s*(-?\d*\.?\d+)')


def parse_presets(src):
    start = src.index('const PRESETS={')
    out = {}
    for m in MATS:
        i = src.index(m + ':', start) if m != 'clay' else src.index('clay:', start)
        a = src.index('{', i)
        b = src.index('}', a)
        body = src[a + 1:b]
        d = {}
        for part in body.split(','):
            part = part.strip()
            if not part or ':' not in part:
                continue
            k, v = part.split(':', 1)
            k = k.strip()
            try:
                d[k] = float(v.strip())
            except ValueError:
                d[k] = v.strip()
        out[m] = d
    return out


def parse_panel(src):
    a = src.index('const F=[')
    b = src.index('\n];', a)
    return set(re.findall(r"^\s*\['([A-Za-z0-9]+)'", src[a:b], re.M))


def num(cell):
    m = NUM.match(cell)
    return float(m.group(1)) if m else None


def parse_table(md):
    """回傳 (names, swift_names, defaults)；defaults: key -> {mat: value}"""
    names, swift, defaults = {}, set(), {}
    section = ''
    header = None
    for ln, line in enumerate(md.splitlines(), 1):
        if line.startswith('## '):
            section = line[3:].strip()
            header = None
            continue
        if line.startswith('沒有滑桿'):
            for k, v in re.findall(r'([a-z][A-Za-z0-9]*) (\d+(?:\.\d+)?)', line):
                names.setdefault(k, ln)
                defaults.setdefault(k, {m: float(v) for m in MATS})
            continue
        if not line.startswith('|'):
            header = None if not line.strip() else header
            continue
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if set(''.join(cells)) <= set('-: '):
            continue
        if header is None:
            header = cells
            continue
        first = cells[0]
        keys = IDENT.findall(first.replace('／', ' '))
        if section.startswith('三、'):
            swift.update(keys)
            continue
        if section.startswith('一、'):
            continue   # 四隻史萊姆的個性表，不是 PRESETS
        for k in keys:
            names.setdefault(k, ln)
        if len(keys) != 1:
            continue
        k = keys[0]
        if '黏土' in header and '麻糬' in header and '果凍' in header:
            clay = num(cells[header.index('黏土')])
            vals = {'clay': clay}
            for mat, col in (('mochi', '麻糬'), ('jelly', '果凍')):
                c = cells[header.index(col)]
                vals[mat] = clay if c.startswith('同') else num(c)
            defaults.setdefault(k, vals)
        else:
            col = next((i for i, h in enumerate(header) if h.startswith('預設')), None)
            if col is not None and col < len(cells):
                v = num(cells[col])
                if v is not None:
                    defaults.setdefault(k, {m: v for m in MATS})
    return names, swift, defaults


def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    src = HTML.read_text(encoding='utf-8')
    md = TABLE.read_text(encoding='utf-8')
    pre = parse_presets(src)
    panel = parse_panel(src)
    names, swift, defaults = parse_table(md)

    keys = []
    for m in MATS:
        for k in pre[m]:
            if k not in keys:
                keys.append(k)
    prog = set(keys) | panel

    missing = [k for k in keys if k not in names]
    extra = sorted(k for k in names if k not in prog)
    diff = []
    for k, vals in defaults.items():
        if k not in pre['clay']:
            continue
        for m in MATS:
            want = vals.get(m)
            have = pre[m].get(k)
            if want is None or not isinstance(have, float):
                continue
            if abs(want - have) > 1e-9:
                diff.append((k, m, want, have, names.get(k)))
    panel_only = sorted(panel - set(keys))

    print(f'PRESETS 鍵 {len(keys)} 個（三個材質聯集），參數表寫到的程式名 {len(names)} 個')
    print(f'\n1. 程式有、表上沒有：{len(missing)}')
    for k in missing:
        print('   ', k, {m: pre[m].get(k) for m in MATS})
    print(f'\n2. 表上有、程式沒有：{len(extra)}')
    for k in extra:
        print('   ', k, f'（參數表第 {names[k]} 行）')
    print(f'\n3. 預設值不同：{len(diff)}（鍵 {len({d[0] for d in diff})} 個）')
    for k, m, want, have, ln in diff:
        print(f'    {k} {m}：表 {want:g}，程式 {have:g}（參數表第 {ln} 行）')
    print(f'\n另：面板清單 F 有、PRESETS 沒有：{len(panel_only)}  {" ".join(panel_only)}')
    sw_in = sorted(k for k in swift if k in prog)
    print(f'另：「只在 Swift 的」那節寫到、網頁也有同名鍵：{len(sw_in)}  {" ".join(sw_in)}')


if __name__ == '__main__':
    main()
