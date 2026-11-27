import os, sys, json, shutil, threading, http.server, functools, time
import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright
sys.stdout.reconfigure(encoding='utf-8')
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = r'E:\捏捏史萊姆\nienie-slime\prototype\web\_wt\prototype\web'
D = os.path.join(HERE, 'web'); os.makedirs(D, exist_ok=True)
shutil.copy(os.path.join(SRC, 'index.html'), os.path.join(D, 'index.html'))
import glob
for q in glob.glob(os.path.join(SRC,'*.js')): shutil.copy(q, D)
for sub in [x for x in os.listdir(SRC) if os.path.isdir(os.path.join(SRC,x)) and x not in ('archive','_wt')]:
    if os.path.isdir(os.path.join(SRC, sub)) and not os.path.isdir(os.path.join(D, sub)): shutil.copytree(os.path.join(SRC, sub), os.path.join(D, sub))
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
srv = http.server.ThreadingHTTPServer(('127.0.0.1', 8997), functools.partial(H, directory=D)); threading.Thread(target=srv.serve_forever, daemon=True).start()

DUMP = r'''()=>{draw();const gl=JEL.gl,M=SKIN.m,w=worldWalls();
 gl.bindFramebuffer(gl.FRAMEBUFFER,M.ft);const px=new Uint8Array(W*H*4);gl.readPixels(0,0,W,H,gl.RGBA,gl.UNSIGNED_BYTE,px);gl.bindFramebuffer(gl.FRAMEBUFFER,null);
 const r=new Array(W*H);for(let i=0;i<W*H;i++)r[i]=px[4*i];
 const P=boundaryPts();
 return {W,H,N,R,cam:[CAM.z,CAM.x,CAM.y],vv:[viewV().x,viewV().y],X:[...X],Y:[...Y],bnd:[...bnd],TRI:[...TRI],EDG:[...EDG],Q0X:[...Q0X],Q0Y:[...Q0Y],P:P.map(p=>[p[0],p[1]]),
  walls:[w.l,w.r,w.b].map(v=>isFinite(v)?v:null),v:[...M.v],ix:[...M.ix],g:[...M.g],rad:[...M.rad],mask:r,key:M.key===TRI}}'''

