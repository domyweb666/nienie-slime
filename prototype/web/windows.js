/* ---------- 窗景（多米 11-24：只換窗戶外面的景，原本那扇照舊、免費、隨時換回）---------- */
// 圖在 scene/win/*.svg（tools/extract-windows.mjs 從設計畫布抽出來的，座標 680×828，等於 sceneFor 的 gw×gh）。
// 不是每幀重畫整張 SVG：換窗時把圖拆成一疊層，一層一張點陣圖存起來，每幀只貼圖。
//   不動的：貼在同一張底圖上（夜晚的疊色、光暈也先貼好），每幀一次。
//   會動的：照 SMIL 的時間表算位置、角度、透明度，貼那一小塊。整層在窗洞外面的那一幀跳過。
// 這份在主程式之前載入，裡面用到的 W、H、DPR、SCENE、ctx 都是執行的時候才讀。
const WINS=[
  {id:'Shancheng',set:0,name:'山城的燈',line:'飄小雨，晚上燈籠亮起來',day:'rgba(120,140,150,.16)',holes:n=>({red:n?'#FF6B3A':'#C63A31',rib:n?'#FFB46A':'#9C2721'})},
  {id:'Dingceng',set:0,name:'頂樓曬衣',line:'風一吹，衣服晃兩下',day:'rgba(255,140,70,.16)'},
  {id:'Daotian',set:0,name:'田中間的火車',line:'等一下就有一台開過去',day:'',holes:n=>({win:n?'#FFE08A':'#7FB4C8'})},
  {id:'Tiandeng',set:0,name:'放天燈',line:'燈從山谷裡慢慢升上來',only:1},
  {id:'Yinghua',set:1,name:'河邊的櫻',line:'花瓣一直掉，晚上樹下點燈',day:'rgba(255,170,190,.1)'},
  {id:'Haibian',set:1,name:'夏天的海',line:'白天有帆船，晚上放煙火',day:''},
  {id:'Yinxing',set:1,name:'銀杏路',line:'葉子落滿整條路',day:'rgba(255,180,60,.12)'},
  {id:'Xueye',set:1,name:'雪地小屋',line:'煙囪冒著煙，晚上有極光',day:'rgba(130,165,205,.2)',holes:n=>({win:n?'#FFD27C':'#F7D8A0'})},
  {id:'Jingyu',set:2,name:'鯨魚經過',line:'等久一點，牠會游過去',day:'rgba(16,86,130,.42)'},
  {id:'Yueqiu',set:2,name:'月亮上看地球',line:'兔子在旁邊搗麻糬',only:1},
  {id:'Yundao',set:2,name:'雲上的島',line:'風車在轉，熱氣球飄過去',day:''},
  {id:'Baobing',set:2,name:'剉冰山',line:'芋圓、仙草、布丁都在山上',day:'rgba(255,170,190,.1)'}];
const WINSETS=['島上','四季','去不了的地方'];
const WIN={txt:{},cache:new Map(),last:null,set:-1,fixed:null,host:null};
function winDef(id){return id?WINS.find(w=>w.id===id)||null:null}
// 現在畫面上是白天還是夜晚：只有夜晚的那兩扇（放天燈、月亮上看地球）開著時算夜晚；不改你選的背景，換回別扇就回來
function viewBg(){const d=VIEW.bg==='blue'?null:winDef(VIEW.win);return d&&d.only?'night':VIEW.bg}

/* ----- 時間表（SMIL 的 animate／animateTransform） ----- */
function winEase(a){const [x1,y1,x2,y2]=a,f=(u,p,q)=>3*(1-u)*(1-u)*u*p+3*(1-u)*u*u*q+u*u*u;
  return x=>{let lo=0,hi=1;for(let i=0;i<18;i++){const m=(lo+hi)/2;if(f(m,x1,x2)<x)lo=m;else hi=m}return f((lo+hi)/2,y1,y2)}}
