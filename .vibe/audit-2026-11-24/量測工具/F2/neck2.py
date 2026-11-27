# 細脖子量測：兩顆 0.6R 的圓用寬 w 的直條連起來，量皮在直條中間還在不在、顏色跟背景差多少
from common import *
from playwright.sync_api import sync_playwright
import base64
JS='''async ({shine,opaque,round,zoom,ws,len,bg})=>{
 F2.fresh(1,{shine,opaque,round});VIEW.bg=bg;await new Promise(r=>setTimeout(r,400));
 const jp=jelPath,bp=boundaryPts;const out=[];const z=zoom;
 // 量背景：路徑放到畫面外
 const W1=F2.W1,H1=F2.H1;
 const x0=W1/2,y0=H1*.45,Rr=R*z,half=len*Rr/2;
 const shape=(w)=>{jelPath=(m)=>{m.beginPath();if(w==null){m.rect(-5000,-5000,1,1);return}
   // 世界座標：畫面 = (世界-CAM)*CAM.z+v
   const v=viewV(),wx=(sx)=>(sx-v.x)/CAM.z+CAM.x,wy=(sy)=>(sy-v.y)/CAM.z+CAM.y,s=1/CAM.z;
   const r0=.6*Rr;m.arc(wx(x0),wy(y0-half),r0*s,0,7);m.closePath();m.moveTo(wx(x0)+r0*s,wy(y0+half));m.arc(wx(x0),wy(y0+half),r0*s,0,7);m.closePath();m.rect(wx(x0-w/2),wy(y0-half),w*s,2*half*s)};
   boundaryPts=()=>{const v=viewV(),wx=(sx)=>(sx-v.x)/CAM.z+CAM.x,wy=(sy)=>(sy-v.y)/CAM.z+CAM.y;return [[wx(x0-Rr),wy(y0-half-Rr)],[wx(x0+Rr),wy(y0-half-Rr)],[wx(x0+Rr),wy(y0+half+Rr)],[wx(x0-Rr),wy(y0+half+Rr)]]}};
 const px=()=>{const k=document.createElement('canvas');k.width=W1;k.height=H1;const g=k.getContext('2d',{willReadFrequently:true});g.drawImage(cv,0,0,W1,H1);return g.getImageData(0,0,W1,H1).data};
 const fe=mat.eyes;mat.eyes=0;const vf=VIEW.face;VIEW.face=0;
 const s0=IV.s,px0=INTRO.px,py0=INTRO.py;
 if(z!==1){IV.s=z;INTRO.px=CAM.x;INTRO.py=CAM.y}
 shape(null);draw();const B=px();
 for(const w of ws){shape(w);draw();F2.readSkin();const D=px();let mn=1,diff=[0,0],n=0;const y1=Math.round(y0-.15*Rr),y2=Math.round(y0+.15*Rr);let wide=0;
   for(let y=y1;y<=y2;y++){const i=y*W1+Math.round(x0);mn=Math.min(mn,F2.skin[i]);const p=i*4;diff[0]+=Math.abs(D[p]-B[p])+Math.abs(D[p+1]-B[p+1])+Math.abs(D[p+2]-B[p+2]);n++;let c=0;for(let x=0;x<W1;x++)c+=F2.skin[y*W1+x];wide+=c}
   out.push({w,wR:+(w/Rr).toFixed(3),alive:mn,shown:+(wide/n).toFixed(1),diff:+(diff[0]/n/3).toFixed(1),col:[...D.slice((Math.round(y0)*W1+Math.round(x0))*4,(Math.round(y0)*W1+Math.round(x0))*4+3)]})}
 jelPath=jp;boundaryPts=bp;IV.s=1;mat.eyes=fe;VIEW.face=vf;
 const k=Math.round(y0)*W1+Math.round(x0);
 return {R:Rr,out,bg:[...B.slice(k*4,k*4+3)]}}'''
FIX=BASE+'/fix/prototype/web';port=freeport();srv=serve(port,FIX)
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    for cfg in [dict(shine=0,opaque=.9,round=1.3,zoom=1,t=0),dict(shine=0,opaque=.9,round=1.3,zoom=1,t=1)]:
        pg.evaluate('(t)=>{JELX.mode=0;JELX.thinOpq=t}',cfg['t']);ws=[round(x*106.11,2) for x in (.13,.15,.18,.2,.25,.3,.35,.4,.5,.6,.8,1.2)]
        r=pg.evaluate(JS,{**cfg,'ws':ws,'len':3,'bg':'day'})
        print(cfg,'R',round(r['R'],1),'bg',r['bg'])
        for o in r['out']: print('   w=%.3fR (%.1fpx) shown=%.1fpx diff=%.1f col=%s'%(o['wR'],o['w'],o['shown'],o['diff'],o['col']))
    print(errs);b.close()
srv.shutdown()
