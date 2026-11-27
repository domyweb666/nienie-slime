import sys,os
sys.stdout.reconfigure(encoding='utf-8')
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from vis import evaljs
js=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'vis.js'),encoding='utf-8').read()
js2=js.replace("const A = run(false), B = run(true);","const A = run(false), B = run(cfg.ctl?false:true);const A2=run(false);let dd=0;for(let i=0;i<A.fr[0].b.length;i++)dd=Math.max(dd,Math.hypot(A.fr[0].b[i][0]-A2.fr[0].b[i][0],A.fr[0].b[i][1]-A2.fr[0].b[i][1]));let d0=0;for(let i=0;i<A.b0.length;i++)d0=Math.max(d0,Math.hypot(A.b0[i][0]-B.b0[i][0],A.b0[i][1]-B.b0[i][1]));out.push({dbg:[dd,d0,t,CAM.x,CAM.y,CAM.z,A.fr[0].N,B.fr[0].N, globalC.xc, globalC.yc, R, SILL.on]});")
r=evaljs(js2,dict(occ=48,ctl=False,jobs=[dict(name='x',n=3)]))
print(r[0])