function winTrack(e){
  const at=n=>e.getAttribute(n),nums=s=>s.trim().split(/[\s,]+/).map(Number),vals=(at('values')?at('values').split(';'):[at('from'),at('to')]).map(nums),n=vals.length;
  const dur=parseFloat(at('dur')),beg=parseFloat(at('begin')||'0'),keys=at('keyTimes')?at('keyTimes').split(';').map(Number):vals.map((_,i)=>i/(n-1));
  const ez=at('calcMode')==='spline'?at('keySplines').split(';').map(s=>winEase(nums(s))):null;
  const run=T=>{let p=(T-beg)/dur;p-=Math.floor(p);let i=0;while(i<n-2&&p>=keys[i+1])i++;
    const d=keys[i+1]-keys[i];let u=d>0?Math.min(1,Math.max(0,(p-keys[i])/d)):1;if(ez)u=ez[i](u);
    const a=vals[i],b=vals[i+1],o=[];for(let k=0;k<Math.max(a.length,b.length);k++){const p0=a[k]||0,p1=b[k]||0;o.push(p0+(p1-p0)*u)}return o};
  run.raw={d:dur,b:beg,k:keys,v:vals,e:at('calcMode')==='spline'?at('keySplines').split(';').map(nums):null};return run}   // raw：時間表原本的數字，只給 tools/export-windows-ios.py 輸出 iOS 用，網頁不讀
// 矩陣用六個數字的陣列（每幀要乘幾十次，不產生 DOMMatrix）
function winMul(m,n){return[m[0]*n[0]+m[2]*n[1],m[1]*n[0]+m[3]*n[1],m[0]*n[2]+m[2]*n[3],m[1]*n[2]+m[3]*n[3],m[0]*n[4]+m[2]*n[5]+m[4],m[1]*n[4]+m[3]*n[5]+m[5]]}
function winMat(type,v){
  if(type==='translate')return[1,0,0,1,v[0],v[1]||0];
  if(type==='scale')return[v[0],0,0,v[1]==null?v[0]:v[1],0,0];
  if(type==='skewX')return[1,0,Math.tan(v[0]*Math.PI/180),1,0,0];
  const a=v[0]*Math.PI/180,c=Math.cos(a),s=Math.sin(a),x=v[1]||0,y=v[2]||0;return[c,s,-s,c,x-c*x+s*y,y-s*x-c*y]}   // rotate
function winStatic(s){let m=[1,0,0,1,0,0];for(const q of (s||'').matchAll(/(\w+)\(([^)]*)\)/g))m=winMul(m,winMat(q[1],q[2].trim().split(/[\s,]+/).map(Number)));return m}

