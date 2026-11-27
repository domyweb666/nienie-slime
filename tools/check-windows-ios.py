# 離線檢查 iOS 的窗景：只讀 windows.json 和 webp，用 WebGL 照 iPhone（Metal）的步驟重畫，跟網頁 winDraw 同一秒比。
# 用法：python tools/check-windows-ios.py [並排圖資料夾] [--t 0,1.3,7.7,23.1] [--scale 1.5]
# 預乘 alpha，混合式固定四種：over (1, 1−a)、add (1, 1)、multiply (目的色, 1−a)、screen (1, 1−來源色)。
import sys, os, io, json, base64, threading, http.server, socketserver, functools, argparse
sys.stdout.reconfigure(encoding='utf-8')
import numpy as np
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB, RES = os.path.join(ROOT, 'prototype', 'web'), os.path.join(ROOT, 'ios', 'NieNie', 'Resources', 'win')
CH = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
GL = r"""
window.setupGL=async (w,h)=>{
 const c=document.createElement('canvas');c.width=w;c.height=h;const gl=c.getContext('webgl2',{alpha:false,antialias:false,preserveDrawingBuffer:true,premultipliedAlpha:true});
 const sh=(t,s)=>{const o=gl.createShader(t);gl.shaderSource(o,s);gl.compileShader(o);if(!gl.getShaderParameter(o,gl.COMPILE_STATUS))throw new Error(gl.getShaderInfoLog(o));return o};
 const pr=gl.createProgram();
 gl.attachShader(pr,sh(gl.VERTEX_SHADER,`#version 300 es
 uniform vec4 M0,B;uniform vec2 M1,RES;uniform vec4 C0;uniform vec2 C1;out vec2 uv,lp,cp;
 void main(){vec2 q=vec2(gl_VertexID&1,gl_VertexID>>1);uv=q;lp=B.xy+q*B.zw;
  vec2 p=vec2(M0.x*lp.x+M0.z*lp.y+M1.x,M0.y*lp.x+M0.w*lp.y+M1.y);cp=vec2(C0.x*lp.x+C0.z*lp.y+C1.x,C0.y*lp.x+C0.w*lp.y+C1.y);
  gl_Position=vec4(p.x/RES.x*2.-1.,1.-p.y/RES.y*2.,0,1);}`));
 gl.attachShader(pr,sh(gl.FRAGMENT_SHADER,`#version 300 es
 precision highp float;in vec2 uv,lp,cp;out vec4 o;uniform sampler2D T;uniform float A;uniform int MODE;uniform vec3 CL;uniform vec4 SEG,COL;uniform float HW;
 void main(){vec4 s;
  if(MODE==1){vec2 a=SEG.xy,d=SEG.zw-a;float l=max(dot(d,d),1e-6);float k=clamp(dot(lp-a,d)/l,0.,1.);float q=length(lp-a-d*k);float f=max(fwidth(q),1e-4);float e=clamp((HW-q)/f+.5,0.,1.);s=vec4(COL.rgb,1.)*COL.a*e;}
  else s=texture(T,uv);
  s*=A;
  if(CL.z>0.){float q=length(cp-CL.xy),f=max(fwidth(q),1e-4);s*=clamp((CL.z-q)/f+.5,0.,1.);}
  o=s;}`));
 gl.linkProgram(pr);if(!gl.getProgramParameter(pr,gl.LINK_STATUS))throw new Error(gl.getProgramInfoLog(pr));gl.useProgram(pr);
 const u={};for(const n of ['M0','M1','B','RES','C0','C1','A','MODE','CL','SEG','COL','HW'])u[n]=gl.getUniformLocation(pr,n);
 gl.bindVertexArray(gl.createVertexArray());gl.viewport(0,0,w,h);gl.enable(gl.BLEND);gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL,gl.NONE);
 window.G={c,gl,u,w,h,tex:{},data:await(await fetch('windows.json')).json()}};
const bez=(e,x)=>{const[x1,y1,x2,y2]=e,f=(u,p,q)=>3*(1-u)*(1-u)*u*p+3*(1-u)*u*u*q+u*u*u;let lo=0,hi=1;for(let i=0;i<18;i++){const m=(lo+hi)/2;if(f(m,x1,x2)<x)lo=m;else hi=m}return f((lo+hi)/2,y1,y2)};
const val=(t,T)=>{let p=(T-t.b)/t.d;p-=Math.floor(p);const n=t.v.length;let i=0;while(i<n-2&&p>=t.k[i+1])i++;const d=t.k[i+1]-t.k[i];let u=d>0?Math.min(1,Math.max(0,(p-t.k[i])/d)):1;if(t.e)u=bez(t.e[i],u);return t.v[i].map((a,j)=>a+(t.v[i+1][j]-a)*u)};
const mul=(m,n)=>[m[0]*n[0]+m[2]*n[1],m[1]*n[0]+m[3]*n[1],m[0]*n[2]+m[2]*n[3],m[1]*n[2]+m[3]*n[3],m[0]*n[4]+m[2]*n[5]+m[4],m[1]*n[4]+m[3]*n[5]+m[5]];
const inv=m=>{const d=m[0]*m[3]-m[1]*m[2];return[m[3]/d,-m[1]/d,-m[2]/d,m[0]/d,(m[2]*m[5]-m[3]*m[4])/d,(m[1]*m[4]-m[0]*m[5])/d]};
const opm=(o,T)=>{if(o.k==='m')return o.v;const v=val(o.t,T),a=v[0]*Math.PI/180;
 if(o.k==='translate')return[1,0,0,1,v[0],v[1]];if(o.k==='scale')return[v[0],0,0,v[1],0,0];if(o.k==='skewX')return[1,0,Math.tan(a),1,0,0];
 const c=Math.cos(a),s=Math.sin(a),x=v[1],y=v[2];return[c,s,-s,c,x-c*x+s*y,y-s*x-c*y]};
const tex=async n=>{if(G.tex[n])return G.tex[n];const gl=G.gl,b=await createImageBitmap(await(await fetch(n+'.webp')).blob(),{premultiplyAlpha:'premultiply',colorSpaceConversion:'none'}),t=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,t);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,b);
 for(const[k,v]of[[gl.TEXTURE_MIN_FILTER,gl.LINEAR],[gl.TEXTURE_MAG_FILTER,gl.LINEAR],[gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE],[gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE]])gl.texParameteri(gl.TEXTURE_2D,k,v);return G.tex[n]=t};
window.drawGL=async (key,T,S)=>{const{gl,u,w,h}=G;gl.clearColor(0,0,0,1);gl.clear(gl.COLOR_BUFFER_BIT);gl.uniform2f(u.RES,w,h);
 for(const L of G.data.scenes[key]){let a=1;for(const q of L.a)a*=typeof q==='number'?q:val(q,T)[0];if(a<.004)continue;gl.uniform1f(u.A,Math.min(1,a));
  const B={over:[gl.ONE,gl.ONE_MINUS_SRC_ALPHA],add:[gl.ONE,gl.ONE],multiply:[gl.DST_COLOR,gl.ONE_MINUS_SRC_ALPHA],screen:[gl.ONE,gl.ONE_MINUS_SRC_COLOR]}[L.o];gl.blendFunc(...B);
  let m=[S,0,0,S,0,0],mc=null;for(let i=0;i<=L.m.length;i++){if(L.c&&L.c.n===i)mc=m;if(i<L.m.length)m=mul(m,opm(L.m[i],T))}
  if(Math.abs(m[0]*m[3]-m[1]*m[2])<1e-9)continue;
  gl.uniform4f(u.M0,m[0],m[1],m[2],m[3]);gl.uniform2f(u.M1,m[4],m[5]);
  if(mc){const k=mul(inv(mc),m);gl.uniform4f(u.C0,k[0],k[1],k[2],k[3]);gl.uniform2f(u.C1,k[4],k[5]);gl.uniform3f(u.CL,L.c.x,L.c.y,L.c.r)}else gl.uniform3f(u.CL,0,0,0);
  if(L.d){const d=L.d,P=d.p.reduce((a,b)=>a+b,0),off=val(d.t,T)[0],hw=d.w/2;gl.uniform1i(u.MODE,1);gl.uniform4f(u.COL,...d.c);gl.uniform1f(u.HW,hw);
   for(const[x0,y0,x1,y1]of d.lines){const len=Math.hypot(x1-x0,y1-y0),dx=(x1-x0)/len,dy=(y1-y0)/len;
    for(let s=-(((off%P)+P)%P);s<len;s+=P){const s0=Math.max(0,s),s1=Math.min(len,s+d.p[0]);if(s1<=s0)continue;
     const ax=x0+dx*s0,ay=y0+dy*s0,bx=x0+dx*s1,by=y0+dy*s1,e=hw+2;gl.uniform4f(u.SEG,ax,ay,bx,by);gl.uniform4f(u.B,Math.min(ax,bx)-e,Math.min(ay,by)-e,Math.abs(bx-ax)+2*e,Math.abs(by-ay)+2*e);gl.drawArrays(gl.TRIANGLE_STRIP,0,4)}}
   continue}
  const t=await tex(L.i);gl.bindTexture(gl.TEXTURE_2D,t);gl.uniform1i(u.MODE,0);gl.uniform4f(u.B,...L.b);gl.drawArrays(gl.TRIANGLE_STRIP,0,4)}
 if(gl.getError())throw new Error('gl error '+key);return G.c.toDataURL('image/png').split(',')[1]};
"""
WEBJS = """async ([id,kind,Ts,S])=>{const g={s:S,gx:0,gy:0,gw:680*S,gh:828*S,w:680*S,h:828*S},v=await winCompile(winDef(id),kind,g),o=[];
 if(ctx.canvas.width<g.w||ctx.canvas.height<g.h)throw new Error('canvas too small '+ctx.canvas.width+'x'+ctx.canvas.height);
 for(const T of Ts){WIN.fixed=T;ctx.setTransform(1,0,0,1,0,0);ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';ctx.fillStyle='#000';ctx.fillRect(0,0,ctx.canvas.width,ctx.canvas.height);winDraw(v);
  const k=document.createElement('canvas');k.width=g.w;k.height=g.h;k.getContext('2d').drawImage(ctx.canvas,0,0);o.push(k.toDataURL('image/png').split(',')[1])}
 WIN.fixed=null;return o}"""


