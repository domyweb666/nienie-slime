import sys
sys.stdout.reconfigure(encoding='utf-8')
P='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/index.html'
s=open(P,encoding='utf-8',newline='').read()
assert '\r\n' in s
s=s.replace('\r\n','\n')
def rep(a,b,n=1):
    global s
    c=s.count(a)
    assert c==n,(c,a[:120])
    s=s.replace(a,b)
# --- 版本字樣
rep('形狀匹配原型 v2.60</title>','形狀匹配原型 v2.61</title>')
rep('<span>v2.60 <i id="v-fps"','<span>v2.61 <i id="v-fps"')
rep('手感調節台的存檔只記 13 個旋鈕，不帶外觀\n   =====','''手感調節台的存檔只記 13 個旋鈕，不帶外觀
   - v2.61（多米 11-25：第一批完整版照推薦，規格 .uiux/04-手感/極致優化規劃-暫定.md、名字和預設 .vibe/第一批-合約.md）：皮 skinU 1，遮罩改畫身體自己那張三角網的聯集，薄的地方補一條保底線，身體裡的東西（餡、腮紅、眼睛）照這張遮罩剪；
     只接在清透皮那條畫法，平塗、別的皮、WebGL 開不起來時自動用舊外框。拉的三顆開關預設關：pullHold（拉長停住就定住）、pullWhole（往身體裡拉先搬整隻）、pullSoft（拉很長放手收回去：先不逃、回正限速、放手 0.8 秒限速、縮短了才換網格、手指在動才放寬上限、停住最多漂 0.3R）。
     其他十個（rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61）登記在這裡，各自的行為另外接。十四個全 0 要跟 v2.60 逐點相同；換隻、換材質都留著（matKeep）。調節台多「這一批」一塊；拉的三顆進存檔，其他不進。
     網址 ?pull=0、?pull=1、?pull=hold,whole,soft 把拉的三顆鎖住（盲比用，畫面上不寫是哪一邊）。window.KPIOS=1 是測試掛鉤：窗台上的回家彈簧改成手機的值，平常不設
   =====''')
