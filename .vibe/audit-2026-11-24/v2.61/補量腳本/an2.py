# e2 分析：每角色×設定×手勢（平均、範圍）
import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
R=[]
for f in sys.argv[1:]:
    for r in json.load(open(f,encoding='utf-8')): r['cf']=('v260' if 'v260' in f else r['cf']);R.append(r)
G=collections.defaultdict(list)
for r in R: G[(r['sl'],r['g'],r['d'],r['v'],r['cf'])].append(r)
nm={2:'芋圓',1:'薄荷',5:'湯圓',7:'汽水'}
def m(a): a=list(a);return f"{sum(a)/len(a):.2f}" + (f"({min(a):.2f}~{max(a):.2f})" if max(a)-min(a)>.1 else '')
last=None
for k in sorted(G,key=lambda k:(k[0],k[1],k[2],k[3])):
    v=G[k]
    if k[:4]!=last: print(f"-- {nm[k[0]]} 抓{k[1]} 上{k[2]}R(實{v[0]['eff']}) {k[3]}R/s");last=k[:4]
    print(f"   {k[4]:<7} 停止瞬 {m(r['stop'] for r in v)} 停1s {m(r['s'][0] for r in v)} 停末{len(v[0]['s'])}s {m(r['s'][-1] for r in v)} 1s長 {m(r['s'][0]-r['stop'] for r in v)} 1→末長 {m(r['s'][-1]-r['s'][0] for r in v)} | 放.1記 {m(r['q01'] for r in v)} 放2s記 {m(r['q2'] for r in v)} 放2s高 {m(r['y2'] for r in v)} strain {m(r['strain'] for r in v)} 逃{sum(1 for r in v if r['esc'])}")
