// 修洞對照（v2.61 D1 rough 補：dragFollow、tugIn）：把 SlimeRig.swift 的原文機械轉成 JS，跟 index.html 的原文吃同一組輸入比。
// 動工前的 SlimeRig.swift（git show 0844ceb，網頁修了、Swift 還沒）也轉一份，rough 0 時要逐位元相同。
// 重跑：在工作樹根目錄 node .vibe/audit-2026-11-24/v2.61/修洞-算式對照.js
// 網頁固定拿 0844ceb；加 --live 改讀工作樹。只證明算式一樣，不證明 Swift 編得過；閉環那段的拉開量是照 slide 公式算的，不是物理。
const fs=require('fs'),cp=require('child_process'),path=require('path');
const ROOT=path.resolve(__dirname,'../../..')+'/',SW='ios/NieNie/Slime/SlimeRig.swift',HT='prototype/web/index.html',BASE='0844ceb';
const rd=s=>s.replace(/\r/g,''),git=f=>rd(cp.execFileSync('git',['show',BASE+':'+f],{cwd:ROOT,maxBuffer:1<<26}).toString('utf8'));
const swNew=rd(fs.readFileSync(ROOT+SW,'utf8')),swOld=git(SW),web=process.argv.includes('--live')?rd(fs.readFileSync(ROOT+HT,'utf8')):git(HT);
let fail=0;