/* ----- 拆層 ----- */
const winIsAnim=e=>e.nodeName==='animate'||e.nodeName==='animateTransform';
const winSt=(e,k)=>{const m=new RegExp('(?:^|;)\\s*'+k+'\\s*:\\s*([^;]+)').exec(e.getAttribute('style')||'');return m?m[1].trim():''};
// 一層：{nodes 要畫的東西, wrap 外面幾層 <g> 的顏色線條設定, ops 位移旋轉（固定的或會動的）, al 透明度, op 疊色方式, clip 裁切圓, tint 夜晚整張疊色}
function winFlat(svg){
  const out=[];let uid=0;
  const emit=(node,st)=>{const l=out[out.length-1];if(l&&l.key===st.key&&!l.shut&&!l.dash)l.nodes.push(node);else out.push({...st,nodes:[node],tint:[]})};
  const walk=(e,st)=>{
    if(e.nodeType!==1||['defs','title','desc'].includes(e.nodeName)||winIsAnim(e)||winSt(e,'opacity')==='0')return;
    const kids=[...e.children],an=kids.filter(winIsAnim),blend=winSt(e,'mix-blend-mode'),deep=e.querySelector('animate,animateTransform')||e.querySelector('[style*="mix-blend"]');
    if(!an.length&&!blend&&!deep){emit(e,st);return}
    // 整張疊色：等於把底下每一層的顏色先乘好（乘一個固定顏色，先乘再疊跟先疊再乘一樣）
    if(blend==='multiply'&&e.nodeName==='rect'&&!an.length&&!st.ops.length&&+e.getAttribute('width')===680&&+e.getAttribute('height')===828&&!e.getAttribute('x')&&!e.getAttribute('y')){
      for(const l of out){l.tint.push(e.getAttribute('fill'));l.shut=true}return}
    const s={...st,ops:[...st.ops],al:[...st.al],wrap:[...st.wrap]};let own=false;
    const tr=an.filter(a=>a.nodeName==='animateTransform'),by=n=>an.find(a=>a.getAttribute('attributeName')===n),oa=by('opacity'),da=by('stroke-dashoffset');
    if(tr.length){own=true;for(const a of tr){const ty=a.getAttribute('type'),f=winTrack(a),vs=(a.getAttribute('values')||'').split(';').map(Number);s.ops.push({ty,tk:f.raw,fn:T=>winMat(ty,f(T)),max:ty==='scale'?Math.max(...vs):1})}}
    else if(e.hasAttribute('transform')){own=true;const m=winStatic(e.getAttribute('transform'));s.ops.push({m,max:Math.hypot(m[0],m[1])})}
    if(oa){own=true;const f=winTrack(oa);s.al.push({tk:f.raw,fn:T=>f(T)[0]})}
    else{const o=e.getAttribute('opacity')||winSt(e,'opacity');if(o&&+o!==1){own=true;s.al.push({v:+o})}}
    if(blend){own=true;s.op=blend==='plus-lighter'?'lighter':blend}
    const cp=/url\(#(\w+)\)/.exec(e.getAttribute('clip-path')||'');
    if(cp){own=true;const c=svg.querySelector('#'+cp[1]+' circle');s.clip={n:s.ops.length,x:+c.getAttribute('cx'),y:+c.getAttribute('cy'),r:+c.getAttribute('r')}}
    if(own)s.key='k'+(++uid);
    if(e.nodeName!=='g'){const c=e.cloneNode(true);for(const k of [...c.children])k.remove();for(const k of ['transform','opacity','style','clip-path'])c.removeAttribute(k);if(da){const f=winTrack(da);s.dash=T=>f(T)[0];s.dash.tk=f.raw}emit(c,s);return}
    const pa=[...e.attributes].filter(a=>!['transform','opacity','style','clip-path'].includes(a.name));
    if(pa.length){if(!own)s.key='k'+(++uid);s.wrap.push(pa.map(a=>`${a.name}="${a.value}"`).join(' '))}
    for(const k of kids)walk(k,s)};
  for(const k of svg.children)walk(k,{ops:[],al:[],wrap:[],op:'',clip:null,key:'root',dash:null});
  return out}
function winTint(s,list){
  if(!list.length)return s;let m=[1,1,1];for(const h of list){const v=parseInt(h.slice(1),16);m=[m[0]*(v>>16)/255,m[1]*(v>>8&255)/255,m[2]*(v&255)/255]}
  return s.replace(/(fill|stroke|stop-color)="#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?"/g,(_,k,h,a)=>{const v=parseInt(h,16),q=[v>>16,v>>8&255,v&255].map((c,i)=>Math.round(c*m[i]).toString(16).padStart(2,'0')).join('');return `${k}="#${q}${a||''}"`})}

/* ----- 一層存成一張圖 ----- */
function winBox(inner,defs){
  if(!WIN.host){const h=document.createElement('div');h.setAttribute('aria-hidden','true');h.style.cssText='position:fixed;left:-9999px;top:0;width:680px;height:828px;visibility:hidden;pointer-events:none';document.body.appendChild(h);WIN.host=h}
  WIN.host.innerHTML=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 828" width="680" height="828"><defs>${defs}</defs><g>${inner}</g></svg>`;
  const b=WIN.host.querySelector('svg>g').getBBox();WIN.host.innerHTML='';return b}
async function winImg(inner,defs,vb,pw,ph){
  const im=new Image();im.width=pw;im.height=ph;
  im.src='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb.join(' ')}" width="${pw}" height="${ph}" preserveAspectRatio="none"><defs>${defs}</defs>${inner}</svg>`);
  await new Promise((ok,no)=>{im.onload=ok;im.onerror=()=>no(new Error('svg'))});
  const c=document.createElement('canvas');c.width=pw;c.height=ph;c.getContext('2d').drawImage(im,0,0,pw,ph);return c}
async function winText(id){if(!WIN.txt[id]){const r=await fetch('scene/win/'+id+'.svg');if(!r.ok)throw new Error(id+' '+r.status);WIN.txt[id]=await r.text()}return WIN.txt[id]}
async function winCompile(d,kind,g){
  const n=kind==='night'?1:0,h={n,d:1-n,...(d.holes?d.holes(n):{})},txt=(await winText(d.id)).replace(/\{\{(\w+)\}\}/g,(_,k)=>h[k]);
  const svg=new DOMParser().parseFromString(txt,'image/svg+xml').documentElement;if(svg.nodeName!=='svg')throw new Error(d.id+' parse');
  const ser=new XMLSerializer(),dn=svg.querySelector('defs'),defs0=dn?[...dn.children].map(e=>ser.serializeToString(e)).join(''):'',s=g.s,out=[];
  const X0=Math.floor(g.gx),Y0=Math.floor(g.gy),X1=Math.ceil(g.gx+g.gw),Y1=Math.ceil(g.gy+g.gh);
  for(const it of winFlat(svg)){
    const inner=winTint(it.wrap.map(a=>`<g ${a}>`).join('')+it.nodes.map(e=>ser.serializeToString(e)).join('')+it.wrap.map(()=>'</g>').join(''),it.tint),defs=winTint(defs0,it.tint);
    const L={ops:it.ops,al:it.al,op:it.op||'source-over',clip:it.clip,dash:it.dash};
    if(it.dash){const e=it.nodes[0],at=k=>e.getAttribute(k);   // 瀑布的虛線：三條直線，每幀直接描
      L.pd=at('d');L.path=new Path2D(L.pd);L.stroke=/stroke="([^"]+)"/.exec(inner)[1];L.lw=+at('stroke-width');L.cap=at('stroke-linecap')||'butt';L.pat=at('stroke-dasharray').split(/[\s,]+/).map(Number);out.push(L);continue}
    const bb=winBox(inner,defs),sw=Math.max(0,...[...inner.matchAll(/stroke-width="([\d.]+)"/g)].map(m=>+m[1]),/<use/.test(inner)?9:0),pad=sw*.75+1.5,b={x:bb.x-pad,y:bb.y-pad,w:bb.width+pad*2,h:bb.height+pad*2};
    if(!it.ops.some(o=>o.fn)&&!it.clip){   // 位置固定：對齊像素，裁到窗洞，每幀直接貼
      let M=[s,0,0,s,g.gx,g.gy];for(const o of it.ops)M=winMul(M,o.m);
      const p=[[b.x,b.y],[b.x+b.w,b.y],[b.x,b.y+b.h],[b.x+b.w,b.y+b.h]],px=p.map(([x,y])=>M[0]*x+M[2]*y+M[4]),py=p.map(([x,y])=>M[1]*x+M[3]*y+M[5]);
      const x0=Math.max(X0,Math.floor(Math.min(...px))),y0=Math.max(Y0,Math.floor(Math.min(...py))),x1=Math.min(X1,Math.ceil(Math.max(...px))),y1=Math.min(Y1,Math.ceil(Math.max(...py)));if(x1<=x0||y1<=y0)continue;
      const c=await winImg(`<g transform="matrix(${M.join(' ')})">${inner}</g>`,defs,[x0,y0,x1-x0,y1-y0],x1-x0,y1-y0);
      const still=!it.al.some(a=>a.fn),fade=still?it.al.reduce((a,q)=>a*q.v,1):1,pv=out[out.length-1];
      if(still&&pv&&pv.flat&&(pv===out[0]||L.op==='source-over')){   // 前一層也不動：直接貼上去，少一層
        const nx=Math.min(pv.x,x0),ny=Math.min(pv.y,y0),nX=Math.max(pv.x+pv.c.width,x1),nY=Math.max(pv.y+pv.c.height,y1);
        if(nX-nx!==pv.c.width||nY-ny!==pv.c.height){const k=document.createElement('canvas');k.width=nX-nx;k.height=nY-ny;k.getContext('2d').drawImage(pv.c,pv.x-nx,pv.y-ny);pv.c=k;pv.x=nx;pv.y=ny}
        const q=pv.c.getContext('2d');q.globalAlpha=fade;q.globalCompositeOperation=L.op;q.drawImage(c,x0-pv.x,y0-pv.y);q.globalAlpha=1;q.globalCompositeOperation='source-over';continue}
      if(fade!==1){const q=c.getContext('2d');q.globalCompositeOperation='destination-in';q.globalAlpha=fade;q.fillRect(0,0,c.width,c.height);q.globalAlpha=1;q.globalCompositeOperation='source-over'}
      if(still)L.al=[];
      out.push({...L,c,x:x0,y:y0,px:true,flat:still&&L.op==='source-over'});continue}
    const rs=s*it.ops.reduce((a,o)=>a*(o.max||1),1),pw=Math.max(1,Math.ceil(b.w*rs)),ph=Math.max(1,Math.ceil(b.h*rs)),bw=pw/rs,bh=ph/rs;
    out.push({...L,c:await winImg(inner,defs,[b.x,b.y,bw,bh],pw,ph),bx:b.x,by:b.y,bw,bh})}
  for(const l of out)if(l.c)l.c.getContext('2d').getImageData(0,0,1,1);   // 哪一層被瀏覽器標成「外來的」就在這裡丟錯，不要等到身體折射那一步才壞
  return{id:d.id,kind,g,items:out,X0,Y0,X1,Y1}}