# the Swift code of SkinMesh.update / clip, line by line
PORT = r'''(S)=>{const f=Math.fround,n=S.N,nb=S.bnd.length,bnd=S.bnd,t=S.TRI,e=S.EDG;
 const at=new Array(n).fill(-1);for(let k=0;k<nb;k++)at[bnd[k]]=k;
 const near=[];for(let i=0;i<n;i++){if(at[i]>=0){near[i]=at[i];continue}let bd=Infinity,bk=0;for(let k=0;k<nb;k++){const dx=S.Q0X[bnd[k]]-S.Q0X[i],dy=S.Q0Y[bnd[k]]-S.Q0Y[i],d=dx*dx+dy*dy;if(d<bd){bd=d;bk=k}}near[i]=bk}
 const third=new Array(nb).fill(-1);for(let q=0;q+2<t.length;q+=3)for(let s=0;s<3;s++){const a=t[q+s],b=t[q+(s+1)%3],c=t[q+(s+2)%3],ka=at[a],kb=at[b];if(ka<0||kb<0)continue;if(kb===(ka+1)%nb)third[ka]=c;else if(ka===(kb+1)%nb)third[kb]=c}
 const zoom=S.zoom,ox=S.ox,oy=S.oy,R=S.R*zoom;
 const vp=[];for(let i=0;i<n;i++)vp[i]=[f(S.X[i]*zoom+ox),f(S.Y[i]*zoom+oy)];
 const rp=[];for(let k=0;k<nb;k++){const s=[f(S.P[k][0]*zoom+ox),f(S.P[k][1]*zoom+oy)];vp[bnd[k]]=s;rp[k]=s}
 const np=[];for(let k=0;k<nb;k++){const q=third[k];if(q<0){np[k]=[0,0];continue}const a=rp[k],b=rp[k+1===nb?0:k+1],c=vp[q];const ex=f(b[0]-a[0]),ey=f(b[1]-a[1]),tx=f(c[0]-a[0]),ty=f(c[1]-a[1]);const side=f(f(ex*ty)-f(ey*tx))>=0?1:-1,len=f(Math.sqrt(f(f(ex*ex)+f(ey*ey)))),l=len>0?len:1;np[k]=[f(f(-ey/l)*side),f(f(ex/l)*side)]}
 const Rf=f(R),lim=f(f(.3)*Rf),far=f((lim+60)*(lim+60)),on=f(f(.26)*Rf),span=f(f(.10)*Rf),gp=[];
 for(let k=0;k<nb;k++){const n0=np[k],n1=np[k===0?nb-1:k-1],sx=f(n0[0]+n1[0]),sy=f(n0[1]+n1[1]),d=f(Math.sqrt(f(f(sx*sx)+f(sy*sy))));if(d<1e-4){gp[k]=1;continue}const nx=f(sx/d),ny=f(sy/d),px=rp[k][0],py=rp[k][1];let best=lim;
  for(let m=0;m<nb;m++){const m1=m+1===nb?0:m+1;if(m===k||m1===k)continue;const ax=f(rp[m][0]-px),ay=f(rp[m][1]-py),bx=f(rp[m1][0]-px),by=f(rp[m1][1]-py),da=f(f(ax*ax)+f(ay*ay)),db=f(f(bx*bx)+f(by*by));if(Math.min(da,db)>far)continue;const ex=f(bx-ax),ey=f(by-ay),den=f(f(nx*ey)-f(ny*ex));if(Math.abs(den)<1e-9)continue;const tt=f(f(f(ax*ey)-f(ay*ex))/den),u=f(f(f(ax*ny)-f(ay*nx))/den);if(tt>.5&&u>=0&&u<=1&&tt<best)best=tt}
  gp[k]=Math.max(0,Math.min(1,f(f(on-best)/span)))}
 const cl=S.walls[0]!=null?S.walls[0]*zoom+ox:-Infinity,cr=S.walls[1]!=null?S.walls[1]*zoom+ox:Infinity,cb=S.walls[2]!=null?S.walls[2]*zoom+oy:Infinity,rr=f(R*.12/2);
 const ip=vp.map(p=>[p[0],p[1]]);for(let k=0;k<nb;k++){const n0=np[k],n1=np[k===0?nb-1:k-1],sx=f(n0[0]+n1[0]),sy=f(n0[1]+n1[1]),d=f(Math.sqrt(f(f(sx*sx)+f(sy*sy))));if(d<1e-4)continue;const s=rp[k];ip[bnd[k]]=[f(s[0]+f(f(sx/d)*rr)),f(s[1]+f(f(sy/d)*rr))]}
 if(isFinite(cb)){const yb=f(f(cb)-rr);for(let i=0;i<n;i++)if(ip[i][1]>yb)ip[i][1]=yb}
 const caps=[];for(let q=0;q+1<e.length;q+=2){const i=e[q],j=e[q+1],rad=f(Math.max(gp[near[i]],gp[near[j]])*rr);if(rad>=.05)caps.push([ip[i][0],ip[i][1],ip[j][0],ip[j][1],rad])}
 // compare with the web's own numbers
 let dv=0,di=0,dg=0;for(let i=0;i<n;i++){dv=Math.max(dv,Math.abs(vp[i][0]-S.v[2*i]),Math.abs(vp[i][1]-S.v[2*i+1]));di=Math.max(di,Math.abs(ip[i][0]-S.ix[2*i]),Math.abs(ip[i][1]-S.ix[2*i+1]))}for(let k=0;k<nb;k++)dg=Math.max(dg,Math.abs(gp[k]-S.g[k]));
 let webCaps=0;for(const r of S.rad)if(r*R*.06>=.05)webCaps++;
 // the clip path: outline polygon + flipped triangles twice (+ capsules), non-zero, against the triangles one by one
 const mk=()=>{const c=document.createElement('canvas');c.width=S.W;c.height=S.H;return c.getContext('2d',{willReadFrequently:true})};
 let flip=0;const A=mk(),B=mk();A.beginPath();
 for(let q=0;q+2<t.length;q+=3){const a=vp[t[q]],b=vp[t[q+1]],c=vp[t[q+2]];if(f((b[0]-a[0])*(c[1]-a[1]))-f((b[1]-a[1])*(c[0]-a[0]))>-.5)continue;flip++;A.moveTo(a[0],a[1]);for(const p of [c,b,a,c,b])A.lineTo(p[0],p[1]);A.closePath()}
 let capP=0;for(let k=0;k<nb;k++){const k1=k+1===nb?0:k+1,r=Math.max(gp[k],gp[k1])*rr;if(r<.5)continue;capP++;const a=ip[bnd[k]],b=ip[bnd[k1]],dx=b[0]-a[0],dy=b[1]-a[1],l=Math.hypot(dx,dy),ux=l>1e-5?dx/l*r:r,uy=l>1e-5?dy/l*r:0;A.moveTo(a[0]+uy,a[1]-ux);A.lineTo(b[0]+uy,b[1]-ux);A.lineTo(b[0]+ux,b[1]+uy);A.lineTo(b[0]-uy,b[1]+ux);A.lineTo(a[0]-uy,a[1]+ux);A.lineTo(a[0]-ux,a[1]-uy);A.closePath()}
 A.moveTo(rp[0][0],rp[0][1]);for(let k=1;k<nb;k++)A.lineTo(rp[k][0],rp[k][1]);A.closePath();A.fill();
 for(let q=0;q+2<t.length;q+=3){const a=vp[t[q]],b=vp[t[q+1]],c=vp[t[q+2]];B.beginPath();B.moveTo(a[0],a[1]);B.lineTo(b[0],b[1]);B.lineTo(c[0],c[1]);B.closePath();B.fill()}
 const ap=A.getImageData(0,0,S.W,S.H).data;const C=mk();C.beginPath();C.moveTo(rp[0][0],rp[0][1]);for(let k=1;k<nb;k++)C.lineTo(rp[k][0],rp[k][1]);C.closePath();C.fill();const cp=C.getImageData(0,0,S.W,S.H).data;
 // web mask rows run bottom-up
 let miss=0,missOld=0,extra=0,area=0;for(let y=0;y<S.H;y++)for(let x=0;x<S.W;x++){const m=S.mask[(S.H-1-y)*S.W+x],a=ap[4*(y*S.W+x)+3],o=cp[4*(y*S.W+x)+3];if(m>200)area++;if(m>250&&a<40)miss++;if(m>250&&o<40)missOld++;if(m<5&&a>215)extra++}
 return {dv,di,dg,caps,webCaps,flip,capP,miss,missOld,extra,area,tri:t.length/3,vp:vp.flat(),n,nb,clip:[cl,cr,cb].map(v=>isFinite(v)?v:null)}}'''