// ---------- Swift → JS（只做字面改寫）
const strip=x=>x.split('\n').map(l=>l.replace(/\s*\/\/.*$/,'')).join('\n');
const once=(s,a)=>{const i=s.indexOf(a);if(i<0||s.indexOf(a,i+1)>=0)throw Error('標記'+(i<0?'沒有':'不唯一')+'：'+a);return i};
const cut=(s,a,b)=>{const i=once(s,a),j=s.indexOf(b,i+a.length);if(j<0)throw Error('尾：'+b);return s.slice(i,j)};
const split=c=>{let d=0,o=[],s='';for(const ch of c){if('(['.includes(ch))d++;if(')]'.includes(ch))d--;if(ch===','&&!d){o.push(s.trim());s=''}else s+=ch}o.push(s.trim());return o};
const cond=(c,names)=>split(c).map(p=>{const m=/^let (\w+) = (.+)$/.exec(p);if(m){names.push(m[1]);return`((${m[1]}=${m[2]})!=null)`}return'('+p+')'}).join('&&');
function s2j(x){x=strip(x)
  .replace(/guard (.+?) else \{/g,(_,c)=>{const n=[],e=cond(c,n);return(n.length?'let '+n.join(',')+';':'')+'if(!('+e+')) {'})
  .replace(/\bvar (\w+): Finger\?/g,'let $1=null')
  .replace(/for (\w+) in fingers\.values where (.+?) \{/g,'for(const $1 of fingers.values())if($2) {')
  .replace(/(let |var |, )(\w+): (?:Double|Bool|Int)(?= =)/g,'$1$2').replace(/\bvar\b/g,'let').replace(/\bnil\b/g,'null')
  .replace(/([\s(])\.grab\b/g,"$1'grab'")
  .replace(/(^|[^\w$.])if (?!\()([^{\n]+?) \{/g,'$1if($2){')
  .replace(/(^|[^\w.$])(hypot|max|min|exp|tanh)\(/g,'$1Math.$2(').replace(/(^|[^\w.$])(hypot|max|min|exp|tanh)\(/g,'$1Math.$2(');
  return x}
function fn(src,name,args){const i=once(src,'    private func '+name+'('),nl=src.indexOf('\n',i),line=strip(src.slice(i,nl));
  const body=line.trimEnd().endsWith('}')?line.slice(line.indexOf('{')+1,line.lastIndexOf('}')).replace(/^\s*(?!return)/,' return '):src.slice(nl+1,src.indexOf('\n    }\n',i));
  return'function '+name+'('+args+'){'+s2j(body)+'\n}\n'}
const getter=(src,name)=>{const l=src.split('\n').filter(q=>q.includes('private var '+name+': Bool {'));if(l.length!==1)throw Error(name);return'get '+name+'(){return '+/\{ (.+?) \}/.exec(l[0])[1]+'},'};
const sets=src=>{const o={};for(const m of strip(cut(src,'private enum RoughSet {','}\n')).matchAll(/(\w+): Double = ([\d.]+)/g))o[m[1]]=+m[2];return o};
// 心情那幾行（strain、tugS）：每格更新，閉環用
const moodSw=src=>'function mood(g,st,dt){if(g){'+s2j(cut(src,'            let rough: Bool = !roughOn || g.yank','            if moodStrain > 0 {'))+'}else{'+s2j(cut(src,'            moodStrain *= exp(-dt / 0.2)','            let k = 1 - exp(-dt / 6)'))+'}}\n';
function swSide(src){const ti=src.includes('private func tugIn(');const code=fn(src,'smooth01','x')+fn(src,'iv2','v')+(ti?fn(src,'tugIn',''):'')+fn(src,'dragFollow','')+moodSw(src);
  return new Function('RoughSet','const S={params:{},fingers:new Map(),R:100,impTrust:0,impWary:0,moodStrain:0,moodStrainMax:0,moodTugS:0,'+getter(src,'roughOn').replace('params','this.params')+'};with(S){'+code+';S.F={dragFollow,mood'+(ti?',tugIn':'')+'}}return S')(sets(src))}

// ---------- 網頁原文
const wl=web.split('\n'),one=p=>{const r=wl.filter(l=>l.startsWith(p));if(r.length!==1)throw Error(r.length+' 行 '+p);return r[0]};
const noC=l=>l.replace(/\s*\/\/.*$/,'');
const wfn=(n,k)=>{const i=wl.indexOf(one('function '+n+'('));return wl.slice(i,i+k).map(noC).join('\n')+'\n'};
const wMood=(()=>{const i=wl.findIndex(l=>l.startsWith('    g.strainT=st>1.5&&')),e=wl.findIndex(l=>l.startsWith('  else{MOOD.strain*=Math.exp('));if(i<0||e<0)throw Error('mood');return'function mood(g,st,dt){if(g){'+wl.slice(i,i+3).map(noC).join('\n')+'}else{'+/MOOD\.strain\*=.*?;if\(MOOD\.tugS\).*?;/.exec(wl[e])[0]+'}}\n'})();
const W=new Function('const S={mat:{},fingers:new Map(),R:100,IMP:{tr:0,w:0},MOOD:{strain:0,strainMax:0,tugS:undefined}};with(S){'+noC(one('const ROUGH='))+'\n'+noC(one('const IV2='))+'\n'+noC(one('const smooth01='))+'\n'+wfn('dragFollow',3)+wfn('tugIn',2)+wMood+';S.F={dragFollow,tugIn,mood}}return S')();

console.log('Swift 常數',JSON.stringify(sets(swNew)),'網頁',/const ROUGH=(\{.*?\})/.exec(one('const ROUGH='))[1]);
const N=swSide(swNew),O=swSide(swOld);
if(process.env.DBG)console.log(fn(swNew,'tugIn','')+fn(swNew,'dragFollow','')+moodSw(swNew)+'----\n'+wfn('dragFollow',3)+wfn('tugIn',2)+wMood);

// ---------- 亂數輸入（每一邊自己的手指物件：沒記的 r0x、沒判的 tug，手機是 nil、網頁是 undefined）
let sd=20261126;const rnd=()=>{sd=(Math.imul(sd,1664525)+1013904223)>>>0;return sd/4294967296},rr=(a,b)=>a+(b-a)*rnd(),pick=a=>a[rnd()*a.length|0];
function gen(){const R=pick([100,108,60,160,rr(60,160)]),z=pick([1,1,.8,rr(.3,1.6)]);
  const p={drag:pick([.35,.35,.35,0,rr(0,1),1]),imp:pick([1,1,1,0]),life2:pick([1,1,1,0]),impC3:pick([0,1]),emo:pick([1,1,1,0,.5,.49]),rough:pick([1,1,1,0,.5,.49])};
  const s={strain:pick([0,0,0,0,rnd(),1]),tugS:pick([undefined,0,rnd(),rnd(),1]),tr:pick([0,rnd(),1]),w:pick([0,rnd(),1])};
  const nf=pick([0,1,1,1,1,1,1,2,2,3,4]),list=[];
  for(let q=0;q<nf;q++){const cx=rr(-400,800),cy=rr(-400,1200),a=rr(0,6.2832),rl=pick([rr(0,1.6),rr(0,1.6),rr(.3,.7),rr(.3,.7),rr(.3,.7),rr(.08,.12),pick([0,.1,.35,.6])])*R,r0x=rl*Math.cos(a),r0y=rl*Math.sin(a);
    const b=rnd()<.75?a+Math.PI+rr(-1.2,1.2):rr(0,6.2832),dl=pick([rr(0,5),rr(0,5),rr(0,5),rr(0,5),rr(.08,.12),pick([0,.1])])*R;
    let ax=cx+r0x,ay=cy+r0y,x=ax,y=ay;const k=1+(rnd()*4|0);   // 螢幕上走 dl×倍數、世界除以倍數；中途縮放（x、y 跟 ax、ay 一起搬，窗台拉遠那段）
    for(let i=0;i<k;i++){x+=Math.cos(b)*dl*z/k/z;y+=Math.sin(b)*dl*z/k/z;if(rnd()<.3){const mx=rr(-200,200)/z,my=rr(-200,200)/z;x+=mx;y+=my;ax+=mx;ay+=my}}
    list.push({mode:pick(['grab','grab','grab','grab','grab','grab','grab','grab','push','stroke','none']),ax,ay,x,y,r:rnd()<.1?null:[r0x,r0y],tug:pick([null,null,null,false,false,false,false,true])})}
  return{R,p,s,fs:list}}
const order=a=>{const b=a.slice();for(let i=b.length-1;i>0;i--){const j=rnd()*(i+1)|0;[b[i],b[j]]=[b[j],b[i]]}return b};   // 手機的 fingers 是 Dictionary，順序不定
function put(g){for(const S of[N,O]){Object.assign(S,{params:g.p,R:g.R,impTrust:g.s.tr,impWary:g.s.w,moodStrain:g.s.strain,moodTugS:g.s.tugS||0});S.fingers=new Map(order(g.fs).map((f,i)=>[i,{mode:f.mode,ax:f.ax,ay:f.ay,x:f.x,y:f.y,r0x:f.r?f.r[0]:null,r0y:f.r?f.r[1]:0,tug:f.tug}]))}
  Object.assign(W,{mat:g.p,R:g.R,IMP:{tr:g.s.tr,w:g.s.w}});W.MOOD.strain=g.s.strain;W.MOOD.tugS=g.s.tugS;
  W.fingers=new Map(g.fs.map((f,i)=>{const o={mode:f.mode,ax:f.ax,ay:f.ay,x:f.x,y:f.y};if(f.r){o.r0x=f.r[0];o.r0y=f.r[1]}if(f.tug!=null)o.tug=f.tug;return[i,o]}))}
const K=2000000,cov={零:0,中間:0,滿:0,多指:0,沒記r0:0,tug:0,drag0:0,emo關:0,rough關:0,impC3開:0,放鬆比strain多:0};let dT=0,dF=0,nz=0,dz=0;const keep=[];
for(let k=0;k<K;k++){const g=gen();put(g);const a=N.F.tugIn(),b=W.F.tugIn(),c=N.F.dragFollow(),d=W.F.dragFollow();
  dT=Math.max(dT,Math.abs(a-b));dF=Math.max(dF,Math.abs(c-d));if(!Number.isFinite(a+b+c+d))fail++;
  if(g.p.rough<.5){nz++;const o=O.F.dragFollow();if(!Object.is(o,c))dz++}
  const gr=g.fs.filter(f=>f.mode==='grab');cov[b===0?'零':b===1?'滿':'中間']++;if(gr.length>1)cov.多指++;if(gr.length===1&&!gr[0].r)cov.沒記r0++;if(gr.length===1&&gr[0].tug)cov.tug++;if(g.p.drag===0)cov.drag0++;if(g.p.emo<.5)cov.emo關++;if(g.p.rough<.5)cov.rough關++;if(g.p.impC3&&g.p.imp&&g.p.life2)cov.impC3開++;if(g.p.rough>=.5&&g.p.emo>=.5&&(g.s.tugS||0)*b>g.s.strain)cov.放鬆比strain多++;
  if(k<200000)keep.push(g)}
const say=(ok,t)=>{console.log((ok?'一樣 ':'不同 ')+t);if(!ok)fail++};
console.log('走到',JSON.stringify(cov));
say(dT<1e-12,'tugIn Swift 對網頁 '+K+' 格 最大差 '+dT);say(dF<1e-12,'dragFollow Swift 對網頁 '+K+' 格 最大差 '+dF);
say(dz===0&&nz>1e5,'rough 關：現在的 Swift 對動工前的 Swift '+nz+' 格 位元不同 '+dz);
for(const k in cov)if(!cov[k])say(false,'沒走到 '+k);

// ---------- 閉環：每格先 dragFollow（讀上一格的 strain、tugS）再更新心情，拉開量照 slide 公式
function loop(S,isWeb,g,rough,frames,log){const par={drag:.35,imp:1,life2:1,impC3:g.c3,emo:1,rough};if(isWeb){S.mat=par;S.IMP={tr:g.tr,w:g.w};Object.assign(S.MOOD,{strain:0,strainMax:0,tugS:undefined})}else Object.assign(S,{params:par,impTrust:g.tr,impWary:g.w,moodStrain:0,moodStrainMax:0,moodTugS:0});
  S.R=g.R;S.fingers=new Map();const mk=(x,y,r)=>{const f={mode:'grab',ax:x,ay:y,x,y,r0x:r[0],r0y:r[1],yank:g.yank};if(!isWeb)Object.assign(f,{tug:null,strainT:0,tugT:0});return f};
  let f=null,f2=null;for(let i=0;i<frames;i++){const t=i/60;
    if(!f&&t<g.off){f=mk(0,0,g.r);S.fingers.set(1,f)}if(g.two&&!f2&&t>=g.two&&t<g.two+.7){f2=mk(50,20,[10,10]);S.fingers.set(2,f2)}if(f2&&t>=g.two+.7){S.fingers.delete(2);f2=null}
    if(f&&t>=g.off){S.fingers.delete(1);f=null}
    if(f){const l=Math.min(g.L,g.v*t)*g.R;f.x=l*Math.cos(g.b);f.y=l*Math.sin(g.b);if(g.tugAt&&t>=g.tugAt)f.tug=g.tugV}
    const k=S.F.dragFollow();let st=0;if(f){const sl=1.5*g.R,dl=Math.hypot(f.x,f.y);st=sl*Math.tanh((1-k)*dl/sl)/g.R*g.stk}
    S.F.mood(f,st,g.dt);log.push(k,isWeb?S.MOOD.strain:S.moodStrain,isWeb?S.MOOD.tugS||0:S.moodTugS)}}
{let d=0,n=0,act=0,d0=0,wr=0;for(let q=0;q<1000;q++){const a=rr(0,6.28),rl=rr(.1,1.1),R=rr(60,160),g={R,r:[rl*R*Math.cos(a),rl*R*Math.sin(a)],b:a+Math.PI+rr(-1.4,1.4),L:rr(.5,5),v:rr(.5,8),off:rr(2,7),two:rnd()<.3?rr(.5,4):0,tugAt:rnd()<.2?rr(.1,2):0,tugV:rnd()<.5,yank:rnd()<.3,c3:pick([0,1]),tr:rnd(),w:rnd(),dt:pick([1/60,1/120]),stk:rr(1.2,2)};
  for(const rough of[1,0]){const A=[],B=[],C=[];loop(N,false,g,rough,480,A);loop(W,true,g,rough,480,B);if(!rough)loop(O,false,g,rough,480,C);
   for(let i=0;i<A.length;i++){if(!rough&&i%3===2){if(A[i]!==0)wr++;continue}   // rough 關：手機 tugS 固定 0，網頁停在原來的值（沒人讀）
    d=Math.max(d,Math.abs(A[i]-B[i]));if(!rough&&!Object.is(A[i],C[i]))d0++}n+=A.length/3;
   if(rough){const E=[];loop(O,false,g,1,480,E);let m=0;for(let i=0;i<A.length;i+=3)m=Math.max(m,E[i]-A[i]);if(m>.02)act++}}}
 say(d<1e-12,'閉環（跟手、strain、tugS）Swift 對網頁 '+n+' 格 最大差 '+d+'（1000 串裡跟手比動工前少的 '+act+' 串）');say(d0===0&&wr===0,'閉環 rough 關：對動工前的 Swift 位元不同 '+d0+'，tugS 不是 0 的 '+wr)}
{const g={R:108,r:[-.9*108,0],b:Math.PI/6,L:3,v:1.5,off:99,two:0,tugAt:0,yank:false,c3:0,tr:0,w:0,dt:1/60,stk:1.6},last=(S,w,r)=>{const A=[];loop(S,w,g,r,300,A);return A[A.length-3].toFixed(3)};
 console.log('左邊抓、往右下慢拉 3R、按住 3 秒的跟手：Swift rough1',last(N,false,1),'網頁 rough1',last(W,true,1),'Swift rough0',last(N,false,0),'動工前 Swift rough1',last(O,false,1),'（說明檔 .105／.105／.105／.35；拉開量是公式值乘 1.6，只看量級）')}

// ---------- 前後順序、r0x 寫入處（查原文）
const pos=(s,...a)=>a.map(x=>once(s,x));
{const a=pos(swNew,'        gooStep(dt); b2Step(dt)','\n        dragStep(dt)   //','\n        moodStep(dt)'),b=pos(web,'  strandStep(dt);b2Step(dt);fxStep(dt);','\n  dragStep(dt);   //','  moodStep(dt);moodColorStep(dt);');
 say(a[0]<a[1]&&a[1]<a[2]&&b[0]<b[1]&&b[1]<b[2],'一格裡的順序：判 tug、dragStep（讀上一格的 strain、tugS）、moodStep，兩邊同')}
{const r=swNew.split('\n').filter(l=>/f\.r0x = [xf]/.test(l)),w=(web.match(/f\.r0x=(?!=)/g)||[]).length;say(r.length===2&&w===2&&r.every(l=>!/params\./.test(l)),'r0x 寫入處：Swift '+r.length+'、網頁 '+w+'，都不看 A4 開關')}

// ---------- 反證：改壞一個地方要紅
const bad=[['inR: Double = 0.35','inR: Double = 0.351'],['inC: Double = 0.5 }','inC: Double = 0.501 }'],['- RoughSet.inR) / 0.25)','- RoughSet.inR) / 0.26)'],['- RoughSet.inC) / 0.2)','- RoughSet.inC) / 0.21)'],
 ['rl < R * 0.1 || dl < R * 0.1','rl < R * 0.45 || dl < R * 0.1'],['rl < R * 0.1 || dl < R * 0.1','rl < R * 0.1 || dl < R * 0.11'],['guard n == 1, let f = g','guard n >= 1, let f = g'],[', f.tug != true else',', f.tug != false else'],['let inward: Double = -dot','let inward: Double = dot'],['dx * r0x + dy * f.r0y','dx * r0x - dy * f.r0y'],
 ['max(moodStrain, moodTugS * tugIn())','max(moodStrain, moodTugS)'],['max(moodStrain, moodTugS * tugIn())','(moodTugS * tugIn())'],['k *= 1 - 0.7 * ease','k *= 1 - 0.701 * ease'],['params.rough >= 0.5','params.rough > 0.5'],['(x >= 1 ? 1 : x * x * (3 - 2 * x)) }','(x >= 1 ? 1 : x * x * (3 - 2.001 * x)) }']];
let red=0;for(const [a,b] of bad){const i=swNew.indexOf(a);if(i<0)throw Error('反證找不到 '+a);const M=swSide(swNew.slice(0,i)+b+swNew.slice(i+a.length));let d=0;
  for(const g of keep){put(g);Object.assign(M,{params:g.p,R:g.R,impTrust:g.s.tr,impWary:g.s.w,moodStrain:g.s.strain,moodTugS:g.s.tugS||0,fingers:N.fingers});d=Math.max(d,Math.abs(M.F.dragFollow()-W.F.dragFollow()))}
  const ok=d>1e-6;if(ok)red++;else fail++;console.log((ok?'  紅 ':'  沒紅！ ')+a.trim()+' → '+b.trim()+' 最大差 '+d.toExponential(2))}
console.log('反證 '+red+'／'+bad.length+' 紅');
console.log(fail?'有 '+fail+' 項不對':'全部一樣');process.exit(fail?1:0);
