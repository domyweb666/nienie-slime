import json,sys,collections
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
order=['honey','mint','taro','peach','xiancao','tangyuan','diedou','qishui','buding','zhennai']
r=[];sl=[];wk=[];w=[]
for o in order:
    d=json.load(open(f'../data/ten-{o}.json',encoding='utf-8'));S=d['S'];c=collections.Counter(x[1] for x in S);n=len(S);r.append(d['meta']['restMul']);sl.append(100*(c['sleep']+c['drowsy'])/n);wk.append(sum(1 for e in d['E'] if e['k'] in('gaitTo','route'))*2);w.append(100*c['walk']/n)
r=np.array(r);print('restMul 與 睡%% r=%.3f；與 走次/時 r=%.3f；與 走%% r=%.3f'%(np.corrcoef(r,sl)[0,1],np.corrcoef(r,wk)[0,1],np.corrcoef(r,w)[0,1]))
k=[i for i,o in enumerate(order) if o not in('mint','qishui')];print('去掉薄荷汽水：睡%% %.1f 到 %.1f，走次/時 %d 到 %d'%(min(np.array(sl)[k]),max(np.array(sl)[k]),min(np.array(wk)[k]),max(np.array(wk)[k])))
# 三群：restMul<=.6, .8-1, >=1.15 的 5 分鐘辨識
import math
def feats(S,E,T):
    n=len(S);c=collections.Counter(x[1] for x in S);xs=np.array([x[20] for x in S]);return [100*(c['sleep']+c['drowsy'])/n,100*c['walk']/n,sum(1 for e in E if e['k'] in('gaitTo','route')),sum(1 for e in E if e['k']=='sniff'),float(np.abs(np.diff(xs)).sum())]
X=[];Y=[]
for o in order:
    d=json.load(open(f'../data/ten-{o}.json',encoding='utf-8'))
    for q in range(6):
        a=3+300*q;b=a+300;X.append(feats([x for x in d['S'] if a<x[0]<=b],[e for e in d['E'] if a<e['t']<=b],300));Y.append('動' if d['meta']['restMul']<=.6 else '其他')
X=np.array(X);Z=(X-X.mean(0))/X.std(0);Y=np.array(Y);ok=0
for i in range(len(Z)):
    ds=[]
    for l in ('動','其他'):
        m=[j for j in range(len(Z)) if Y[j]==l and j!=i];ds.append((((Z[i]-Z[m].mean(0))**2).sum(),l))
    ok+=min(ds)[1]==Y[i]
print('只分「薄荷汽水」和「其他八隻」：對 %d/60 = %.0f%%'%(ok,100*ok/60))
# 兩隻兩隻分（5 分鐘）
import itertools
X=[];Y=[]
for o in order:
    d=json.load(open(f'../data/ten-{o}.json',encoding='utf-8'))
    for q in range(6):
        a=3+300*q;b=a+300;X.append(feats([x for x in d['S'] if a<x[0]<=b],[e for e in d['E'] if a<e['t']<=b],300));Y.append(o)
X=np.array(X);Z=(X-X.mean(0))/X.std(0);Y=np.array(Y);acc=[]
for a,b in itertools.combinations(order,2):
    ix=[i for i in range(60) if Y[i] in(a,b)];ok=0
    for i in ix:
        ds=[]
        for l in (a,b):
            m=[j for j in ix if Y[j]==l and j!=i];ds.append((((Z[i]-Z[m].mean(0))**2).sum(),l))
        ok+=min(ds)[1]==Y[i]
    acc.append((ok/len(ix),a,b))
acc.sort(reverse=True);print('兩隻兩隻比（亂猜 50%%）：平均 %.0f%%，前五 %s'%(100*np.mean([x[0] for x in acc]),[(round(x[0]*100),x[1],x[2]) for x in acc[:5]]));print('  到八成以上的配對 %d / 45；其中有薄荷或汽水 %d'%(sum(x[0]>=.8 for x in acc),sum(x[0]>=.8 and (x[1] in('mint','qishui') or x[2] in('mint','qishui')) for x in acc)))
