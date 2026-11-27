import sys,os,json
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE); sys.argv=[sys.argv[0],os.path.join(os.path.dirname(HERE),'webB')]
import vis
from vis import evaljs
from drag import an
js=open(os.path.join(HERE,'vis.js'),encoding='utf-8').read(); DT=1/120
arms=[('現在 lag .22',{}),('起步跟手 0.3R',{'lagLead':.3}),('起步跟手 0.6R',{'lagLead':.6}),('混合 30% 直接',{'lagMix':.3}),('混合 50% 直接',{'lagMix':.5}),('lag .12',{'lag':.12}),('lag .12＋起步 0.3R',{'lag':.12,'lagLead':.3})]
jobs=[];meta=[]
for pos,kw in (('邊緣往上拉',dict(edge=1,dir=[0,-1])),):
    for v in (60,150,300,600):
        for a,o in arms:
            n=12+int((.9 if v<300 else .6 if v==300 else .35)/DT)
            jobs.append(dict(name=f'{v} {a}',n=n,wait=12,v=v,over=o,**kw)); meta.append((v,a,kw['dir']))
r=evaljs(js,dict(occ=48,jobs=jobs),port=8973)
for x,(v,a,d) in zip(r,meta):
    t2,s,gap,ms,modes=an(x,v,12,d)
    print('%3d點/秒 %-18s 動2點 %s ms | 50/100/200/400ms 那塊/手指 %s | 結束落後 %.0f 點=%.0f ms'%(v,a,'%.0f'%t2 if t2 else '-','  '.join(s),gap,ms))