/* ----- 換窗：還沒準備好就先畫上一扇（第一次就先畫原本那扇），準備好了下一幀換過去 ----- */
function winScene(d,kind){
  const geo=W+'|'+H+'|'+DPR,key=d.id+'|'+kind+'|'+geo;let e=WIN.cache.get(key);
  if(!e){e={st:'wait',geo};WIN.cache.set(key,e);const g=sceneGeo();
    winCompile(d,kind,g).then(v=>{e.win=v;e.wall=sceneRoom(g,kind==='night'?'rgba(38,42,92,.62)':d.day);e.st='ok'}).catch(er=>{e.st='fail';console.warn('[windows] reason:',er&&er.message||er);hint('這扇窗沒載進來，先放原本那扇')})}
  if(e.st==='ok'){WIN.cache.delete(key);WIN.cache.set(key,e);WIN.last=e;   // 最多留三張：這扇的白天夜晚、上一扇
    while(WIN.cache.size>3){const k=WIN.cache.keys().next().value;if(k===key)break;WIN.cache.delete(k)}return e}
  return e.st==='wait'&&WIN.last&&WIN.last.geo===geo?WIN.last:null}
function winNow(){return WIN.fixed!=null?WIN.fixed:REDUCED?0:performance.now()/1000}   // 減少動態：停在第 0 秒那一格
function winDraw(v){
  const T=winNow(),g=v.g;ctx.save();
  for(const L of v.items){
    let a=1;for(const q of L.al)a*=q.fn?q.fn(T):q.v;if(a<.004)continue;ctx.globalAlpha=Math.min(1,a);ctx.globalCompositeOperation=L.op;
    if(L.px){ctx.setTransform(1,0,0,1,0,0);ctx.drawImage(L.c,L.x,L.y);continue}
    let m=[g.s,0,0,g.s,g.gx,g.gy],mc=null;for(let i=0;i<=L.ops.length;i++){if(L.clip&&L.clip.n===i)mc=m;if(i<L.ops.length)m=winMul(m,L.ops[i].fn?L.ops[i].fn(T):L.ops[i].m)}
    if(L.path){ctx.save();ctx.setTransform(...m);ctx.strokeStyle=L.stroke;ctx.lineWidth=L.lw;ctx.lineCap=L.cap;ctx.setLineDash(L.pat);ctx.lineDashOffset=L.dash(T);ctx.stroke(L.path);ctx.restore();continue}
    if(mc){ctx.save();ctx.setTransform(...mc);ctx.beginPath();ctx.arc(L.clip.x,L.clip.y,L.clip.r,0,Math.PI*2);ctx.clip()}
    if(m[1]===0&&m[2]===0){   // 沒有轉：只貼窗洞裡看得到的那一塊
      const X=m[0]*L.bx+m[4],Y=m[3]*L.by+m[5],sx=m[0]*L.bw/L.c.width,sy=m[3]*L.bh/L.c.height,x0=Math.max(X,v.X0),y0=Math.max(Y,v.Y0),x1=Math.min(X+sx*L.c.width,v.X1),y1=Math.min(Y+sy*L.c.height,v.Y1);
      if(x1>x0&&y1>y0&&sx>0&&sy>0){const u0=Math.max(0,Math.floor((x0-X)/sx)),v0=Math.max(0,Math.floor((y0-Y)/sy)),u1=Math.min(L.c.width,Math.ceil((x1-X)/sx)),v1=Math.min(L.c.height,Math.ceil((y1-Y)/sy));
        ctx.setTransform(1,0,0,1,0,0);ctx.drawImage(L.c,u0,v0,u1-u0,v1-v0,X+u0*sx,Y+v0*sy,(u1-u0)*sx,(v1-v0)*sy)}}
    else{const mx=L.bx+L.bw/2,my=L.by+L.bh/2,w=Math.abs(m[0])*L.bw+Math.abs(m[2])*L.bh,hh=Math.abs(m[1])*L.bw+Math.abs(m[3])*L.bh,cx=m[0]*mx+m[2]*my+m[4],cy=m[1]*mx+m[3]*my+m[5];
      if(cx+w/2>v.X0&&cx-w/2<v.X1&&cy+hh/2>v.Y0&&cy-hh/2<v.Y1){ctx.setTransform(...m);ctx.drawImage(L.c,L.bx,L.by,L.bw,L.bh)}}
    if(mc)ctx.restore()}
  ctx.restore()}

