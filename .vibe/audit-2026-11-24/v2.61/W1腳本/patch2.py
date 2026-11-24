P='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/index.html'
s=open(P,encoding='utf-8',newline='').read().replace('\r\n','\n')
a='<script src="desk.js"></script>\n'
assert s.count(a)==1
blk='''<script>
/* v2.61 調節台「這一批」（多米 11-25）。寫在這裡、不動 desk.js：三檔、拉的三顆、五組切換，規格在 .vibe/第一批-合約.md。
   拉的三顆跟著存 1、存 2、存 3 和匯出走（包住 desk.js 的 deskPick、deskApply…），其他開關不進。沒有這三顆的舊存檔當成全關；手感風格只動旋鈕，不動這三顆。
   網址有 ?pull= 時三顆鎖住，這一塊收起來，匯出也不寫，畫面上看不到是哪一邊。 */
'use strict';
const TIER61={b158:['build 158',k=>0],fix:['只修錯',k=>PRESETS.clay[k]],pull:['修錯加拉的三條',k=>PULL3.includes(k)?1:PRESETS.clay[k]]};
const PULLN={pullHold:'A3 停住',pullWhole:'A4 整隻先走',pullSoft:'A5 收回去'};
const GRP61=[['皮',['skinU']],['牠怎麼記你',['rough','tapSoft','petSlow']],['聲音',['snd61']],['眼睛和旁邊',['eyeTrue','nearFast','greetLook']],['睡醒',['wakeSoft']]];
(()=>{
  let saving=false;const d0={pick:deskPick,apply:deskApply,save:deskSave,diff:deskDiff,changed:deskChanged,json:deskJSON,imp:deskImport,text:deskText,sync:deskSync,style:styleSnap};
  const on=v=>+v>=.5?1:0,saved=FEEL61&&FEEL61.v===2&&FEEL61.k?FEEL61.k:{},word=v=>on(v)?'開':'關';
  deskPick=()=>{const o=d0.pick();for(const k of PULL3)o[k]=saving&&PULLQ?on(saved[k]):on(mat[k]);return o};
  deskSave=()=>{saving=true;try{d0.save()}finally{saving=false}};   // 網址鎖住時，台上記的是原本存的，不被網址蓋掉
  deskApply=sn=>{if(sn&&sn.k&&!PULLQ)for(const k of PULL3)mat[k]=on(sn.k[k]);d0.apply(sn)};
  styleSnap=id=>{const s=d0.style(id);if(s)for(const k of PULL3)s.k[k]=on(mat[k]);return s};
  deskDiff=(a,b)=>{const o=d0.diff(a,b);for(const k of PULL3)if(on(a.k[k])!==on(b.k[k]))o.push(PULLN[k]+' '+word(a.k[k])+'／'+word(b.k[k]));return o};
  deskChanged=()=>{const o=d0.changed(),b=DESK.base0;if(b&&!PULLQ)for(const k of PULL3)if(on(b.k[k])!==on(mat[k]))o.push(PULLN[k]+' '+word(b.k[k])+'→'+word(mat[k]));return o};
  deskJSON=()=>{const t=d0.json();if(PULLQ)return t;const o=JSON.parse(t);for(const k of PULL3)o.k[k]=on(mat[k]);o.s.forEach((s,i)=>{if(s)for(const k of PULL3)s.k[k]=on(DESK.slots[i].k[k])});return JSON.stringify(o)};
  deskImport=txt=>{const r=d0.imp(txt),m=/#nienie-feel\s+(\{.*\})\s*$/m.exec(txt||'');if(!m||!r.startsWith('匯入了'))return r;try{const o=JSON.parse(m[1]);[0,1,2].forEach(i=>{const s=(o.s||[])[i];if(s&&s.k&&DESK.slots[i])for(const k of PULL3)DESK.slots[i].k[k]=on(s.k[k])});if(!PULLQ)for(const k of PULL3)mat[k]=on(o.k[k]);deskSync();deskSave()}catch(_){}return r};
  const tierNow=()=>{for(const id in TIER61)if(KEYS61.every(k=>on(mat[k])===on(TIER61[id][1](k))))return id;return null};
  deskText=()=>{const t=d0.text(),id=tierNow(),w='\n這一批（v2.61）：'+(PULLQ?'拉的三條由網址決定':(id?TIER61[id][0]:'自己切的'))+'；關著的：'+(KEYS61.filter(k=>!on(mat[k])&&!(PULLQ&&PULL3.includes(k))).join('、')||'沒有');return t.replace('\n#nienie-feel',w+'\n#nienie-feel')};
  const main=document.getElementById('feel-main'),box=document.createElement('div');box.className='feel-box';box.id='feel-61';
  box.innerHTML='<h4>這一批（v2.61）</h4>'+(PULLQ?'<p class="feel-note">拉的三條由網址決定，這裡先不顯示是哪一邊。</p>':
    '<div class="feel-row"><span>三檔</span>'+Object.keys(TIER61).map(id=>`<button data-61t="${id}">${TIER61[id][0]}</button>`).join('')+'</div>'+
    '<div class="feel-row"><span>拉</span>'+PULL3.map(k=>`<button data-61p="${k}">${PULLN[k]}</button>`).join('')+'<small>停住：拉長停下來，就定在那裡。整隻先走：往身體裡拉，整隻先跟著走再拉長。收回去：拉很長放手，會收回來。這三顆會跟著存檔。</small></div>')+
    '<div class="feel-row"><span>單獨切</span>'+GRP61.map(([n],i)=>`<button data-61g="${i}">${n}</button>`).join('')+'<small>按一下關，再按開。關掉的那組就跟 build 158 一樣。不跟著存檔。</small></div>';
  main.insertBefore(box,document.getElementById('feel-styles'));
  deskSync=()=>{d0.sync();const id=tierNow(),set=(b,v)=>b.setAttribute('aria-pressed',String(v));
    for(const b of box.querySelectorAll('[data-61t]'))set(b,b.getAttribute('data-61t')===id);
    for(const b of box.querySelectorAll('[data-61p]'))set(b,on(mat[b.getAttribute('data-61p')])===1);
    for(const b of box.querySelectorAll('[data-61g]'))set(b,GRP61[+b.getAttribute('data-61g')][1].every(k=>on(mat[k])))};
  const done=t=>{syncSliders();deskSync();deskSave();if(t)deskNote(t)};
  box.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;const a=n=>b.getAttribute(n);
    if(a('data-61t')){const q=TIER61[a('data-61t')];for(const k of KEYS61)mat[k]=q[1](k);done('換到「'+q[0]+'」。')}
    else if(a('data-61p')){const k=a('data-61p');mat[k]=on(mat[k])?0:1;done(PULLN[k]+'：'+word(mat[k])+'。')}
    else if(a('data-61g')!==null){const [n,ks]=GRP61[+a('data-61g')],v=ks.every(k=>on(mat[k]))?0:1;for(const k of ks)mat[k]=v;done(n+'：'+word(v)+'。')}});
  document.getElementById('feel').addEventListener('click',e=>{const b=e.target.closest('button');if(b&&b.id==='feel-def'&&!PULLQ){for(const k of PULL3)mat[k]=0;DESK.base0=deskSnap();done()}});   // 回到預設：存檔裡有的都回預設，拉的三顆也算
  {const v=document.querySelector('#feel .feel-ver');if(v)v.textContent='v2.61'}DESK.build='網頁 v2.61';
  if(!DESK.stale&&!PULLQ)for(const k of PULL3)mat[k]=on(saved[k]);   // 上次留在台上的三顆
  DESK.base0=deskSnap();syncSliders();deskSync();deskSave()})();
</script>
'''
s=s.replace(a,"<script>const FEEL61=(()=>{try{return JSON.parse(localStorage.getItem('nienie.feel')||'null')}catch(_){return null}})();</script>\n"+a+blk)
open(P,'w',encoding='utf-8',newline='').write(s.replace('\n','\r\n'))
print('ok')