class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *x):
        pass


def serve(d):
    s = socketserver.ThreadingTCPServer(('127.0.0.1', 0), functools.partial(H, directory=d))
    s.daemon_threads = True
    threading.Thread(target=s.serve_forever, daemon=True).start()
    return s


def img(b64):
    return Image.open(io.BytesIO(base64.b64decode(b64))).convert('RGB')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out', nargs='?')
    ap.add_argument('--t', default='0,1.3,7.7,23.1')
    ap.add_argument('--scale', type=float, default=1.5)
    ap.add_argument('--only')
    a = ap.parse_args()
    Ts = [float(x) for x in a.t.split(',')]
    S = a.scale
    w, h = int(680 * S), int(828 * S)
    if a.out:
        os.makedirs(a.out, exist_ok=True)
    s1, s2 = serve(WEB), serve(RES)
    bad = 0
    with sync_playwright() as p:
        br = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
        web = br.new_context(viewport={'width': 700, 'height': 900}, device_scale_factor=2).new_page()
        web.set_default_timeout(0)
        web.goto(f'http://127.0.0.1:{s1.server_address[1]}/index.html', wait_until='load')
        web.wait_for_timeout(2500)
        web.evaluate('()=>{window.requestAnimationFrame=()=>0}')
        web.wait_for_timeout(200)
        ios = br.new_page()
        ios.set_default_timeout(0)
        ios.goto(f'http://127.0.0.1:{s2.server_address[1]}/windows.json')
        ios.evaluate('()=>{document.documentElement.innerHTML=""}')
        ios.add_script_tag(content=GL)
        ios.evaluate('([w,h])=>setupGL(w,h)', [w, h])
        keys = ios.evaluate('Object.keys(G.data.scenes)')
        for key in keys:
            if a.only and not key.startswith(a.only):
                continue
            wid, kind = key.split('|')
            ref = [img(x) for x in web.evaluate(WEBJS, [wid, kind, Ts, S])]
            row = []
            for T, A in zip(Ts, ref):
                B = img(ios.evaluate('([k,T,S])=>drawGL(k,T,S)', [key, T, S]))
                d = np.abs(np.asarray(A, float) - np.asarray(B, float)).mean(2)
                n = 20
                q = d[:h // n * n, :w // n * n].reshape(h // n, n, w // n, n).mean((1, 3))
                j, i = np.unravel_index(q.argmax(), q.shape)
                row.append((d.mean(), q.max(), int(i * n / S), int(j * n / S)))
                if a.out:
                    sh = Image.new('RGB', (w * 3 // 2, h // 2 + 14))
                    D = Image.fromarray(np.clip(d * 4, 0, 255).astype('uint8')).convert('RGB')
                    for k, m in enumerate((A, B, D)):
                        sh.paste(m.resize((w // 2, h // 2)), (k * w // 2, 14))
                    ImageDraw.Draw(sh).text((4, 1), f'{key} T={T}  web / ios / diff x4', fill='white')
                    sh.save(os.path.join(a.out, f'{wid}-{kind}-{T}.png'))
            print(f'{key:16s}', '  '.join(f'T{T:g} 平均 {m:.2f} 最大塊 {x:.1f}@({i},{j})' for T, (m, x, i, j) in zip(Ts, row)))
            bad = max(bad, max(m for m, *_ in row))
        br.close()
    print(f'最大平均差 {bad:.2f}（滿分 255）')


if __name__ == '__main__':
    main()
