# 停住不動時補點：補點前一格、後 1、2、8 格的外框疊在一起（原本 vs 家跟著移）
from common import *
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw,ImageFont
import numpy as np
JS='''async (seeds)=>{const out=[];for(const s of seeds){F2.fresh(s,{shine:0,opaque:.9});let hist=[],cur=null,hold=0;GEST.CALM(s,(ph)=>{const n0=REM.n,t0=TRI;update(F2.DT);hold=ph==='hold'?hold+1:0;const P=boundaryPts().map(p=>F2.scr(p[0],p[1]));hist.push(P);if(hist.length>4)hist.shift();const f=[...fingers.values()][0];
  if(!cur&&TRI!==t0&&REM.n>0&&hold>12)cur={s,k:0,polys:[hist[hist.length-2],P],f:f?[f.sx,f.sy]:null};else if(cur){cur.k++;if(cur.k===1||cur.k===8)cur.polys.push(P);if(cur.k===8){out.push(cur);cur=null}}});for(const id of [...fingers.keys()])F2.ev('pointerup',id,0,0);if(out.length>=3)break}return out}'''
res={}
for name,d in (('現在','prototype/web'),('家跟著移','fix7/prototype/web')):
    port=freeport();srv=serve(port,BASE+'/'+d)
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        res[name]=pg.evaluate(JS,list(range(1,25)));b.close()
    srv.shutdown()
ft=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',18)
W,H=393,700;cols=[(120,120,120),(220,60,60),(255,150,0),(30,110,220)];lab=['補點前一格','補點那格','後 1 格','後 8 格']
C=Image.new('RGB',(W*6,H+60),'white');d=ImageDraw.Draw(C)
for a,(name,L) in enumerate(res.items()):
    for i,q in enumerate(L[:3]):
        ox=(a*3+i)*W
        for pl,c in zip(q['polys'],cols): d.line([(x+ox,y+50) for x,y in pl+pl[:1]],fill=c,width=2)
        if q['f']: x,y=q['f'];d.ellipse((ox+x-8,y+50-8,ox+x+8,y+50+8),outline=(200,0,200),width=2)
        def cen(P):
            P=np.array(P);x,y=P.T;x2,y2=np.roll(x,-1),np.roll(y,-1);cr=x*y2-x2*y;A=cr.sum();return np.array([((x+x2)*cr).sum()/(3*A),((y+y2)*cr).sum()/(3*A)])
        c0=cen(q['polys'][0]);txt=' '.join('%.0f'%np.hypot(*(cen(P)-c0)) for P in q['polys'][1:]);d.text((ox+10,4),name+'　重心離補點前：'+txt+' 點',font=ft,fill='black')
for c,l,x in zip(cols,lab,(10,150,290,400)): d.text((x,28),l,font=ft,fill=c)
C.resize((C.width*2//3,C.height*2//3)).save(BASE+'/../F2-補點那一格.jpg',quality=88)
for n,L in res.items(): print(n,len(L))