# --- ctx 可以換成暫存畫布
rep("const cv=document.getElementById('cv'),ctx=cv.getContext('2d');","const cv=document.getElementById('cv');let ctx=cv.getContext('2d');   // v2.61：畫身體裡的東西時暫時換到暫存畫布（skinLayer），畫完換回來")
# --- PRESETS
rep("pullNearR:10,clear:0,remesh:1,","pullNearR:10,clear:0,skinU:1,pullHold:0,pullWhole:0,pullSoft:0,rough:1,tapSoft:1,petSlow:1,wakeSoft:1,nearFast:1,greetLook:1,brJit:1,bumpSoft:1,eyeTrue:1,snd61:1,remesh:1,",3)
rep("const F=[\n","""// v2.61 第一批的十四個開關。三個材質的預設都一樣；換隻、換材質時留著現在的（matKeep）
const KEYS61=['skinU','pullHold','pullWhole','pullSoft','rough','tapSoft','petSlow','wakeSoft','nearFast','greetLook','brJit','bumpSoft','eyeTrue','snd61'],PULL3=['pullHold','pullWhole','pullSoft'];
// 網址 ?pull=：1 三顆都開、0 三顆都關、hold,whole,soft 任選。有寫就鎖住，換隻、換材質、換存檔都照網址（開兩個分頁比的時候才不會跑掉）
const PULLQ=(()=>{const q=new URLSearchParams(location.search).get('pull');if(q==null)return null;const w=q.split(',').map(x=>x.trim()),on=k=>q.trim()==='1'||w.includes(k)?1:0;return{pullHold:on('hold'),pullWhole:on('whole'),pullSoft:on('soft')}})();
function matKeep(m){const o={};if(m)for(const k of KEYS61)if(typeof m[k]==='number')o[k]=m[k];return PULLQ?{...o,...PULLQ}:o}
const F=[
""")
ROWS='''  ['skinU','皮：不會斷的畫法 v2.61','1：先畫滿身體裡每一個小三角形，細的地方補一條保底線，拉遠、打結時皮比較不會斷開，手指底下也看得到。0 回 v2.60（照外框畫）。只在清透皮有作用',0,1,1],
  ['pullHold','拉的 A3：拉長停住就定住 v2.61','1：拉開 0.6R 以上，手指停下來 0.25 秒，身體就不再自己變長。0 回 v2.60',0,1,1],
  ['pullWhole','拉的 A4：往裡拉，整隻先走 v2.61','1：往身體裡面拉的那一段，整隻先跟著走，再拉長。0 回 v2.60',0,1,1],
  ['pullSoft','拉的 A5：拉很長放手，收回去 v2.61','1：身體拉得很長時放手，先不逃、轉正有限速、放手後 0.8 秒內每一點有限速；按住不動時上限不會自己變大。0 回 v2.60',0,1,1],
  ['rough','只有快扯算欺負 v2.61','1：慢慢拉很長不算欺負；快扯不會變熟，也不會變得怕你。0 回 v2.60（拉開 1.5R 撐半秒就算）',0,1,1],
  ['tapSoft','慢慢點不算攻擊 v2.61','1：慢慢點牠不會嚇到。0 回 v2.60',0,1,1],
  ['petSlow','慢慢摸也算摸 v2.61','1：摸得很慢也會呼嚕、變熟。0 回 v2.60（太慢會被當成抓）',0,1,1],
  ['wakeSoft','輕碰慢慢醒 v2.61','1：睡著時輕輕碰，慢慢醒；剛打開 40 秒才會睡。0 回 v2.60（一碰就嚇醒、30 秒就睡）',0,1,1],
  ['nearFast','聽節奏時也會靠過來 v2.61','1：在聽聲音打節奏時，手指放旁邊照樣靠過來。0 回 v2.60',0,1,1],
  ['greetLook','打開先看你 v2.61','1：打開、切回來，先看你一眼。0 回 v2.60',0,1,1],
  ['brJit','作息每次不一樣 v2.61','1：醒多久、睡多久每次有點不同。0 回 v2.60',0,1,1],
  ['bumpSoft','自己撞到擺飾只晃不倒 v2.61','1：牠自己走路撞到的擺飾晃一下，不會倒。0 回 v2.60',0,1,1],
  ['eyeTrue','眼睛看真的手指 v2.61','1：眼睛跟著手指現在的位置。0 回 v2.60（慢四分之一秒）',0,1,1],
  ['snd61','新的揉聲 v2.61','1：揉的聲音換新的循環，抓著時雨聲變小。0 回 v2.60',0,1,1],
'''
i=s.index("  ['clear','十隻都換成亮面透明 v2.60'");j=s.index('\n',i)+1
s=s[:j]+ROWS+s[j:]
# --- A2..A5 常數與物理
rep("function capGrowStep(dt){if(","""/* ---------- v2.61 拉的三顆開關（多米 11-25；規格在 .uiux/04-手感/極致優化規劃-暫定.md 的 A2 到 A5，量法在 .vibe/audit-2026-11-24/整理-不破皮.md） ----------
   停住的計時 PULLT：有手指抓著、而且每一根都慢於 PULLSTILL R/s，滿 PULLWAIT 秒才算停住。 */
const PULLSTILL=.3,PULLWAIT=.25;
const PULLHOLD={fade:.25,min:.02};   // A3（cr）停住後 fade 秒內，記形速度降到 min 倍
const PULLWHOLE={k:1.6,r0:.15,ramp:.35};   // A4（iw）往中心走的那段，最多 k 倍「起點離中心的距離」先搬整隻；起點離中心 r0 R 以內不搬，再過 ramp R 全搬
const PULLSOFT={noFlee:1.35,upright:3,relV:6,relT:.8,homeLen:1.35,drift:.3};   // A5＋A2：noFlee（fl）記住的外框長過原本幾倍，放手先不逃；upright（up）回正時尖端最快幾 R/s；relV、relT（vc）放手幾秒內每顆最快幾 R/s；homeLen（bl）外框縮到幾倍內才換回原本的網格；drift（gv）停住時手指最多漂幾 R。手指在動才放寬上限（cg）也在這一顆
let PULLT=0;
function pullMoving(){for(const f of fingers.values())if(f.mode==='grab'&&Math.hypot(f.vxS||0,f.vyS||0)>R*PULLSTILL)return true;return false}
function pullStillStep(dt){let g=false;for(const f of fingers.values())if(f.mode==='grab')g=true;PULLT=g&&!pullMoving()?PULLT+dt:0}
function pullHoldK(){const g0=PULLT<PULLWAIT?1:Math.max(PULLHOLD.min,1-(PULLT-PULLWAIT)/PULLHOLD.fade);return 1-pullK()*(1-g0)}   // A3：拉開 0.6R 起才作用（pullK）
function memLen(){let s=0;const n=bnd.length;for(let k=0;k<n;k++){const i=bnd[k],j=bnd[(k+1)%n];s+=Math.hypot(QX[j]-QX[i],QY[j]-QY[i])}return s}   // 記住的形狀外框多長
function capGrowStep(dt){if(""")
rep("if(held){if(gap>.12&&mat.stretchCap>0){let m=0;","if(held){if(gap>.12&&mat.stretchCap>0&&(!(mat.pullSoft>=.5)||pullMoving())){let m=0;")
rep("if(REM.n>0&&HB.length===bnd.length&&remesh(true)){","if(REM.n>0&&HB.length===bnd.length&&(!(mat.pullSoft>=.5)||memLen()<PULLSOFT.homeLen*HRC[HRX.length])&&remesh(true)){")
rep("  if(grab)fingerGrab(f,p);\n","  if(grab){f.r0x=p.x-globalC.xc;f.r0y=p.y-globalC.yc;fingerGrab(f,p)}   // v2.61 A4：抓下去的地方離身體中心多遠\n")
rep("f.peak=0;f.on=false;fingerGrab(f,{x:f.x,y:f.y});sfxPlay('press',.35);dragRebase()}","f.peak=0;f.on=false;f.r0x=f.x-globalC.xc;f.r0y=f.y-globalC.yc;fingerGrab(f,{x:f.x,y:f.y});sfxPlay('press',.35);dragRebase()}")
L="for(let i=0;i<N;i++){const vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}"
rep("  "+L+"\n","""  if(mat.pullSoft>=.5&&!fingers.size&&t-lastTouch<PULLSOFT.relT&&!INTRO.on&&!SILL.hop){const lim=PULLSOFT.relV*R*dt;for(let i=0;i<N;i++){let vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;const sp=Math.hypot(vx,vy);if(sp>lim){vx*=lim/sp;vy*=lim/sp}PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}}   // v2.61 A5：放手限速
  else """+L+"\n")