def raster(S, P):
    W, Hh = S['W'], S['H']
    vp = np.array(P['vp']).reshape(-1, 2); tri = np.array(S['TRI']).reshape(-1, 3)
    off = [(.375, .125), (.875, .375), (.125, .625), (.625, .875)]   # Metal's and D3D's standard 4x pattern
    buf = np.zeros((4, Hh, W), np.float32)
    for a, b, c in vp[tri]:
        x0, x1 = int(max(0, np.floor(min(a[0], b[0], c[0])))), int(min(W, np.ceil(max(a[0], b[0], c[0])) + 1))
        y0, y1 = int(max(0, np.floor(min(a[1], b[1], c[1])))), int(min(Hh, np.ceil(max(a[1], b[1], c[1])) + 1))
        if x0 >= x1 or y0 >= y1: continue
        s = (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])
        if s == 0: continue
        yy, xx = np.mgrid[y0:y1, x0:x1]
        for q, (dx, dy) in enumerate(off):
            px, py = xx + dx, yy + dy
            w0 = ((b[0]-a[0])*(py-a[1]) - (b[1]-a[1])*(px-a[0])) / s
            w1 = ((c[0]-b[0])*(py-b[1]) - (c[1]-b[1])*(px-b[0])) / s
            w2 = ((a[0]-c[0])*(py-c[1]) - (a[1]-c[1])*(px-c[0])) / s
            buf[q, y0:y1, x0:x1][(w0 >= 0) & (w1 >= 0) & (w2 >= 0)] = 1
    cl, cr, cb = P['clip']
    sx0 = int(np.floor(max(0, min(W, cl if cl is not None else -1)))); sx1 = int(np.ceil(max(0, min(W, cr if cr is not None else 1e9)))); sy1 = int(np.ceil(max(1, min(Hh, (cb if cb is not None else 1e9) + 1))))
    for ax, ay, bx, by, r in P['caps']:
        x0, x1 = int(max(sx0, np.floor(min(ax, bx) - r - 2))), int(min(sx1, np.ceil(max(ax, bx) + r + 2)))
        y0, y1 = int(max(0, np.floor(min(ay, by) - r - 2))), int(min(sy1, np.ceil(max(ay, by) + r + 2)))
        if x0 >= x1 or y0 >= y1: continue
        yy, xx = np.mgrid[y0:y1, x0:x1]
        px, py = xx + .5, yy + .5; dx, dy = bx - ax, by - ay
        h = np.clip(((px-ax)*dx + (py-ay)*dy) / max(dx*dx + dy*dy, 1e-6), 0, 1)
        o = np.clip(r + .5 - np.hypot(px-ax-dx*h, py-ay-dy*h), 0, 1)
        buf[:, y0:y1, x0:x1] = np.maximum(buf[:, y0:y1, x0:x1], o)
    return buf.mean(0)

