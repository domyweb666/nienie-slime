# pair.py a b ...：同一組手勢逐組對照（修好、新破、McNemar p），out/r_<名>.json 或完整路徑
import sys,os,math,collections
H=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,H+'/tool')
from ana2 import load,rec
def get(n):
    R,E,S=load(n if n.endswith('.json') else H+f'/out/r_{n}.json');return {r['id']:(rec(r),r['c']) for r in R}
G=[(n,get(n)) for n in sys.argv[1:]]
for n,o in G:
    k=collections.Counter(c['k'] for q,c in o.values() if q['brk']);print(n.split('/')[-1],len(o),'破',sum(q['brk'] for q,_ in o.values()),'裂',sum(1 for q,_ in o.values() if q['split']),'洞',sum(1 for q,_ in o.values() if q['hole']),'突',sum(1 for q,_ in o.values() if q['pop']),dict(k))
a,A=G[0]
for n,o in G[1:]:
    ids=[i for i in A if i in o];b=[i for i in ids if A[i][0]['brk'] and not o[i][0]['brk']];c=[i for i in ids if o[i][0]['brk'] and not A[i][0]['brk']];m=len(b)+len(c);k=min(len(b),len(c))
    p=min(1,2*sum(math.comb(m,i) for i in range(k+1))/2**m) if m else 1
    same=sum(1 for i in ids if abs(A[i][0]['lagP']-o[i][0]['lagP'])<1e-9 and A[i][0]['vmax']==o[i][0]['vmax'])
    print(a.split('/')[-1],'->',n.split('/')[-1],'同組',len(ids),'只前者破',len(b),'只後者破',len(c),'p=%.3f'%p,'數字完全一樣的組',same,'| 新破:',c[:14])