/* ----- 切換列：原本／三套，點一套展開那四扇 ----- */
function winUi(){
  const a=document.getElementById('v-wset'),b=document.getElementById('v-wins');if(!a||!b)return;const cur=winDef(VIEW.win),open=WIN.set;
  a.innerHTML=`<button data-w="" aria-pressed="${!cur}">原本</button>`+WINSETS.map((s,i)=>`<button data-ws="${i}" aria-expanded="${open===i}" aria-pressed="${!!cur&&cur.set===i}">${s}</button>`).join('');
  b.parentElement.style.display=open<0?'none':'';document.getElementById('view').classList.toggle('wopen',open>=0);b.innerHTML=open<0?'':WINS.filter(w=>w.set===open).map(w=>`<button data-w="${w.id}" aria-pressed="${!!cur&&cur.id===w.id}">${w.name}</button>`).join('')}
function winPick(id){const d=winDef(id),o={win:d?d.id:''};if(d&&VIEW.bg==='blue')o.bg='day';viewSet(o);if(d)hint(d.name+'：'+d.line+(d.only?'（只有夜晚）':''))}
document.getElementById('view').addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;
  if(b.dataset.ws!=null){const i=+b.dataset.ws;WIN.set=WIN.set===i?-1:i;winUi()}
  else if(b.dataset.w!=null)winPick(b.dataset.w);
  else if(b.dataset.v==='day'&&winDef(VIEW.win)&&winDef(VIEW.win).only)hint('這扇窗只有夜晚')});
