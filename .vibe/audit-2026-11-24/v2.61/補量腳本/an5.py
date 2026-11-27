import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
R=[]
for f in sys.argv[1:]:
    for r in json.load(open(f,encoding='utf-8')): r['cf']=('v260' if 'v260' in f else r['cf']);R.append(r)
nm={2:'芋圓',1:'薄荷',5:'湯圓',7:'汽水'}
G=collections.defaultdict(list)
for r in R: G[(r['sl'],r['nm'],r['v'],r['cf'])].append(r)
def f(a): a=[x for x in a if x is not None]; return '沒' if not a else (f"{a[0]}" if len(set(a))==1 else f"{min(a)}~{max(a)}")
for k in sorted(G):
    v=G[k];print(f"{nm[k[0]]} {k[1]:<8}{k[2]}cm/s {k[3]:<5} 呼嚕秒 {f([r['tP'] for r in v])}(沒{sum(r['tP'] is None for r in v)}/{len(v)}) 第幾趟 {f([r['nP'] for r in v])} 一趟 {v[0]['dur1']}s 最高 {f([r['purr'] for r in v])} g {f([r['g'] for r in v])} 熟 {f([r['dTr'] for r in v])} 戒 {f([r['dW'] for r in v])} 移 {f([r['shift'] for r in v])}R")
