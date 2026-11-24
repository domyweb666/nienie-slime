import sys,os,json,math
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
import vis
from vis import evaljs
js=open(os.path.join(HERE,'vis.js'),encoding='utf-8').read()
jobs=[]
for nm,o,v in (('關活物 中間慢拖 60',{},60),('關活物 中間慢拖 30',{},30),('關活物 中間不動',{},0),('開活物 中間慢拖 60',{'life':.8,'life2':1,'emo':1,'morph':1,'wriggle':.05,'pods':2,'jelly':1,'drift':.14},60),('開活物 中間不動',{'life':.8,'life2':1,'emo':1,'morph':1,'wriggle':.05,'pods':2,'jelly':1,'drift':.14},0),('關活物 中間慢拖 60 grabReach0',{'grabReach':0},60),('關活物 中間慢拖 60 noFlip0',{'noFlip':0},60),('關活物 中間慢拖 60 localArea0',{'localArea':0},60),('關活物 中間慢拖 60 press2=0',{'press2':0},60)):
    jobs.append(dict(name=nm,n=140,wait=12,v=v,dir=[1,0],over=o))
r=evaljs(js,dict(occ=48,jobs=jobs),port=8975)
for x in r:
    rows=x['rows'];mx=0;at=0
    for k in range(14,len(rows)):
        a,b=rows[k-1][3],rows[k][3]
        if a and b:
            d=math.hypot(b[0]-a[0],b[1]-a[1])
            if d>mx: mx=d;at=k/120
    ys=[q[3][1]-rows[11][3][1] for q in rows[12:] if q[3]]
    print('%-28s 那塊一格最多跳 %.2f 點（在 %.2f 秒）；垂直偏移最大 %.1f 點'%(x['name'],mx,at,max(abs(y) for y in ys)))
