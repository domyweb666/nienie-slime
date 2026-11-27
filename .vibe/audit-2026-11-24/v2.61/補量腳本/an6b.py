import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
f,cfs,vs=sys.argv[1],sys.argv[2].split(','),[float(x) for x in sys.argv[3].split(',')]
R=json.load(open(f,encoding='utf-8'));G=collections.defaultdict(list)
for r in R:
    if r['cf'] in cfs and r['v'] in vs: G[(r['sl'],r['dn'],r['cf'],r['d'],r['v'])].append(r)
def m(a): a=list(a);return f"{sum(a)/len(a):.2f}"+(f"~{max(a):.2f}" if max(a)-min(a)>.03 else '')
for k in sorted(G):
    v=G[k];print(f"sl{k[0]} {k[1]} {k[2]} {k[3]}R(實{v[0]['eff']}) {k[4]}R/s 拉開{m(r['st'] for r in v)} :",' / '.join(f"停{h}: s{m(r['strain'] for r in w)} 抗{sum(r['prot']>0 for r in w)} 逃{sum(r['esc'] for r in w)} 戒{m(r['dW'] for r in w)} 熟{m(r['dTr'] for r in w)} 拔{m(r['tugPx'] for r in w)}" for h in sorted({r['hold'] for r in v}) for w in [[r for r in v if r['hold']==h]]), 'n/格',len(v)//len({r['hold'] for r in v}))
