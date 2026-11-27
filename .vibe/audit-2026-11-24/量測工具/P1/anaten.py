# anaten.py：十隻，只看行為分不分得出來
import sys, json, math, collections, glob, os
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
MM=.1656
fs=sorted(glob.glob('../data/ten-*.json'));ids=[];X=[];Y=[]
order=['honey','mint','taro','peach','xiancao','tangyuan','diedou','qishui','buding','zhennai']
name=dict(honey='蜜蜜',mint='薄荷',taro='芋圓',peach='桃桃',xiancao='仙草',tangyuan='湯圓',diedou='蝶豆',qishui='汽水',buding='布丁',zhennai='珍奶')
desc=dict(honey='慢吞吞最愛睡',mint='好動到處跑',taro='怕生熟了黏',peach='愛撒嬌常來',xiancao='酷慢熟',tangyuan='愛睡',diedou='怕生',qishui='停不下來',buding='膽小',zhennai='貪吃')
feat=['睡%','休息%','張望%','走%','睡次/時','醒一輪秒','走次/時','走mm/時','探/時','位移sd mm','招呼/時','眨眼/分']
def features(S,E,T):
    n=len(S);c=collections.Counter(r[1] for r in S);xs=np.array([r[20] for r in S])
    so=[e['t'] for e in E if e['k']=='sleepOn'];iv=np.diff(so)
    return [100*(c['sleep']+c['drowsy'])/n,100*c['rest']/n,100*c['look']/n,100*c['walk']/n,len(so)/T*3600,float(iv.mean()) if len(iv) else 999,sum(1 for e in E if e['k'] in('gaitTo','route'))/T*3600,float(np.abs(np.diff(xs)).sum())*MM/T*3600,sum(1 for e in E if e['k']=='sniff')/T*3600,float(xs.std())*MM,sum(1 for e in E if e['k']=='e4' and e['ph'])/T*3600,sum(1 for e in E if e['k']=='blink')/T*60]
print('%-6s %s'%('',' '.join('%9s'%f for f in feat)))
for o in order:
    f=f'../data/ten-{o}.json'
    if not os.path.exists(f): continue
    d=json.load(open(f,encoding='utf-8'));S=d['S'];E=d['E'];F=features(S,E,1800)
    print('%-6s %s  %s %s'%(name[o],' '.join('%9.1f'%v for v in F),desc[o],{k:d['meta'][k] for k in('restMul','dash','mat')}))
    for k in range(6):
        a=3+300*k;b=a+300;s=[r for r in S if a<r[0]<=b];e=[x for x in E if a<x['t']<=b];v=features(s,e,300);v[5]=0;X.append(v);Y.append(o)
X=np.array(X);Y=np.array(Y)
if len(X):
    keep=[i for i in range(X.shape[1]) if X[:,i].std()>1e-9 and i!=5];Z=(X[:,keep]-X[:,keep].mean(0))/X[:,keep].std(0)
    labs=sorted(set(Y));ok=0;conf=collections.Counter();ok3=0
    for i in range(len(Z)):
        d=[]
        for l in labs:
            m=[j for j in range(len(Z)) if Y[j]==l and j!=i];d.append((float(((Z[i]-Z[m].mean(0))**2).sum()),l))
        d.sort();pr=d[0][1];ok+=pr==Y[i];ok3+=Y[i] in [x[1] for x in d[:3]];conf[(Y[i],pr)]+=1
    print('看 5 分鐘行為猜是哪一隻（留一法、最近中心）：對 %d/%d = %.0f%%（亂猜 %.0f%%）；前三名含對 %.0f%%'%(ok,len(Z),100*ok/len(Z),100/len(labs),100*ok3/len(Z)))
    for l in labs: print('  ',name[l],'對',conf[(l,l)],'/6 常被猜成',[(name[b],v) for (a,b),v in conf.most_common() if a==l and b!=l][:2])
    # 每個特徵：隻與隻之間的變異佔比（eta^2）
    print('每個特徵裡「是哪一隻」解釋的變異比例（eta²）：')
    for i in keep:
        g=X[:,i].mean();sb=sum((X[Y==l,i].mean()-g)**2*(Y==l).sum() for l in labs);st=((X[:,i]-g)**2).sum();print('   %-10s %.2f'%(feat[i],sb/st))
