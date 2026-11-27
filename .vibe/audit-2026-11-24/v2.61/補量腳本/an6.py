import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
R=[]
for f in sys.argv[1:]:
    for r in json.load(open(f,encoding='utf-8')): r['cf']=('v260' if 'v260' in f else r['cf']);R.append(r)
nm={2:'芋圓',1:'薄荷',5:'湯圓',7:'汽水'}
G=collections.defaultdict(list)
for r in R: G[(r['sl'],r['cf'],r['d'],r['v'],r['hold'])].append(r)
def m(a): a=list(a);return f"{sum(a)/len(a):.2f}"+(f"({min(a):.2f}~{max(a):.2f})" if max(a)-min(a)>.02 else '')
for k in sorted(G,key=lambda k:(k[0],k[2],-k[3],k[4],k[1])):
    v=G[k];n=len(v)
    print(f"{nm[k[0]]} {k[2]}R {k[3]}R/s 停{k[4]} {k[1]:<7}n{n} strain {m(r['strain'] for r in v)} 抗議{sum(1 for r in v if r['prot'])} 逃{sum(1 for r in v if r['esc'])} yank{sum(1 for r in v if r['yank'])} 紅 {m(r['red'] for r in v)} 瞇{sum(1 for r in v if r['sq'])} 戒 {m(r['dW'] for r in v)} 熟 {m(r['dTr'] for r in v)} 往回拔tug {m(r['tug'] for r in v)} 移{m(r['tugPx'] for r in v)}R 拉開 {m(r['st'] for r in v)} 脫{sum(1 for r in v if r['lost'] is not None)}")