with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r'C:\Program Files\Google\Chrome\Application\chrome.exe', headless=True, args=['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist'])
    pg = br.new_page(viewport={'width': 393, 'height': 852}, device_scale_factor=2)
    errs = []; pg.on('pageerror', lambda e: errs.append(str(e)[:150]))
    pg.goto('http://127.0.0.1:8997/index.html'); pg.wait_for_timeout(6000)
    out = []
    def snap(name):
        S = pg.evaluate(DUMP)
        z, cx, cy = S['cam']; S['zoom'] = z; S['ox'] = S['vv'][0] - cx * z; S['oy'] = S['vv'][1] - cy * z
        P = pg.evaluate(PORT, S)
        M = raster(S, P); w = np.array(S['mask'], np.float32).reshape(S['H'], S['W'])[::-1] / 255
        d = np.abs(M - w)
        out.append((name, S['N'], P['nb'], P['tri'], len(P['caps']), P['webCaps'], round(P['dv'], 5), round(P['di'], 5), round(P['dg'], 5), float(d.mean()), int((d > .3).sum()), P['area'], P['flip'], P['capP'], P['miss'], P['missOld'], P['extra']))
        print(out[-1], flush=True)
        if (name.startswith('two') or name.startswith('far')): Image.fromarray((np.hstack([M, w, d]) * 255).astype(np.uint8)).save(os.path.join(HERE, name + '.png'))
    print('name N nb tri caps webCaps dv di dg meanAbs px>.3 area flip capP miss missOutlineOnly extra')
    snap('rest')
    c = pg.evaluate('()=>{let x=0,y=0;for(const i of bnd){x+=X[i];y+=Y[i]}const z=CAM.z,v=viewV();return [(x/bnd.length-CAM.x)*z+v.x,(y/bnd.length-CAM.y)*z+v.y,R*z]}')
    EV = '''([t,id,x,y])=>{const e=new PointerEvent(t,{pointerId:id,clientX:x,clientY:y,bubbles:true,pointerType:'touch',isPrimary:id===11,width:30,height:30,buttons:1});cv.dispatchEvent(e)}'''
    def ev(t, i, x, y): pg.evaluate(EV, [t, i, x, y])
    for run in range(3):
        ev('pointerdown', 11, c[0] - c[2]*.6, c[1]); ev('pointerdown', 12, c[0] + c[2]*.6, c[1])
        for k in range(1, 41):
            u = k / 40
            ev('pointermove', 11, c[0] - c[2]*.6 - u*130, c[1] - u*(120 + 150*run)); ev('pointermove', 12, c[0] + c[2]*.6 + u*130, c[1] - u*(300 - 200*run)); pg.wait_for_timeout(16)
            if k in (20, 40): snap('two%d_%d' % (run, k))
        pg.wait_for_timeout(600); snap('two%d_hold' % run)
        ev('pointerup', 11, c[0], c[1]); ev('pointerup', 12, c[0], c[1]); pg.wait_for_timeout(60); snap('two%d_rel' % run); pg.wait_for_timeout(3500)
    for run in range(2):
        ev('pointerdown', 11, c[0], c[1] - c[2]*.5)
        for k in range(1, 31):
            ev('pointermove', 11, c[0] + (150 if k % 10 < 5 else -150), c[1] - k*18); pg.wait_for_timeout(16)
        snap('far%d' % run); ev('pointermove', 11, c[0], c[1] + 250); pg.wait_for_timeout(50); snap('far%d_back' % run); ev('pointerup', 11, c[0], c[1]); pg.wait_for_timeout(3000)
    print('errors', errs[:5]); br.close()
srv.shutdown()
