import sys,os;sys.path.insert(0,'tool')
from ana2 import load,rec,g,P
sys.stdout.reconfigure(encoding='utf-8')
av=lambda a:(lambda b:sum(b)/len(b) if b else float('nan'))([x for x in a if x is not None])
for n in sys.argv[1:]:
    p=f'out/r_{n}.json'
    if not os.path.exists(p): continue
    R,E,S=load(p);Q=[(r,rec(r)) for r in R]
    f=lambda k:sum(1 for r,q in Q if q[k])
    fs=[(r,q) for r,q in Q if r['c']['k']=='pull' and r['c'].get('grab')=='far' and r['c'].get('sp')=='slow']
    far=[(r,q) for r,q in Q if r['c']['k']=='pull' and r['c'].get('grab')=='far']
    h=lambda X:av([g(r,'hold','len1') for r,q in X if 'hold' in r['ph']]); rl=lambda X:av([g(r,'rel','len1') for r,q in X])
    nf=[(r,q) for r,q in Q if r['c']['k']=='pull' and r['c'].get('grab') in('near','center','regrab')]
    print(f"{n:<8} n{len(Q)} 破{f('brk')} 裂{f('split')} 洞{f('hole')} 變{f('pop')} 皮沒蓋{f('er')} NaN{f('nan')} | 末秒每格跳{av([q['j34'] for r,q in Q]):.2f} 滿4秒還抖{sum(1 for r,q in Q if q['set']>=3.9)} 甩最快{max(q['vmax'] for r,q in Q):.0f} 平均{av([q['vmax'] for r,q in Q]):.1f} 按住跳{av([q['jh'] for r,q in Q]):.2f} 按住長>0.5R {sum(1 for r,q in Q if q['grow'] is not None and q['grow']>.5)}/{sum(1 for r,q in Q if q['grow'] is not None)} | 身長 按住末{h(Q):.2f} 放手末{rl(Q):.2f} 最長均{av([max(v['len'] for v in r['ph'].values()) for r,q in Q]):.2f}；抓對側(n{len(far)}) 按住{h(far):.2f} 放{rl(far):.2f}；抓同側中間(n{len(nf)}) 按住{h(nf):.2f} 放{rl(nf):.2f} | 慢拉抓對側 n{len(fs)} 有洞{sum(1 for r,q in fs if q['hole'])} 洞讀數 按住{sum(q['h_hold'] for r,q in fs)} 放手{sum(q['h_rel'] for r,q in fs)} 破{sum(q['brk'] for r,q in fs)}")
