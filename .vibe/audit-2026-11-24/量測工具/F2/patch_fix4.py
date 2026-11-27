# 在自己的複本（fix/）改 index.html：網格聯集遮罩走 GPU、最細保底、薄處照樣不透明、顯示平滑（都有開關 JELX）
import sys
sys.stdout.reconfigure(encoding='utf-8')
P=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix4/prototype/web/index.html'
S0=open(r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/prototype/web/index.html',encoding='utf-8').read()
s=S0
def rep(a,b,n=1):
    global s
    assert s.count(a)==n,(s.count(a),a[:80]);s=s.replace(a,b)
# 1 著色器：薄的地方照樣不透明（thick 改看小模糊 b1 的一半份量）
rep("uniform float aEdge,aCore,amb,dif,glow,line,nk,shin,s0,s1,spec,sheen,arc,rnd,wet,water,refr,absorb,opq;","uniform float aEdge,aCore,amb,dif,glow,line,nk,shin,s0,s1,spec,sheen,arc,rnd,wet,water,refr,absorb,opq,thinOpq,thr;")
rep("w=mix(w,col,clamp(smoothstep(.03,.35,thick)*opq,0.,1.));","w=mix(w,mix(col,mix(cEdge,cCore,.55)*amb,thinOpq*(1.-smoothstep(.05,.5,thick))*.75),clamp(max(smoothstep(.03,.35,thick),thinOpq*smoothstep(.50,.64,b1))*opq,0.,1.));")
rep("if(cov<=0.){o=vec4(0.);return;}","float thG=thr>0.?texture(M,v).g*(thr>1.5?1.:1.-smoothstep(.14,.28,texture(B2,v).r)):0.;cov=max(cov,smoothstep(.25,.75,thG));if(cov<=0.){o=vec4(0.);return;}")
rep("thinOpq*smoothstep(.50,.64,b1))*opq","thinOpq*max(smoothstep(.50,.64,b1),smoothstep(.3,.8,thG)))*opq")
rep("'refr','absorb','opq'])JEL.uF","'refr','absorb','opq','thinOpq','thr'])JEL.uF")
rep("gl.uniform1f(U.opq,look6()?.9:mat.opaque||0);","gl.uniform1f(U.opq,look6()?.9:mat.opaque||0);gl.uniform1f(U.thinOpq,JELX.thinOpq);gl.uniform1f(U.thr,JELX.mode===7?1:JELX.mode===8?2:0);")
# 2 程式：網格遮罩
rep("const JEL={gl:null,","""const JELX={mode:0,wmin:.12,wthr:.09,thinOpq:0,smooth:0,ms:0};   // mode 0 現在（外框路徑）；1 網格聯集；2 聯集＋最細保底（裡面的邊畫成膠囊）
/* 顯示用的位置（1€ 濾波：慢的時候抹掉抖，快的時候不延遲）；補點時照三角形權重換過去 */
const DSP={n:0,x:null,y:null,dx:null,dy:null,t:-1,px:null,py:null};
function dspStep(dt){if(!(JELX.smooth>0)){DSP.n=0;return}
  if(DSP.n!==N){DSP.n=N;DSP.x=Float64Array.from(X);DSP.y=Float64Array.from(Y);DSP.px=Float64Array.from(X);DSP.py=Float64Array.from(Y);DSP.dx=new Float64Array(N);DSP.dy=new Float64Array(N);return}
  let mx=0,my=0;for(let i=0;i<N;i++){mx+=X[i]-DSP.px[i];my+=Y[i]-DSP.py[i]}mx/=N;my/=N;   // 整團平移不濾
  const a=fc=>{const tau=1/(6.2832*fc);return 1/(1+tau/dt)},ad=a(3),beta=JELX.beta||.06,mc=JELX.minc||4;
  for(let i=0;i<N;i++){DSP.x[i]+=mx;DSP.y[i]+=my;const vx=(X[i]-DSP.px[i]-mx)/dt,vy=(Y[i]-DSP.py[i]-my)/dt;DSP.dx[i]+=(vx-DSP.dx[i])*ad;DSP.dy[i]+=(vy-DSP.dy[i])*ad;const k=a(mc+beta*Math.hypot(DSP.dx[i],DSP.dy[i]));DSP.x[i]+=(X[i]-DSP.x[i])*k;DSP.y[i]+=(Y[i]-DSP.y[i])*k;DSP.px[i]=X[i];DSP.py[i]=Y[i]}}
function jelMeshInit(gl,prog){const VM=`#version 300 es
in vec2 p;uniform vec2 t;void main(){gl_Position=vec4(p.x*t.x-1.,1.-p.y*t.y,0.,1.);}`,FM=`#version 300 es
precision mediump float;out vec4 o;void main(){o=vec4(1.);}`,VC=`#version 300 es
in vec2 p;in vec4 ab;in float rr;uniform vec2 t;uniform float uR;out vec2 q;flat out vec4 sg;flat out float rd;void main(){float r=uR*rr;rd=r;vec2 a=ab.xy,b=ab.zw,d=b-a;float L=length(d);vec2 u=L>1e-5?d/L:vec2(1.,0.),n=vec2(-u.y,u.x);q=mix(a,b,p.x)+u*(p.x*2.-1.)*(r+1.)+n*p.y*(r+1.);sg=ab;gl_Position=vec4(q.x*t.x-1.,1.-q.y*t.y,0.,1.);}`,FC=`#version 300 es
precision highp float;in vec2 q;flat in vec4 sg;flat in float rd;out vec4 o;void main(){float r=rd;if(r<.05)discard;vec2 a=sg.xy,ba=sg.zw-a,pa=q-a;float h=clamp(dot(pa,ba)/max(dot(ba,ba),1e-6),0.,1.);o=vec4(clamp(r+.5-length(pa-ba*h),0.,1.));}`;
  const M=JEL.mesh={pm:prog(VM,FM),pc:prog(VC,FC),n:-1,key:null};M.ut=gl.getUniformLocation(M.pm,'t');M.ct=gl.getUniformLocation(M.pc,'t');M.cr=gl.getUniformLocation(M.pc,'uR');
  M.va=gl.createVertexArray();gl.bindVertexArray(M.va);M.vb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M.vb);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);M.ib=gl.createBuffer();gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,M.ib);
  M.vc=gl.createVertexArray();gl.bindVertexArray(M.vc);M.qb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M.qb);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([0,-1,1,-1,0,1,1,1]),gl.STATIC_DRAW);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);M.eb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M.eb);const l=gl.getAttribLocation(M.pc,'ab');M.l=l;gl.enableVertexAttribArray(l);gl.vertexAttribPointer(l,4,gl.FLOAT,false,0,0);gl.vertexAttribDivisor(l,1);M.rb2=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M.rb2);const l2=gl.getAttribLocation(M.pc,'rr');gl.enableVertexAttribArray(l2);gl.vertexAttribPointer(l2,1,gl.FLOAT,false,0,0);gl.vertexAttribDivisor(l2,1);
  gl.bindVertexArray(null)}
function jelRad(gl,M,n){const L=M.radN||0;gl.bindBuffer(gl.ARRAY_BUFFER,M.rb2);if(M.rad&&M.radOn)gl.bufferData(gl.ARRAY_BUFFER,M.rad,gl.DYNAMIC_DRAW);else{const c=Math.max(EDG.length/2,n);if(!M.one||M.one.length<c)M.one=new Float32Array(c+512).fill(1);gl.bufferData(gl.ARRAY_BUFFER,M.one,gl.DYNAMIC_DRAW)}}
// 每個外框點往裡量到對面外框多遠（像素），算要不要保底：T 大於 .26R 不用、小於 .16R 全開
function jelThick(M,v,nb,Rz){const T=M.T&&M.T.length>=nb?M.T:(M.T=new Float32Array(nb+64)),cap=.3*Rz;
  for(let k=0;k<nb;k++){const b=bnd[k],nxs=M.nx[2*k]+M.nx[2*((k+nb-1)%nb)],nys=M.nx[2*k+1]+M.nx[2*((k+nb-1)%nb)+1],d=Math.hypot(nxs,nys);let t=cap;if(d<1e-4){T[k]=0;continue}const nx=nxs/d,ny=nys/d,x=v[2*b],y=v[2*b+1];
    for(let m=0;m<nb;m++){if(m===k||(m+1)%nb===k)continue;const a=bnd[m],c=bnd[(m+1)%nb],ax=v[2*a]-x,ay=v[2*a+1]-y,bx=v[2*c]-x,by=v[2*c+1]-y;if(Math.min(ax*ax+ay*ay,bx*bx+by*by)>(cap+60)*(cap+60))continue;const ex=bx-ax,ey=by-ay,den=nx*ey-ny*ex;if(Math.abs(den)<1e-9)continue;const tt=(ax*ey-ay*ex)/den,u=(ax*ny-ay*nx)/den;if(tt>.5&&u>=0&&u<=1&&tt<t)t=tt}
    T[k]=t}
  return T}
function jelMeshMask(tr,k,grow){const gl=JEL.gl,M=JEL.mesh,n=N;
  if(!M.v||M.v.length<n*2)M.v=new Float32Array((n+256)*2);const v=M.v,XX=JELX.mode===6&&DSP.n===n?DSP.x:X,YY=JELX.mode===6&&DSP.n===n?DSP.y:Y,nb=bnd.length,A=tr.a*k,B=tr.b*k,C=tr.c*k,D=tr.d*k,E=tr.e*k,F=tr.f*k,tf=(i,x,y)=>{v[2*i]=A*x+C*y+E;v[2*i+1]=B*x+D*y+F;grow(x,y,R*.08)};
  for(let i=0;i<n;i++)if(BIDX[i]<0)tf(i,XX[i],YY[i]);
  for(let i=0;i<nb;i++){const a=bnd[(i+nb-1)%nb],b=bnd[i],c=bnd[(i+1)%nb];tf(b,XX[a]*.25+XX[b]*.5+XX[c]*.25,YY[a]*.25+YY[b]*.5+YY[c]*.25)}
  if(M.W!==W||M.H!==H){M.W=W;M.H=H;if(M.rb){gl.deleteRenderbuffer(M.rb);gl.deleteFramebuffer(M.fb);gl.deleteFramebuffer(M.ft)}
    M.rb=gl.createRenderbuffer();gl.bindRenderbuffer(gl.RENDERBUFFER,M.rb);gl.renderbufferStorageMultisample(gl.RENDERBUFFER,4,gl.RGBA8,W,H);M.fb=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,M.fb);gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.RENDERBUFFER,M.rb);
    M.tx=gl.createTexture();JEL.params(gl,M.tx);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA8,W,H,0,gl.RGBA,gl.UNSIGNED_BYTE,null);M.ft=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,M.ft);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,M.tx,0)}
  gl.bindFramebuffer(gl.FRAMEBUFFER,M.fb);gl.viewport(0,0,W,H);gl.disable(gl.SCISSOR_TEST);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT);gl.enable(gl.BLEND);gl.blendEquation(gl.MAX);gl.blendFunc(gl.ONE,gl.ONE);
  gl.bindVertexArray(M.va);gl.bindBuffer(gl.ARRAY_BUFFER,M.vb);gl.bufferData(gl.ARRAY_BUFFER,v.subarray(0,n*2),gl.DYNAMIC_DRAW);
  if(M.key!==TRI){M.key=TRI;M.all=Int32Array.from(EDG);M.rad=new Float32Array(EDG.length/2);M.nb=new Int32Array(n);for(let i=0;i<n;i++){if(BIDX[i]>=0){M.nb[i]=BIDX[i];continue}let bd=1e18,bk=0;for(let q2=0;q2<nb;q2++){const e=(Q0X[bnd[q2]]-Q0X[i])**2+(Q0Y[bnd[q2]]-Q0Y[i])**2;if(e<bd){bd=e;bk=q2}}M.nb[i]=bk}M.g=new Float32Array(nb);M.allv=new Float32Array(EDG.length*2);{const nei=Array.from({length:n},()=>[]);for(let e=0;e<EDG.length;e+=2){nei[EDG[e]].push(EDG[e+1]);nei[EDG[e+1]].push(EDG[e])}M.t3=new Int32Array(nb).fill(-1);const em=new Map();bnd.forEach((b,q2)=>em.set(b+'_'+bnd[(q2+1)%nb],q2));for(let q2=0;q2<TRI.length;q2+=3)for(const [a2,b2,c2] of [[0,1,2],[1,2,0],[2,0,1]]){const u=TRI[q2+a2],w=TRI[q2+b2],z=TRI[q2+c2];let e2=em.get(u+'_'+w);if(e2==null)e2=em.get(w+'_'+u);if(e2!=null)M.t3[e2]=z}}M.pv=new Float32Array(n*4);gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,M.ib);gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,Uint16Array.from(TRI),gl.STATIC_DRAW);const L=[];for(let e=0;e<EDG.length;e+=2)if(BIDX[EDG[e]]<0&&BIDX[EDG[e+1]]<0)L.push(EDG[e],EDG[e+1]);M.ie=Int32Array.from(L);M.ev=new Float32Array(L.length*2)}
  const rg=JELX.mode===7||JELX.mode===8;gl.colorMask(true,!rg,!rg,!rg);gl.useProgram(M.pm);gl.uniform2f(M.ut,2/W,2/H);gl.drawElements(gl.TRIANGLES,TRI.length,gl.UNSIGNED_SHORT,0);
  if(JELX.mode===2){const I=M.ie,ev=M.ev;for(let e=0;e<I.length;e+=2){const i=I[e],j=I[e+1];ev[2*e]=v[2*i];ev[2*e+1]=v[2*i+1];ev[2*e+2]=v[2*j];ev[2*e+3]=v[2*j+1]}
    gl.bindVertexArray(M.vc);gl.bindBuffer(gl.ARRAY_BUFFER,M.eb);gl.bufferData(gl.ARRAY_BUFFER,ev,gl.DYNAMIC_DRAW);jelRad(gl,M,n);gl.useProgram(M.pc);gl.uniform2f(M.ct,2/W,2/H);gl.uniform1f(M.cr,R*Math.sqrt(Math.abs(A*D-B*C))*JELX.wmin/2);gl.drawArraysInstanced(gl.TRIANGLE_STRIP,0,4,I.length/2)}
  const zz=Math.sqrt(Math.abs(A*D-B*C));
  gl.colorMask(!rg,true,!rg,!rg);M.radOn=false;if(JELX.mode===3||JELX.mode===6||rg||JELX.mode===9){const I=M.all,ev=M.allv,rr=R*zz*(rg?JELX.wthr:JELX.wmin)/2,IX=M.ix&&M.ix.length>=2*n?M.ix:(M.ix=new Float32Array(2*n+512));IX.set(v.subarray(0,2*n));
    const NX=M.nx&&M.nx.length>=2*nb?M.nx:(M.nx=new Float32Array(2*nb+256));for(let k2=0;k2<nb;k2++){const i=bnd[k2],j=bnd[(k2+1)%nb],q2=M.t3[k2];let nx=0,ny=0;if(q2>=0){const ex=v[2*j]-v[2*i],ey=v[2*j+1]-v[2*i+1],tx=v[2*q2]-v[2*i],ty=v[2*q2+1]-v[2*i+1],s2=ex*ty-ey*tx>=0?1:-1,l=Math.hypot(ex,ey)||1;nx=-ey/l*s2;ny=ex/l*s2}NX[2*k2]=nx;NX[2*k2+1]=ny}
    for(let k2=0;k2<nb;k2++){const b=bnd[k2],p2=(k2+nb-1)%nb;let ax=NX[2*k2]+NX[2*p2],ay=NX[2*k2+1]+NX[2*p2+1];const d=Math.hypot(ax,ay);if(d<1e-4)continue;IX[2*b]+=ax/d*rr;IX[2*b+1]+=ay/d*rr}
    if(JELX.mode===9){const Rz=R*zz,T=jelThick(M,v,nb,Rz),g=M.g;for(let k2=0;k2<nb;k2++)g[k2]=Math.max(0,Math.min(1,(.26*Rz-T[k2])/(.10*Rz)));for(let e=0;e<I.length;e+=2){const a=M.nb[I[e]],b2=M.nb[I[e+1]];M.rad[e/2]=Math.max(g[a],g[b2])}M.radOn=true}
    for(let e=0;e<I.length;e+=2){const i=I[e],j=I[e+1];ev[2*e]=IX[2*i];ev[2*e+1]=IX[2*i+1];ev[2*e+2]=IX[2*j];ev[2*e+3]=IX[2*j+1]}
    const wl=worldWalls(),X0=isFinite(wl.l)?A*wl.l+E:0,X1=isFinite(wl.r)?A*wl.r+E:W,Y1=isFinite(wl.b)?D*wl.b+F:H,sc=(x0,y0,x1,y1)=>gl.scissor(Math.max(0,Math.floor(x0)),Math.max(0,Math.floor(H-y1)),Math.ceil(Math.min(W,x1)-Math.max(0,x0)),Math.ceil(Math.min(H,y1)-Math.max(0,y0)));gl.enable(gl.SCISSOR_TEST);sc(X0,0,X1,Math.max(1,Math.min(H,Y1+1)));
    gl.bindVertexArray(M.vc);gl.bindBuffer(gl.ARRAY_BUFFER,M.eb);gl.bufferData(gl.ARRAY_BUFFER,ev,gl.DYNAMIC_DRAW);jelRad(gl,M,n);gl.useProgram(M.pc);gl.uniform2f(M.ct,2/W,2/H);gl.uniform1f(M.cr,rr);gl.drawArraysInstanced(gl.TRIANGLE_STRIP,0,4,I.length/2);gl.disable(gl.SCISSOR_TEST)}
  if(JELX.mode===5){gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT);const pv=M.pv;for(let i=0;i<n;i++){pv[4*i]=pv[4*i+2]=v[2*i];pv[4*i+1]=pv[4*i+3]=v[2*i+1]}gl.bindVertexArray(M.vc);gl.bindBuffer(gl.ARRAY_BUFFER,M.eb);gl.bufferData(gl.ARRAY_BUFFER,pv.subarray(0,4*n),gl.DYNAMIC_DRAW);jelRad(gl,M,n);gl.useProgram(M.pc);gl.uniform2f(M.ct,2/W,2/H);gl.uniform1f(M.cr,h*zz*(JELX.disc||.8));gl.drawArraysInstanced(gl.TRIANGLE_STRIP,0,4,n)}
  gl.colorMask(true,true,true,true);gl.bindVertexArray(null);gl.disable(gl.BLEND);gl.blendEquation(gl.FUNC_ADD);
  gl.bindFramebuffer(gl.READ_FRAMEBUFFER,M.fb);gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER,M.ft);gl.blitFramebuffer(0,0,W,H,0,0,W,H,gl.COLOR_BUFFER_BIT,gl.NEAREST);return M.tx}
const JEL={gl:null,""")
rep("JEL.gl=gl;JEL.c=c;","jelMeshInit(gl,prog);gl.bindBuffer(gl.ARRAY_BUFFER,q);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);JEL.gl=gl;JEL.c=c;")
# 3 jelRender：遮罩來源換掉
rep("  m.setTransform(1,0,0,1,0,0);m.fillStyle='#000';m.fillRect(0,0,W,H);m.setTransform(tr.a*k,tr.b*k,tr.c*k,tr.d*k,tr.e*k,tr.f*k);m.fillStyle='#fff';\n  jelPath(m,P);m.fill();","  if(!JELX.mode){m.setTransform(1,0,0,1,0,0);m.fillStyle='#000';m.fillRect(0,0,W,H);m.setTransform(tr.a*k,tr.b*k,tr.c*k,tr.d*k,tr.e*k,tr.f*k);m.fillStyle='#fff';\n  jelPath(m,P);m.fill()}")
rep("  extraMask(m,grow);   // v2.51 黏條、小的那團\n  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,JEL.tM);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,JEL.mc);",
"  let TM=JEL.tM;if(JELX.mode){TM=jelMeshMask(tr,k,grow);JEL.tMesh=TM}else{extraMask(m,grow);   // v2.51 黏條、小的那團\n  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,JEL.tM);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,JEL.mc)}")
rep("blur(JEL.tM,JEL.h1,1/JEL.h1.w,0,s1);blur(JEL.h1.tx,JEL.h2,0,1/JEL.h2.h,s1);blur(JEL.tM,JEL.q1,1/JEL.q1.w,0,s2);","blur(TM,JEL.h1,1/JEL.h1.w,0,s1);blur(JEL.h1.tx,JEL.h2,0,1/JEL.h2.h,s1);blur(TM,JEL.q1,1/JEL.q1.w,0,s2);")
rep("[[JEL.tM,U.M],[JEL.h2.tx,U.B1]","[[TM,U.M],[JEL.h2.tx,U.B1]")
# 4 每幀推一次顯示位置
rep("  eyeStep(dt);   // v2.23\n}","  eyeStep(dt);   // v2.23\n  dspStep(dt);\n}")
open(P,'w',encoding='utf-8').write(s);print('patched',len(s)-len(S0))
