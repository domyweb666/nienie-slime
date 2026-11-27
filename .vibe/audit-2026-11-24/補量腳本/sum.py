import sys,os
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo/'
sys.path.insert(0,D+'tool')
from ana2 import load,rec,av,g
import random
def ci(a,n):
    if not n: return ''
    p=a/n;z=1.96;d=1+z*z/n;c=(p+z*z/2/n)/d;w=z*((p*(1-p)/n+z*z/4/n/n)**.5)/d;return f'{100*(c-w):.0f}~{100*(c+w):.0f}%'
def S(nm,f=None):
    p=D+f'r_{nm}.json'
    if not os.path.exists(p): return
    R,E,SK=load(p)
    if f: R=[r for r in R if f(r['c'])]
    if not R: return
    Q=[rec(r) for r in R];n=len(Q);c=lambda k:sum(1 for q in Q if q[k])
    print(f"{nm:<9} n{n:4d} err{len(E)} sk{len(SK)} 破{c('brk'):3d}({ci(c('brk'),n)}) 裂{c('split'):3d} 洞{c('hole'):3d} 變{c('pop'):3d} | 裂格{sum(q['split'] for q in Q):4d} 洞格{sum(q['hole'] for q in Q):4d} 變次{sum(q['pop'] for q in Q):4d} 皮沒蓋到{c('er'):3d} 翻面均{av([q['fl'] for q in Q]):4.0f} 自交格{sum(q['xFr'] for q in Q):5d} 按住跳{av([q['jh'] for q in Q]):5.2f} 末秒{av([q['j34'] for q in Q]):4.2f} 抖4s{sum(1 for q in Q if q['set']>=3.9):3d} 甩max{max(q['vmax'] for q in Q):4.0f} 出畫面{c('offFr'):3d} 身長{av([g(r,'hold','len1') for r in R if 'hold' in r['ph']]):.2f}→{av([g(r,'rel','len1') for r in R]):.2f} 落後{av([q['lagH'] for q in Q]):.2f} 可見{av([q['gapH'] for q in Q]):.2f} ms{av([q['ms'] for q in Q]):.1f} NaN{c('nan')}")
if __name__=='__main__':
    for nm in sys.argv[1:]: S(nm)
