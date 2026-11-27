// S2 對照：把 SlimeRig.swift 的原文機械轉成 JS，跟 F1 補丁（diff 的 + 行）和 index.html 的原文算同一組亂數輸入
const fs=require('fs');
const ROOT='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/';
const sw=fs.readFileSync(ROOT+'ios/NieNie/Slime/SlimeRig.swift','utf8').replace(/\r/g,'');
const web=fs.readFileSync(ROOT+'prototype/web/index.html','utf8').replace(/\r/g,'');
const diff=fs.readFileSync(ROOT+'.vibe/audit-2026-11-24/patches/合併-F1開關+F2遮罩+手機彈簧開關-對HEAD-v2.60.diff','utf8').replace(/\r/g,'');
const plus=diff.split('\n').filter(l=>l[0]==='+').map(l=>l.slice(1));
const one=(a,f)=>{const r=a.filter(f);if(r.length!==1)throw Error('找到 '+r.length+' 行：'+f);return r[0]};
const between=(s,a,b,inc)=>{const i=s.indexOf(a);if(i<0||s.indexOf(a,i+1)>=0)throw Error('標記不唯一 '+a);const j=s.indexOf(b,i+a.length);if(j<0)throw Error('尾 '+b);return s.slice(i,j+(inc?b.length:0))};
function s2j(x){return x.split('\n').map(l=>l.replace(/\s*\/\/.*$/,'')).join('\n')
  .replace(/([,( ]|let |var )(\w+): (?:Double|Bool|Int)(?= =)/g,'$1$2')
  .replace(/\bvar\b/g,'let')
  .replace(/for (\w+) in 0\.\.<(\w+) \{/g,'for(let $1=0;$1<$2;$1++){')
  .replace(/for (\w+) in bnd \{/g,'for(const $1 of bnd){')
  .replace(/if params\.pullWhole[^\n]*\{(?=\s*\n)/,'const f=fl.find(q=>q.mode===".grab"),r0x=f&&f.r0x;if(params.pullWhole>=.5&&n===1&&f&&r0x!=null){')
  .replace(/\bif (?![(!])([^{\n]+?) \{/g,'if($1){').replace(/\bif !(\(.+?\)) \{/g,'if(!$1){')
  .replace(/if \(/g,'if(')
  .replace(/\b(hypot|sqrt|tanh|max|min)\(/g,'Math.$1(')
  .replace(/return \(([^\n}]+), n\)/g,'return [$1, n]').replace(/return \(0, 0, 0\)/,'return [0,0,0]')}
// Swift 的常數
const PullSet={};for(const m of between(sw,'private enum PullSet {','\n    }').matchAll(/(\w+): Double = ([\d.]+)/g))PullSet[m[1]]=+m[2];
console.log('Swift 常數',JSON.stringify(PullSet));
const wc=web.split('\n').filter(l=>/^const PULL(STILL|HOLD|WHOLE|SOFT)=/.test(l)).map(l=>l.replace(/\/\/.*$/,'').replace(/^const /,'var ')).join('\n');
console.log('網頁常數',wc.replace(/\n/g,' '));
let seed=7;const rnd=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296},rr=(a,b)=>a+(b-a)*rnd();
let fail=0;const rep=(n,cnt,d,ex)=>{console.log((d===0?'一樣 ':d<1e-12?'一樣（捨入內）':'不同 ')+n+' 組數 '+cnt+' 最大差 '+d+(ex?' '+ex:''));if(!(d<1e-12))fail++};
const dm=(a,b)=>Math.abs(a-b);

// ---- A4 iw
{const body=s2j(between(sw,'        var dx: Double = sx / Double(n)','\n    }\n    /// A finger joined').replace(/Double\(n\)/g,'n'));
 const S=new Function('sx','sy','n','fl','params','R','PullSet','smooth01','slideLen','dragFollow',body);
 const wl=web.split('\n'),i0=wl.findIndex(l=>l.startsWith('function dragTarget()')),wsrc=wl.slice(i0,i0+6).join('\n');
 const W=new Function('mat','fingers','R','smooth01','slideLen','dragFollow',wc+'\n'+between(web,'function dragTarget()','// 手指換了').replace(/\/\/.*$/gm,'')+';return dragTarget()');
 const pl=one(plus,l=>l.startsWith('  let dx=sx/n,dy=sy/n,dl='));
 const P=new Function('F1X','fingers','R','smooth01','slideLen','dragFollow','let sx=0,sy=0,n=0;for(const f of fingers.values())if(f.mode==="grab"){if(!f.tug){sx+=f.x-f.ax;sy+=f.y-f.ay}n++}if(!n)return[0,0,0];'+pl.replace(/\}\s*$/,''));
 const sm=x=>x<=0?0:x>=1?1:x*x*(3-2*x);let d0=0,d1=0,dz=0,act=0;const K=200000;
 for(let k=0;k<K;k++){const R=100,nf=rnd()<.8?1:2,fs=[];for(let q=0;q<nf;q++){const a=rr(0,6.3),l=rr(0,5)*R,ra=rr(0,6.3),rl=rr(0,1.6)*R;fs.push({mode:'grab',ax:200,ay:300,x:200+l*Math.cos(a),y:300+l*Math.sin(a),r0x:rl*Math.cos(ra),r0y:rl*Math.sin(ra),tug:rnd()<.05})}
  const fin=new Map(fs.map((f,i)=>[i,f])),sl=()=>150,df=()=>.3;
  let sx=0,sy=0,n=0;for(const f of fs){if(!f.tug){sx+=f.x-f.ax;sy+=f.y-f.ay}n++}
  const fl=fs.map(f=>({mode:'.grab',r0x:f.r0x,r0y:f.r0y}));
  for(const on of [1,0]){const a=S(sx,sy,n,fl,{pullWhole:on},R,PullSet,sm,sl,df),b=W({slide:1.5,pullWhole:on},fin,R,sm,sl,df),c=P({iw:on},fin,R,sm,sl,df);
   const e=Math.max(...a.map((v,i)=>dm(v,b[i]))),g=Math.max(...a.map((v,i)=>dm(v,c[i])));
   if(on){d0=Math.max(d0,e);d1=Math.max(d1,g);const z=P({iw:0},fin,R,sm,sl,df);if(dm(z[0],a[0])>1e-9)act++}else dz=Math.max(dz,e,g)}}
 rep('A4 iw Swift 對網頁',K,d0,'（有作用 '+act+' 組）');rep('A4 iw Swift 對補丁',K,d1);rep('A4 關掉時 Swift 對網頁、補丁',K,dz)}

// ---- A3 cr 計時與倍數
{const hb=s2j(between(sw,'        let g0: Double = pullStillT','\n    }'));
 const S=new Function('pullStillT','pullK','mat','PullSet',hb.replace(/max\(/g,m=>m));
 const W=new Function('PULLT0','pk',wc+'\nlet PULLT=PULLT0;const pullK=()=>pk;'+one(web.split('\n'),l=>l.startsWith('function pullHoldK()')).replace(/\/\/.*$/,'')+';return pullHoldK()');
 let d=0;const K=100000;for(let k=0;k<K;k++){const T=rr(0,1),p=rnd()<.2?0:rnd();d=Math.max(d,dm(S(T,()=>p,{},PullSet),W(T,p)))}rep('A3 cr 倍數 Swift 對網頁',K,d);
 // 補丁：F1S 自己計時。餵同一串手指速度
 const f1=one(plus,l=>l.startsWith('let F1S=0;function f1Creep'));
 const mk=new Function('F1X','mv','pk','let cur=false,kk=0;function f1Moving(){return cur}function pullK(){return kk}'+f1+';return(dt,m,p)=>{cur=m;kk=p;return f1Creep(dt)}');
 let dd=0,n=0;for(let r=0;r<400;r++){const c=mk({cr:1});let T=0;for(let i=0;i<400;i++){const m=rnd()<.03,p=rnd(),dt=1/60;const b=c(dt,m,p);T=m?0:T+dt;dd=Math.max(dd,dm(S(T,()=>p,{},PullSet),b));n++}}rep('A3 cr 計時＋倍數 Swift 對補丁（都在記形那條路時）',n,dd);
 const st=between(sw,'        pullStillT = pullMoving() ?','\n');if(!/pullMoving\(\) \? 0 : pullStillT \+ dt/.test(st))fail++;
 const kcw=/\*\(mat\.pullHold>=\.5\?pullHoldK\(\):1\);/.test(web),kcs=/mat\.pullHold >= 0\.5 \? kc0 \* pullHoldK\(mat\) : kc0/.test(sw);console.log('kc 乘上倍數：網頁',kcw,'Swift',kcs);if(!kcw||!kcs)fail++}

// ---- A5 vc 放手限速
{const body=s2j(between(sw,'            let lim: Double = PullSet.relV * R * dt','        } else {'));
 const S=new Function('X','Y','PX','PY','N','R','dt','damp','Gh','G','PullSet',body);
 const wl=one(web.split('\n'),l=>l.includes('PULLSOFT.relV*R*dt')),W=new Function('X','Y','PX','PY','N','R','dt','damp','Gh','G',wc+'\n'+wl.slice(wl.indexOf('{const lim='),wl.lastIndexOf('}   //')+1));
 const pl=one(plus,l=>l.includes('F1X.vc*R*dt')),a=pl.indexOf('{const lim=F1X.vc'),P=new Function('F1X','X','Y','PX','PY','N','R','dt','damp','Gh','G',pl.slice(a,pl.indexOf('}}else for',a)+2));
 let d0=0,d1=0,hit=0;const K=300;for(let k=0;k<K;k++){const N=500,R=100,dt=1/240,mk=()=>Array.from({length:N},()=>rr(0,400)),X=mk(),Y=mk(),PX=X.map(v=>v+rr(-6,6)),PY=Y.map(v=>v+rr(-6,6));
  const c=()=>[[...X],[...Y],[...PX],[...PY]],A=c(),B=c(),C=c(),gh=rr(-30,30),g=1400;S(...A,N,R,dt,.94,gh*dt*dt,g*dt*dt,PullSet);W(...B,N,R,dt,.94,gh,g);P({vc:6},...C,N,R,dt,.94,gh,g);
  for(let q=0;q<4;q++)for(let i=0;i<N;i++){d0=Math.max(d0,dm(A[q][i],B[q][i]));d1=Math.max(d1,dm(A[q][i],C[q][i]))}
  for(let i=0;i<N;i++)if(Math.hypot(X[i]-PX[i],Y[i]-PY[i])*.94>6*R*dt)hit++}
 rep('A5 vc Swift 對網頁',K*500,d0,'（被限到 '+hit+' 顆）');rep('A5 vc Swift 對補丁',K*500,d1)}

// ---- A5 up 回正限速
{const body=s2j(between(sw,'            var rm = 0.0\n            for i in bnd {','        }\n        if rotK != 0'));
 const S=new Function('rotK','X','Y','bnd','gcx','gcy','R','dt','PullSet',body+';return rotK');
 const wl=one(web.split('\n'),l=>l.includes('PULLSOFT.upright*R*dt')),W=new Function('rotK','X','Y','bnd','cx','cy','R','dt',wc+'\n'+wl.slice(wl.indexOf('{let rm=0'),wl.lastIndexOf('}   //')+1)+';return rotK');
 const pl=one(plus,l=>l.includes('F1X.up*R*dt')),i=pl.indexOf('{let rm=0'),P=new Function('F1X','rotK','X','Y','bnd','cx','cy','R','dt',pl.slice(i,pl.indexOf('}   //',i)+1)+';return rotK');
 let d0=0,d1=0,hit=0;const K=20000;for(let k=0;k<K;k++){const n=60,s=rr(.2,5)*100,X=Array.from({length:n},()=>rr(-s,s)),Y=Array.from({length:n},()=>rr(-s,s)),b=X.map((_,q)=>q),r=rr(-.1,.1),a=[r,X,Y,b,3,4,100,1/240],v=S(...a,PullSet);if(v!==r)hit++;d0=Math.max(d0,dm(v,W(...a)));d1=Math.max(d1,dm(v,P({up:3},...a)))}
 rep('A5 up Swift 對網頁',K,d0,'（被限到 '+hit+' 次）');rep('A5 up Swift 對補丁',K,d1)}

// ---- A2 gv 條件
{const body=s2j(between(sw,'                var heldBack = false','                if sw > 0 && !heldBack'));
 const S=new Function('f','sx','sy','R','mat','pullStillT','PullSet',body+';return heldBack');
 const wl=one(web.split('\n'),l=>l.includes('R*PULLSOFT.drift')),W=new Function('f','sx','sy','R','mat','PULLT',wc+'\nreturn ('+wl.slice(wl.indexOf('!(mat.pullSoft')+1,wl.indexOf('{const cs=effSlip()')-1)+')');
 const pl=one(plus,l=>l.includes('F1X.gvL||.3')),P=new Function('f','sx','sy','R','F1X','F1S','return ('+pl.slice(pl.indexOf('!(F1X.gv')+1,pl.indexOf('{const cs=effSlip()')-1)+')');
 let bad=0,hit=0;const K=200000;for(let k=0;k<K;k++){const f={slx:rr(-80,80)*(rnd()<.1?0:1),sly:rr(-80,80)*(rnd()<.1?0:1)},sx=rnd()<.05?0:rr(-9,9),sy=rnd()<.05?0:rr(-9,9),T=rr(0,.6),on=rnd()<.8?1:0,a=!!S(f,sx,sy,100,{pullSoft:on},T,PullSet),b=!!W(f,sx,sy,100,{pullSoft:on},T),c=!!P(f,sx,sy,100,{gv:on},T);if(a)hit++;if(a!==b||a!==c)bad++}
 rep('A2 gv 條件 Swift 對網頁、補丁',K,bad,'（擋下 '+hit+' 次）')}

// ---- A2 bl、A5 fl 的外框長
{const body=s2j(between(sw,'        var s = 0.0\n        let n = bnd.count\n        for k in 0..<n { let i = bnd[k], j = bnd[(k + 1) % n]; s += hypot(QX','\n    }').replace('bnd.count','bnd.length'));
 const S=new Function('bnd','QX','QY',body),W=new Function('bnd','QX','QY',one(web.split('\n'),l=>l.startsWith('function memLen()')).replace(/\/\/.*$/,'')+';return memLen()'),P=new Function('bnd','QX','QY',one(plus,l=>l.startsWith('function f1Per()'))+';return f1Per()');
 let d=0;const K=2000;for(let k=0;k<K;k++){const n=70,X=Array.from({length:n},()=>rr(-200,200)),Y=Array.from({length:n},()=>rr(-200,200)),b=X.map((_,q)=>(q*13)%n),v=S(b,X,Y);d=Math.max(d,dm(v,W(b,X,Y)),dm(v,P(b,X,Y)))}rep('A2 bl、A5 fl 外框長 Swift 對網頁、補丁',K,d)}
console.log(fail?'有 '+fail+' 項不同':'全部一樣');
