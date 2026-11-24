# 每幀成本：同一個狀態交錯畫各種遮罩，量 JS 時間、加 gl.finish 的總時間、GPU 計時器
from common import *
from playwright.sync_api import sync_playwright
import numpy as np
FIX=BASE+'/fix/prototype/web'
port=freeport();srv=serve(port,FIX)
SETUP='''(d)=>{F2.fresh(1,{shine:0,opaque:.9});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);if(d>0){F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy];for(let s=1;s<=50;s++){e=F2.clampS(sx-.2*d*R*s/50,sy-d*R*s/50);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT)}for(let i=0;i<40;i++)update(F2.DT)}return {N,nb:bnd.length,tri:TRI.length/3,edg:EDG.length/2}}'''
JS='''async (o)=>{const modes=o.modes,K=o.k,gl=JEL.gl,ext=gl.getExtension('EXT_disjoint_timer_query_webgl2'),res={};for(const m of modes)res[m]={js:[],sync:[],gpu:[],full:[]};
 const jr0=jelRender;const px=new Uint8Array(4);
 const P=boundaryPts();const col=n=>getComputedStyle(document.documentElement).getPropertyValue(n).trim();
 draw();const pend=[];
 for(let i=0;i<K;i++)for(const m of modes){JELX.mode=m;
   {const v=viewV();ctx.setTransform(DPR*CAM.z,0,0,DPR*CAM.z,DPR*(v.x-CAM.z*CAM.x),DPR*(v.y-CAM.z*CAM.y))}
   const tr=ctx.getTransform();gl.finish();gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);
   let q=null;if(ext){q=gl.createQuery();gl.beginQuery(ext.TIME_ELAPSED_EXT,q)}
   const t0=performance.now();jelRender(P,tr,col);const t1=performance.now();if(q)gl.endQuery(ext.TIME_ELAPSED_EXT);gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);const t2=performance.now();
   res[m].js.push(t1-t0);res[m].sync.push(t2-t0);if(q)pend.push([m,q]);
   if(i%10===9){await new Promise(r=>setTimeout(r,0))}}
 await new Promise(r=>setTimeout(r,300));for(const [m,q] of pend)if(gl.getQueryParameter(q,gl.QUERY_RESULT_AVAILABLE))res[m].gpu.push(gl.getQueryParameter(q,gl.QUERY_RESULT)/1e6);
 const disj=ext?gl.getParameter(ext.GPU_DISJOINT_EXT):null;
 // 整個 update、draw
 const up=[],dr=[];for(let i=0;i<120;i++){const t0=performance.now();update(1/60);const t1=performance.now();JELX.mode=0;draw();const t2=performance.now();up.push(t1-t0);dr.push(t2-t1)}
 return {res,up,dr,disj,ext:!!ext}}'''
def st(a):
    a=np.array(a);return 'n%d p10 %.2f 中位 %.2f p90 %.2f'%(len(a),np.percentile(a,10),np.median(a),np.percentile(a,90)) if len(a) else 'none'
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    pg.evaluate("()=>{JELX.smooth=0}")
    for d in (0,4.5):
        print('pull',d,pg.evaluate(SETUP,d))
        r=pg.evaluate(JS,{'modes':[0,1,2,3,5],'k':80})
        for m in r['res']:
            print('  mode',m,'| JS ms',st(r['res'][m]['js']),'| JS+等 GPU',st(r['res'][m]['sync']),'| GPU 計時',st(r['res'][m]['gpu']))
        print('  update',st(r['up']),'| draw',st(r['dr']),'| timer ext',r['ext'],'disjoint',r['disj'])
    print(errs);b.close()
srv.shutdown()
