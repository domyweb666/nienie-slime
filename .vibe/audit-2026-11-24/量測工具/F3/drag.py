import sys,os,json,math
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from vis import evaljs
js=open(os.path.join(HERE,'vis.js'),encoding='utf-8').read()
DT=1/120
def an(x,v,wait,d):
    rows=x['rows']; p0=rows[wait-1][3]
    def rel(k): # 手指與被抓那塊沿拖動方向走了多少（點）
        q=rows[k][3]; f=(rows[k][4]-x['sx'])*d[0]+(rows[k][5]-x['sy'])*d[1]
        p=(q[0]-p0[0])*d[0]+(q[1]-p0[1])*d[1] if q else float('nan'); return f,p
    t2=tb=None
    b_base=rows[wait-1][1]
    for k in range(wait,len(rows)):
        f,p=rel(k)
        if t2 is None and p>=2: t2=(k-wait+1)*DT*1000; f2=f
    kk=[wait+int(round(ms/1000/DT))-1 for ms in (50,100,200,400)]
    s=[]
    for k in kk:
        if k<len(rows):
            f,p=rel(k); s.append('%.0f/%.0f'%(p,f))
        else: s.append('-')
    f,p=rel(len(rows)-1); gap=f-p
    modes=sorted(set(str(r[6]) for r in rows[wait:]))
    return t2,s,gap,gap/v*1000,modes
if __name__=='__main__':
    arms=[('lag .22（現在）',{}),('lag .12',{'lag':.12}),('lag .05',{'lag':.05}),('lag 0',{'lag':0})]
    jobs=[];meta=[]
    for pos,kw in (('邊緣往上拉',dict(edge=1,dir=[0,-1])),('中間往右拖',dict(dir=[1,0]))):
        for v in (60,150,300,600):
            for an_,o in arms:
                n=12+int(0.6/DT) if v>=300 else 12+int(0.9/DT)
                if v==600: n=12+int(.35/DT)
                jobs.append(dict(name=f'{pos} {v} {an_}',n=n,wait=12,v=v,over=o,**kw)); meta.append((pos,v,an_,kw['dir']))
    r=evaljs(js,dict(occ=48,jobs=jobs))
    json.dump(r,open(os.path.join(HERE,'drag.json'),'w'))
    print('drift(沒碰時外框自己動) max %.3f 點'%max(x['drift'] for x in r))
    print('欄位：被抓那塊走 2 點要多少毫秒（同時手指走了 v*t）；50/100/200/400ms 時「那塊走了/手指走了」點；結束時落後 點＝毫秒')
    for x,(pos,v,a,d) in zip(r,meta):
        t2,s,gap,ms,modes=an(x,v,12,d)
        print('%-8s %3d點/秒 %-12s 動2點 %s ms | %s | 落後 %.0f 點=%.0f ms | %s'%(pos,v,a,'%.0f'%t2 if t2 else '沒到','  '.join(s),gap,ms,','.join(modes)))