rep("  const rotK=-gAng*Math.min(.2,grabbing?","  let rotK=-gAng*Math.min(.2,grabbing?")
rep("  if(rotK!==0){const c=Math.cos(rotK)","  if(mat.pullSoft>=.5&&!grabbing){let rm=0;for(const i of bnd){const q=(X[i]-cx)**2+(Y[i]-cy)**2;if(q>rm)rm=q}const lim=PULLSOFT.upright*R*dt/Math.max(R*.5,Math.sqrt(rm));rotK=Math.max(-lim,Math.min(lim,rotK))}   // v2.61 A5：身體很長時回正不甩\n  if(rotK!==0){const c=Math.cos(rotK)")
rep("  const kh=FLOAT?(","  const kh=window.KPIOS&&SILL.on?.006*(grabbing?mat.anchor:1):FLOAT?(")
rep("    if(sw>0){const cs=effSlip();if(mat.endless>=.5){const gc=globalC","    if(sw>0&&!(mat.pullSoft>=.5&&PULLT>PULLWAIT&&Math.hypot(sx,sy)>0&&(f.slx||0)*sx+(f.sly||0)*sy>0&&Math.hypot(f.slx||0,f.sly||0)>R*PULLSOFT.drift)){const cs=effSlip();if(mat.endless>=.5){const gc=globalC")
rep("*dt*g)*(mat.rubSpeed>0&&tickOn()?0:1);   // v2.24","*dt*g)*(mat.rubSpeed>0&&tickOn()?0:1)*(mat.pullHold>=.5?pullHoldK():1);   // v2.24")
rep("function moodRelease(f){if(!(mat.emo>=.5))return;\n","function moodRelease(f){if(!(mat.emo>=.5))return;\n  if(mat.pullSoft>=.5&&MOOD.strainMax>.15&&memLen()>PULLSOFT.noFlee*HRC[HRX.length]){MOOD.strainMax=0;MOOD.scare=Math.min(1,MOOD.scare+.5);return}   // v2.61 A5：還拉得很長就先不逃\n")
rep("  const dx=sx/n,dy=sy/n,dl=Math.hypot(dx,dy);if(dl<1e-9)return[0,0,n];const S=slideLen(),st=S*Math.tanh((1-dragFollow())*dl/S);return[dx-dx/dl*st,dy-dy/dl*st,n]}",
"""  let dx=sx/n,dy=sy/n,dl=Math.hypot(dx,dy);if(dl<1e-9)return[0,0,n];
  let wx=0,wy=0;if(mat.pullWhole>=.5&&n===1){const f=[...fingers.values()].find(q=>q.mode==='grab');if(f&&f.r0x!=null){const rl=Math.hypot(f.r0x,f.r0y);if(rl>R*.1){const ux=f.r0x/rl,uy=f.r0y/rl,p=-(dx*ux+dy*uy);
    if(p>0){const c=Math.min(p,rl*PULLWHOLE.k)*smooth01((rl/R-PULLWHOLE.r0)/PULLWHOLE.ramp);wx=-ux*c;wy=-uy*c;dx-=wx;dy-=wy;dl=Math.hypot(dx,dy)||1e-9}}}}   // v2.61 A4：往身體中心走的那一段先搬整隻，剩下的照舊拉長
  const S=slideLen(),st=S*Math.tanh((1-dragFollow())*dl/S);return[wx+dx-dx/dl*st,wy+dy-dy/dl*st,n]}""")
