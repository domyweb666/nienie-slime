from an import *
import statistics as st
def cmpx(k,x,y):
    A,B=get(f'{k}_{x}'),get(f'{k}_{y}')
    if not A or not B: return
    A,B=A[0],B[0];ids=[i for i in A if i in B];s=[]
    for kk in('vmax','j34','set','offFr','Lmax','jh'):
        d=[(B[i][kk] or 0)-(A[i][kk] or 0) for i in ids];lo,hi=boot(d);up=sum(1 for v in d if v>0);dn=sum(1 for v in d if v<0)
        s.append(f'{kk} 均差{sum(d)/len(d):+.2f}[{lo:+.2f},{hi:+.2f}] 升{up}降{dn}')
    print(k,x,'->',y,len(ids),' | '.join(s))
for k in('gone','mix','rnd'):
    for x,y in(('a','g'),('g','b'),('g','b2'),('a','a2'),('b','b2'),('g','h'),('g','i'),('b','c'),('f','e')): cmpx(k,x,y)
