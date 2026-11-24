import sys,os,random,math
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo/'
sys.path.insert(0,D+'tool');sys.path.insert(0,D)
from ana2 import load,rec,av,g
from ana import mx,tot
def ci(a,n):
    p=a/n;z=1.96;d=1+z*z/n;c=(p+z*z/2/n)/d;w=z*((p*(1-p)/n+z*z/4/n/n)**.5)/d;return f'{100*(c-w):.0f}~{100*(c+w):.0f}%'
def mc(b,c):
    n=b+c
    if n==0: return 1
    k=min(b,c);return min(1,2*sum(math.comb(n,i) for i in range(k+1))/2**n)
def get(nm):
    p=D+f'r_{nm}.json'
    if not os.path.exists(p): return None
    R,E,SK=load(p);o={}
    for r in R:
        q=rec(r);q['Lmax']=mx(r,'len');q['Lhold']=g(r,'hold','len1') if 'hold' in r['ph'] else None;q['Lrel']=g(r,'rel','len1');q['Lrel0']=g(r,'rel','len0');q['c']=r['c'];o[r['id']]=q
    return o,len(E),len(SK)
def boot(d,B=1000):
    rnd=random.Random(1);n=len(d)
    m=sorted(sum(rnd.choice(d) for _ in range(n))/n for _ in range(B));return m[int(.025*B)],m[int(.975*B)]
def show(k,names,base='a',flt=None):
    G={x:get(f'{k}_{x}') for x in names};G={x:v for x,v in G.items() if v}
    print('==',k)
    for x,(o,e,s) in G.items():
        Q=[q for q in o.values() if not flt or flt(q['c'])];n=len(Q);c=lambda kk:sum(1 for q in Q if q[kk])
        print(f"{x:3} n{n} err{e} 破{c('brk')}({ci(c('brk'),n)}) 裂{c('split')} 洞{c('hole')} 變{c('pop')} 沒蓋到{c('er')} NaN{c('nan')} | 最長 均{av([q['Lmax'] for q in Q]):.2f} 最大{max(q['Lmax'] for q in Q):.2f} 按住末{av([q['Lhold'] for q in Q]):.2f} | 落後 拉{av([q['lagP'] for q in Q]):.2f} 按住{av([q['lagH'] for q in Q]):.2f} 可見{av([q['gapH'] for q in Q]):.2f} | 放手半秒{av([q['Lrel0'] for q in Q]):.2f} 4秒{av([q['Lrel'] for q in Q]):.2f} | ms{av([q['ms'] for q in Q]):.2f} | 甩max{max(q['vmax'] for q in Q):.0f} 甩中位{sorted(q['vmax'] for q in Q)[n//2]:.1f} 末秒{av([q['j34'] for q in Q]):.2f} 抖4s{sum(1 for q in Q if q['set']>=3.9)} 按住長{av([q['grow'] for q in Q]):.2f}")
    for x,y in PAIRS:
        if x not in G or y not in G: continue
        A,B=G[x][0],G[y][0];ids=[i for i in A if i in B and (not flt or flt(A[i]['c']))]
        s=[]
        for kk in('brk','split','hole','pop'):
            b=sum(1 for i in ids if A[i][kk] and not B[i][kk]);c=sum(1 for i in ids if B[i][kk] and not A[i][kk]);s.append(f'{kk} 修{b}新破{c} p={mc(b,c):.3f}')
        for kk in('Lmax','Lhold','Lrel','lagP','lagH'):
            d=[B[i][kk]-A[i][kk] for i in ids if A[i][kk] is not None and B[i][kk] is not None]
            lo,hi=boot(d);s.append(f'{kk} {sum(d)/len(d):+.3f}[{lo:+.3f},{hi:+.3f}]')
        print(f'  {x}->{y} n{len(ids)}:',' | '.join(s))
PAIRS=[('a','b'),('g','b'),('b','c'),('c','d'),('a','c'),('b','e'),('f','e'),('a','a2'),('b','b2')]
if __name__=='__main__':
    N='a a2 g b b2 c d f e'.split()
    for k in sys.argv[1:] or ['gone','mix','rnd']: show(k,N)