rep("  plasticity(dt);\n  twitch(L);","  pullStillStep(dt);plasticity(dt);\n  twitch(L);")
# --- 皮
SKIN=r'''/* ---------- v2.61 A1 皮：三角網的聯集（多米 11-25；來源 .vibe/audit-2026-11-24/patches 的 m9） ----------
   以前的遮罩是外框那一圈路徑：打成 8 字、脖子細於 0.1R，模糊後過不了門檻，皮就斷開，或手指底下那截沒畫出來。
   現在遮罩畫身體自己那張三角網（TRI）的聯集，翻面的也畫；外框點往裡量到對面多厚，薄於 SKINT.hi R 的地方開始補線、SKINT.lo R 以下全補，線寬 SKINT.w R，往內縮一個半徑（平常的樣子不變胖），貼地的線往上挪一個半徑（不然被地板裁掉一半又變細）。
   身體裡的東西（氣泡、餡、腮紅、眼睛）先畫在暫存畫布，再用同一張遮罩剪，剪的邊跟皮的邊是同一條。
   skinU 0、別的皮、平塗、沒有三角網、WebGL 開不起來：走舊的外框路徑，印一次警告。 */
const SKINT={w:.12,hi:.26,lo:.16,cap:.3},SKIN={m:null,warned:false,used:false,covered:false,base:null,lay:null,lctx:null};
function skinWarn(why){if(SKIN.warned)return;SKIN.warned=true;console.warn('[skinU] '+why+'，皮改用舊的外框畫法')}
function skinOn(){if(!(mat.skinU>=.5))return false;
  if(VIEW.skin!=='A'){skinWarn('現在的皮是 '+VIEW.skin);return false}
  if(!SKIN.m){skinWarn('著色器沒開起來');return false}
  if(!TRI.length||!EDG.length||N>65535){skinWarn('沒有三角網');return false}
  return true}
function skinInit(gl,prog,VS){SKIN.m=null;const VM=`#version 300 es
in vec2 p;uniform vec2 t;void main(){gl_Position=vec4(p.x*t.x-1.,1.-p.y*t.y,0.,1.);}`,FM=`#version 300 es
precision mediump float;out vec4 o;void main(){o=vec4(1.);}`,VC=`#version 300 es
in vec2 p;in vec4 ab;in float rr;uniform vec2 t;uniform float uR;out vec2 q;flat out vec4 sg;flat out float rd;void main(){float r=uR*rr;rd=r;vec2 a=ab.xy,b=ab.zw,d=b-a;float L=length(d);vec2 u=L>1e-5?d/L:vec2(1.,0.),n=vec2(-u.y,u.x);q=mix(a,b,p.x)+u*(p.x*2.-1.)*(r+1.)+n*p.y*(r+1.);sg=ab;gl_Position=vec4(q.x*t.x-1.,1.-q.y*t.y,0.,1.);}`,FC=`#version 300 es
precision highp float;in vec2 q;flat in vec4 sg;flat in float rd;out vec4 o;void main(){float r=rd;if(r<.05)discard;vec2 a=sg.xy,ba=sg.zw-a,pa=q-a;float h=clamp(dot(pa,ba)/max(dot(ba,ba),1e-6),0.,1.);o=vec4(clamp(r+.5-length(pa-ba*h),0.,1.));}`,FX1=`#version 300 es
precision mediump float;in vec2 v;out vec4 o;uniform sampler2D t;void main(){o=vec4(texture(t,v).r);}`;
  const M={pm:prog(VM,FM),pc:prog(VC,FC),px:prog(VS,FX1),key:null,W:0,H:0};
  M.ut=gl.getUniformLocation(M.pm,'t');M.ct=gl.getUniformLocation(M.pc,'t');M.cr=gl.getUniformLocation(M.pc,'uR');M.xt=gl.getUniformLocation(M.px,'t');
  M.va=gl.createVertexArray();gl.bindVertexArray(M.va);M.vb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M.vb);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);M.ib=gl.createBuffer();gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,M.ib);
  M.vc=gl.createVertexArray();gl.bindVertexArray(M.vc);const qb=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,qb);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([0,-1,1,-1,0,1,1,1]),gl.STATIC_DRAW);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);
  for(const [nm,sz,key] of [['ab',4,'eb'],['rr',1,'rb']]){M[key]=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,M[key]);const l=gl.getAttribLocation(M.pc,nm);gl.enableVertexAttribArray(l);gl.vertexAttribPointer(l,sz,gl.FLOAT,false,0,0);gl.vertexAttribDivisor(l,1)}
  gl.bindVertexArray(null);SKIN.m=M}
// 網格換了（建身體、補點、換回來）才重算：外框邊所屬三角形的第三個頂點（判斷哪邊是裡面，翻面也對）、每顆最近的外框點、索引
function skinMesh(gl,M,n,nb){M.key=TRI;M.rad=new Float32Array(EDG.length/2);M.ev=new Float32Array(EDG.length*2);M.near=new Int32Array(n);M.g=new Float32Array(nb);M.T=new Float32Array(nb);M.nx=new Float32Array(2*nb);M.v=new Float32Array(2*n);M.ix=new Float32Array(2*n);
  for(let i=0;i<n;i++){if(BIDX[i]>=0){M.near[i]=BIDX[i];continue}let bd=1e18,bk=0;for(let k=0;k<nb;k++){const e=(Q0X[bnd[k]]-Q0X[i])**2+(Q0Y[bnd[k]]-Q0Y[i])**2;if(e<bd){bd=e;bk=k}}M.near[i]=bk}
  M.t3=new Int32Array(nb).fill(-1);const em=new Map();bnd.forEach((b,k)=>em.set(b+'_'+bnd[(k+1)%nb],k));
  for(let k=0;k<TRI.length;k+=3)for(const [a,b,c] of [[0,1,2],[1,2,0],[2,0,1]]){const u=TRI[k+a],w=TRI[k+b];let e=em.get(u+'_'+w);if(e==null)e=em.get(w+'_'+u);if(e!=null)M.t3[e]=TRI[k+c]}
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,M.ib);gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,Uint16Array.from(TRI),gl.STATIC_DRAW)}
// 每個外框點往裡量到對面外框多遠（像素，最多量 SKINT.cap R）
function skinThick(M,v,nb,Rz){const T=M.T,cap=SKINT.cap*Rz,far=(cap+60)*(cap+60);
  for(let k=0;k<nb;k++){const b=bnd[k],p=(k+nb-1)%nb,nxs=M.nx[2*k]+M.nx[2*p],nys=M.nx[2*k+1]+M.nx[2*p+1],d=Math.hypot(nxs,nys);let best=cap;if(d<1e-4){T[k]=0;continue}const nx=nxs/d,ny=nys/d,x=v[2*b],y=v[2*b+1];
    for(let m=0;m<nb;m++){if(m===k||(m+1)%nb===k)continue;const a=bnd[m],c=bnd[(m+1)%nb],ax=v[2*a]-x,ay=v[2*a+1]-y,bx=v[2*c]-x,by=v[2*c+1]-y;if(Math.min(ax*ax+ay*ay,bx*bx+by*by)>far)continue;const ex=bx-ax,ey=by-ay,den=nx*ey-ny*ex;if(Math.abs(den)<1e-9)continue;const q=(ax*ey-ay*ex)/den,u=(ax*ny-ay*nx)/den;if(q>.5&&u>=0&&u<=1&&q<best)best=q}
    T[k]=best}
  return T}
function skinMask(tr,k,grow,extra){const gl=JEL.gl,M=SKIN.m,n=N,nb=bnd.length,A=tr.a*k,B=tr.b*k,C=tr.c*k,D=tr.d*k,E=tr.e*k,F0=tr.f*k,zz=Math.sqrt(Math.abs(A*D-B*C)),Rz=R*zz,rr=Rz*SKINT.w/2;
  gl.bindVertexArray(M.va);
  if(M.key!==TRI)skinMesh(gl,M,n,nb);
  const v=M.v,put=(i,x,y)=>{v[2*i]=A*x+C*y+E;v[2*i+1]=B*x+D*y+F0;grow(x,y,R*.08)};
  for(let i=0;i<n;i++)if(BIDX[i]<0)put(i,X[i],Y[i]);
  for(let i=0;i<nb;i++){const a=bnd[(i+nb-1)%nb],b=bnd[i],c=bnd[(i+1)%nb];put(b,X[a]*.25+X[b]*.5+X[c]*.25,Y[a]*.25+Y[b]*.5+Y[c]*.25)}   // 外框點跟 boundaryPts 一樣抹一次
  if(M.W!==W||M.H!==H){M.W=W;M.H=H;if(M.rbf){gl.deleteRenderbuffer(M.rbf);gl.deleteFramebuffer(M.fb);gl.deleteFramebuffer(M.ft);gl.deleteTexture(M.tx)}
    M.rbf=gl.createRenderbuffer();gl.bindRenderbuffer(gl.RENDERBUFFER,M.rbf);gl.renderbufferStorageMultisample(gl.RENDERBUFFER,4,gl.RGBA8,W,H);M.fb=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,M.fb);gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.RENDERBUFFER,M.rbf);
    M.tx=gl.createTexture();gl.activeTexture(gl.TEXTURE0);JEL.params(gl,M.tx);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA8,W,H,0,gl.RGBA,gl.UNSIGNED_BYTE,null);M.ft=gl.createFramebuffer();gl.bindFramebuffer(gl.FRAMEBUFFER,M.ft);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,M.tx,0)}
  gl.bindFramebuffer(gl.FRAMEBUFFER,M.fb);gl.viewport(0,0,W,H);gl.disable(gl.SCISSOR_TEST);gl.clearColor(0,0,0,0);gl.clear(gl.COLOR_BUFFER_BIT);gl.enable(gl.BLEND);gl.blendEquation(gl.MAX);gl.blendFunc(gl.ONE,gl.ONE);
  gl.bindBuffer(gl.ARRAY_BUFFER,M.vb);gl.bufferData(gl.ARRAY_BUFFER,v,gl.DYNAMIC_DRAW);gl.useProgram(M.pm);gl.uniform2f(M.ut,2/W,2/H);gl.drawElements(gl.TRIANGLES,TRI.length,gl.UNSIGNED_SHORT,0);
  // 薄的地方：每條網格邊一顆膠囊，寬度照兩端離最近外框的厚度
  const NX=M.nx,IX=M.ix,ev=M.ev,g=M.g;IX.set(v);
  for(let q=0;q<nb;q++){const i=bnd[q],j=bnd[(q+1)%nb],c=M.t3[q];let nx=0,ny=0;if(c>=0){const ex=v[2*j]-v[2*i],ey=v[2*j+1]-v[2*i+1],tx=v[2*c]-v[2*i],ty=v[2*c+1]-v[2*i+1],sd=ex*ty-ey*tx>=0?1:-1,l=Math.hypot(ex,ey)||1;nx=-ey/l*sd;ny=ex/l*sd}NX[2*q]=nx;NX[2*q+1]=ny}
  for(let q=0;q<nb;q++){const b=bnd[q],p=(q+nb-1)%nb,ax=NX[2*q]+NX[2*p],ay=NX[2*q+1]+NX[2*p+1],d=Math.hypot(ax,ay);if(d<1e-4)continue;IX[2*b]+=ax/d*rr;IX[2*b+1]+=ay/d*rr}
  const wl=worldWalls();
  if(Math.abs(B)<1e-9&&Math.abs(C)<1e-9&&isFinite(wl.b)){const yb=D*wl.b+F0-rr;for(let i=0;i<n;i++)if(IX[2*i+1]>yb)IX[2*i+1]=yb}   // 貼地的線往上挪一個半徑
  const T=skinThick(M,v,nb,Rz);for(let q=0;q<nb;q++)g[q]=Math.max(0,Math.min(1,(SKINT.hi*Rz-T[q])/((SKINT.hi-SKINT.lo)*Rz)));
  for(let e=0,m=0;e<EDG.length;e+=2,m+=4){const i=EDG[e],j=EDG[e+1];M.rad[e/2]=Math.max(g[M.near[i]],g[M.near[j]]);ev[m]=IX[2*i];ev[m+1]=IX[2*i+1];ev[m+2]=IX[2*j];ev[m+3]=IX[2*j+1]}
  const X0=Math.max(0,Math.floor(isFinite(wl.l)?A*wl.l+E:0)),X1=Math.min(W,isFinite(wl.r)?A*wl.r+E:W),Y1=Math.max(1,Math.min(H,(isFinite(wl.b)?D*wl.b+F0:H)+1));   // 線畫到牆、地板為止
  gl.enable(gl.SCISSOR_TEST);gl.scissor(X0,Math.max(0,Math.floor(H-Y1)),Math.max(0,Math.ceil(X1-X0)),Math.ceil(Y1));
  gl.bindVertexArray(M.vc);gl.bindBuffer(gl.ARRAY_BUFFER,M.eb);gl.bufferData(gl.ARRAY_BUFFER,ev,gl.DYNAMIC_DRAW);gl.bindBuffer(gl.ARRAY_BUFFER,M.rb);gl.bufferData(gl.ARRAY_BUFFER,M.rad,gl.DYNAMIC_DRAW);gl.useProgram(M.pc);gl.uniform2f(M.ct,2/W,2/H);gl.uniform1f(M.cr,rr);gl.drawArraysInstanced(gl.TRIANGLE_STRIP,0,4,EDG.length/2);gl.disable(gl.SCISSOR_TEST);
  gl.bindVertexArray(null);
  if(extra){gl.useProgram(M.px);gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,JEL.tM);gl.uniform1i(M.xt,0);gl.drawArrays(gl.TRIANGLES,0,3)}   // 黏條、第二團照舊畫在 2D 遮罩，疊上來
  gl.disable(gl.BLEND);gl.blendEquation(gl.FUNC_ADD);
  gl.bindFramebuffer(gl.READ_FRAMEBUFFER,M.fb);gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER,M.ft);gl.blitFramebuffer(0,0,W,H,0,0,W,H,gl.COLOR_BUFFER_BIT,gl.NEAREST);return M.tx}
// 身體裡的東西怎麼剪：舊的皮用外框路徑；新的皮先畫在暫存畫布（這裡不剪），畫完在 skinLayer 用遮罩剪
function fxClip(P){if(SKIN.base)return;jelPath(ctx,P);ctx.clip()}
function skinLayer(fn){const w=cv.width,hh=cv.height;if(!SKIN.lay){SKIN.lay=document.createElement('canvas');SKIN.lctx=SKIN.lay.getContext('2d')}
  if(SKIN.lay.width!==w||SKIN.lay.height!==hh){SKIN.lay.width=w;SKIN.lay.height=hh}
  const l=SKIN.lctx,base=ctx;l.setTransform(1,0,0,1,0,0);l.globalCompositeOperation='source-over';l.globalAlpha=1;l.clearRect(0,0,w,hh);l.setTransform(base.getTransform());
  SKIN.base=base;ctx=l;try{fn()}finally{ctx=base;SKIN.base=null}
  base.lineCap=l.lineCap;base.lineJoin=l.lineJoin;   // 眼睛設的筆頭以前會留在主畫布上，照舊留著
  if(!SKIN.covered)jelCover();
  l.setTransform(1,0,0,1,0,0);l.globalAlpha=1;l.globalCompositeOperation='destination-in';l.drawImage(JEL.c,0,0);l.globalCompositeOperation='source-over';
  base.save();base.setTransform(1,0,0,1,0,0);base.drawImage(SKIN.lay,0,0);base.restore()}
// 皮的透明度不是滿的（水關掉時）：剪之前把畫布換成純遮罩。皮這時已經貼到主畫布上了
function jelCover(){const gl=JEL.gl;gl.useProgram(JEL.pF);gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.viewport(0,0,JEL.c.width,JEL.c.height);gl.clearColor(0,0,0,0);gl.disable(gl.SCISSOR_TEST);gl.clear(gl.COLOR_BUFFER_BIT);gl.uniform1f(JEL.uF.cov1,1);gl.drawArrays(gl.TRIANGLES,0,3);gl.uniform1f(JEL.uF.cov1,0);SKIN.covered=true}
const JEL={gl:null,'''
rep("const JEL={gl:null,",SKIN)
rep("absorb,opq;\nfloat H1","absorb,opq,cov1;\nfloat H1")
rep("smoothstep(.18,.82,m);if(cov<=0.){o=vec4(0.);return;}","smoothstep(.18,.82,m);if(cov<=0.){o=vec4(0.);return;}if(cov1>.5){o=vec4(cov);return;}")
rep("'absorb','opq'])JEL.uF","'absorb','opq','cov1'])JEL.uF")
rep("JEL.b2=JEL.bc.getContext('2d');\n  JEL.gl=gl;","JEL.b2=JEL.bc.getContext('2d');\n  try{skinInit(gl,prog,VS)}catch(err){SKIN.m=null;console.warn(err)}gl.bindVertexArray(null);gl.bindBuffer(gl.ARRAY_BUFFER,q);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,2,gl.FLOAT,false,0,0);   // v2.61\n  JEL.gl=gl;")
rep("""  m.setTransform(1,0,0,1,0,0);m.fillStyle='#000';m.fillRect(0,0,W,H);m.setTransform(tr.a*k,tr.b*k,tr.c*k,tr.d*k,tr.e*k,tr.f*k);m.fillStyle='#fff';
  jelPath(m,P);m.fill();
""","""  const skn=skinOn(),ext=GOO.length>0||B2.on;   // v2.61：新的皮只有黏條、第二團還用 2D 遮罩
  if(!skn||ext){m.setTransform(1,0,0,1,0,0);m.fillStyle='#000';m.fillRect(0,0,W,H);m.setTransform(tr.a*k,tr.b*k,tr.c*k,tr.d*k,tr.e*k,tr.f*k);m.fillStyle='#fff'}
  if(!skn){jelPath(m,P);m.fill()}
""")
rep("""  extraMask(m,grow);   // v2.51 黏條、小的那團
  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,JEL.tM);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,JEL.mc);
""","""  if(!skn||ext){extraMask(m,grow);   // v2.51 黏條、小的那團
  gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,JEL.tM);gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,JEL.mc)}
  const TM=skn?skinMask(tr,k,grow,ext):JEL.tM;SKIN.used=skn;
""")
rep("blur(JEL.tM,JEL.h1,","blur(TM,JEL.h1,");rep("blur(JEL.tM,JEL.q1,","blur(TM,JEL.q1,");rep("[[JEL.tM,U.M],","[[TM,U.M],")
rep("  gl.uniform1f(U.water,wat);gl.uniform1f(U.refr,","  SKIN.covered=wat>=1;gl.uniform1f(U.water,wat);gl.uniform1f(U.refr,")
rep("  ctx.save();jelPath(ctx,P);ctx.clip();\n  if(cl>.01)","  ctx.save();fxClip(P);\n  if(cl>.01)")
rep("  if(SNW.glow>.01){ctx.save();const g=ctx.createRadialGradient(c.xc,c.yc,R*.6","  if(SNW.glow>.01){const x=ctx;if(SKIN.base)ctx=SKIN.base;ctx.save();const g=ctx.createRadialGradient(c.xc,c.yc,R*.6")
rep("ctx.fillStyle=g;ctx.fillRect(c.xc-R*2,c.yc-R*2,R*4,R*4);ctx.restore()}}","ctx.fillStyle=g;ctx.fillRect(c.xc-R*2,c.yc-R*2,R*4,R*4);ctx.restore();ctx=x}}")
rep("  ctx.save();jelPath(ctx,P);ctx.clip();\n  for(const [i,rr,ph] of BUB.list)","  ctx.save();fxClip(P);\n  for(const [i,rr,ph] of BUB.list)")
rep("if(f===FX0)return;ctx.save();jelPath(ctx,P);ctx.clip();","if(f===FX0)return;ctx.save();fxClip(P);")
rep("S=R*(mat.eyeSize||1);ctx.save();jelPath(ctx,P);ctx.clip();","S=R*(mat.eyeSize||1);ctx.save();fxClip(P);")
rep("ctx.drawImage(JEL.c,0,0);ctx.restore();drawBubbles(P);drawFx(P);drawGlitter(P);drawBlush(P);drawEyes(col);drawStuck();","ctx.drawImage(JEL.c,0,0);ctx.restore();const inBody=()=>{drawBubbles(P);drawFx(P);drawGlitter(P);drawBlush(P);drawEyes(col)};if(SKIN.used)skinLayer(inBody);else inBody();drawStuck();")
rep("return}   // v2.28 預覽：果凍皮畫身體\n","return}   // v2.28 預覽：果凍皮畫身體\n  if(mat.skinU>=.5)skinWarn(VIEW.skin==='flat'?'現在是平塗':'WebGL 開不起來');\n")
# --- 換隻、換材質
rep("...s.p,...viewOver()};if(one0!=null&&one0<.5)","...s.p,...viewOver(),...keep61};if(one0!=null&&one0<.5)")
rep("const s=SLIMES[i],one0=mat?mat.one:null,clr0=mat?mat.clear:0;","const s=SLIMES[i],one0=mat?mat.one:null,clr0=mat?mat.clear:0,keep61=matKeep(mat);")
rep("function setMat(name){const s=SLIMES[SLIME],clr0=mat.clear;mat={...PRESETS[name],seed:s.seed,...s.p,...viewOver()};","function setMat(name){const s=SLIMES[SLIME],clr0=mat.clear;mat={...PRESETS[name],seed:s.seed,...s.p,...viewOver(),...matKeep(mat)};")
# --- 隱藏面板：網址鎖住時不露
rep("  for(const [key,name,hint,min,max,step] of F){\n","  for(const [key,name,hint,min,max,step] of F){if(PULLQ&&PULL3.includes(key))continue;   // 網址鎖住時不放，盲比才看不到是哪一邊\n")
rep("function dump(){$('t-out').value=JSON.stringify({...mat,float:FLOAT})}","function dump(){const o={...mat,float:FLOAT};if(PULLQ)for(const k of PULL3)delete o[k];$('t-out').value=JSON.stringify(o)}")
open(P,'w',encoding='utf-8',newline='').write(s.replace('\n','\r\n'))
print('ok')
