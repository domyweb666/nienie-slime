/* 捏捏史萊姆 手感調節台 v1（v2.52，多米 11-22 的交辦 B 組）。照《虛擬手感》3-4 第十一節的規格：
   7 條主旋鈕（一個底層詞一條）＋「更多」裡的副旋鈕；3 格存檔，換的時候不加任何動作；盲比（隨機叫 1 號、2 號，選完才揭曉，自動記一行）；
   存檔記預設版本，預設改了會問；匯出的字貼回來能原樣重現；量測一組（灰盒、純圓、圖層、讀數）。
   在 index.html 的主程式之後載入，用的是主程式的 mat、PRESETS、setMat、effNote、LAB、GRD、PHYS。手機版同一份規格在 ios/NieNie/UI/FeelDesk.swift，
   名字、範圍、匯出的格式兩邊要一樣（改一邊就改另一邊）。網頁沒有觸覺、只有約 60 fps，這裡調出來的數字只算起點（3-4 跳過條件）。 */
const FEELVER='v2.53';   // 預設版本的名字：三種材料的旋鈕預設值有改就換；另外有一個從預設值算出來的指紋（deskStamp），忘了換名字也認得出來
// key、名字（底層詞）、參照點（怎麼捏來試）、最小、最大、一格、哪一組
const KNOBS=[
  ['alpha','軟','按三秒，看周圍跟著塌多少。越右越硬',.05,.8,.01,'捏下去'],
  ['lag','黏滯（慢一拍）','慢拖一次、快拖一次，看被抓的那塊差多少',0,.3,.01,'捏下去'],
  ['creep','留形','拉長放開，看形狀留多少。0 完全不留',0,6,.1,'捏完'],
  ['recover','回原形','放著不碰，看多久退一半。越左越久',0,1.5,.01,'捏完'],
  ['inertiaZ','彈：晃幾下','戳一下放開，數晃幾下才停。越左晃越多下',.05,1,.01,'放手'],
  ['inertiaHz','彈：晃多快','同一個手勢，看第一下多快（每秒幾下）',0,6,.1,'放手'],
  ['maxPull','韌','慢慢拉，看身體本身拉到多長（幾個半徑）',.6,10,.1,'拉']];
const MORE=[
  ['pressSink','按下去沉多久','手指按著不動，凹下去要幾秒',.05,2,.05],
  ['yield','多用力才留形','越左輕輕捏就留下形狀，越右要捏很大力',.02,1.5,.01],
  ['slide','拉多長整隻跟著走','拉長到這個長度（幾個半徑），再拉整隻被拖著走',0,3,.1],
  ['stick','黏手','慢慢抬手時，那塊多黏幾秒才放（候選 26 是 0.1）；0 關',0,.2,.02],
  ['flow','流','放著不碰，每秒往下塌掉高度的幾成；0 不塌',0,.5,.01]];
const DKEYS=[...KNOBS,...MORE].map(r=>r[0]).concat(['strand']);   // 一份存檔記這 13 個數字；黏條（strand）是開關，一起記才比得出「黏條」對「身體自己拉到 7」
const DNAME=Object.fromEntries([...KNOBS,...MORE].map(r=>[r[0],r[1]]));DNAME.strand='黏條';
const MATN={clay:'黏土',mochi:'麻糬',jelly:'果凍'};
const DESK={slots:[null,null,null],log:[],base0:null,pv:FEELVER,ps:'',stale:null,blind:null,fsl:{},build:'網頁 '+FEELVER};

const dfmt=v=>String(+(+v).toFixed(3));
// 旋鈕旁邊的換算：軟是每 1/240 秒拉回幾成，換成時間常數；回原形、流換成「一半要幾秒」
function deskUnit(k,v){v=+v;
  if(k==='alpha')return v>0&&v<1?'約 '+Math.round(1000/240/-Math.log(1-v))+' 毫秒':'';
  if(k==='lag')return Math.round(v*1000)+' 毫秒';
  if(k==='recover')return v>0?'退一半約 '+dfmt((Math.LN2/v).toFixed(v>.35?1:0))+' 秒':'不會退';
  if(k==='flow')return v>0?'約 '+dfmt((Math.LN2/v).toFixed(v>.35?1:0))+' 秒塌一半':'不塌';
  if(k==='stick')return v>0?Math.round(v*1000)+' 毫秒':'關';
  return ''}
// 三種材料這 13 個預設值的指紋（FNV-1a）：預設改了，舊存檔認得出來
function deskStamp(){let s='';for(const m of ['clay','mochi','jelly'])for(const k of DKEYS)s+=dfmt(PRESETS[m][k])+',';
  let h=0x811c9dc5;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,0x01000193)>>>0}return ('00000000'+h.toString(16)).slice(-8).slice(0,6)}
function deskPick(){const o={};for(const k of DKEYS)o[k]=+dfmt(mat[k]);return o}
function deskSnap(){return {base:curMat,pv:FEELVER,ps:deskStamp(),k:deskPick()}}
function deskSave(){try{localStorage.setItem('nienie.feel',JSON.stringify({v:2,pv:DESK.pv,ps:DESK.ps,base:curMat,k:deskPick(),s:DESK.slots,log:DESK.log.slice(-60)}))}catch(_){}}
// 套一份存檔：先換到它的材料，再蓋上 13 個數字。不彈、不出聲、不動牠（3-4：換的時候加的任何動作都會蓋在要比的東西上）
function deskApply(sn){if(!sn||!sn.k)return;if(sn.base&&sn.base!==curMat&&PRESETS[sn.base])setMat(sn.base);
  for(const k of DKEYS)if(typeof sn.k[k]==='number'&&isFinite(sn.k[k]))mat[k]=sn.k[k];deskSync();deskSave()}
function deskNote(t){const e=$('feel-note');if(e)e.textContent=t}
function deskChanged(){const o=[],b=DESK.base0;if(!b)return o;const now=deskPick();for(const k of DKEYS)if(dfmt(b.k[k])!==dfmt(now[k]))o.push(DNAME[k]+' '+dfmt(b.k[k])+'→'+dfmt(now[k]));
  if(b.base!==curMat)o.unshift('材料 '+MATN[b.base]+'→'+MATN[curMat]);return o}
function deskDiff(a,b){const o=[];if(a.base!==b.base)o.push('材料 '+MATN[a.base]+'／'+MATN[b.base]);for(const k of DKEYS)if(dfmt(a.k[k])!==dfmt(b.k[k]))o.push(DNAME[k]+' '+dfmt(a.k[k])+'／'+dfmt(b.k[k]));return o}

// ---- 匯出與匯入（3-4 第 6 欄：貼回去能原樣重現）。最後一行 #nienie-feel 是給程式讀的，上面幾行給人看 ----
function deskJSON(){const kj=k=>'{'+DKEYS.map(x=>'"'+x+'":'+dfmt(k[x])).join(',')+'}',sj=s=>s?'{"base":"'+s.base+'","pv":"'+(s.pv||'')+'","ps":"'+(s.ps||'')+'","k":'+kj(s.k)+'}':'null';
  return '{"v":2,"pv":"'+FEELVER+'","ps":"'+deskStamp()+'","base":"'+curMat+'","k":'+kj(deskPick())+',"s":['+DESK.slots.map(sj).join(',')+']}'}
function deskEnv(){const hz=typeof fpsNow==='number'&&fpsNow>0?Math.round(fpsNow):60;return '捏捏手感 v2｜build '+DESK.build+'｜預設 '+FEELVER+'·'+deskStamp()+'｜'+(/iPhone|iPad/.test(navigator.userAgent)?'iPhone Safari':'瀏覽器')+'｜'+hz+' Hz｜低電量 不明'}
function deskLine(sn){const p=k=>{const u=k==='maxPull'?(sn===deskLive&&effNote('maxPull')?'實際 '+dfmt(effPull()):''):k==='strand'?'':deskUnit(k,sn.k[k]);return DNAME[k]+' '+(k==='strand'?(sn.k[k]>=.5?'開':'關'):dfmt(sn.k[k]))+(u?'（'+u+'）':'')};
  return [KNOBS.map(r=>p(r[0])).join('、'),MORE.map(r=>p(r[0])).concat([p('strand')]).join('、')]}
let deskLive=null;
function deskText(){deskLive={base:curMat,k:deskPick()};const [a,b]=deskLine(deskLive);
  let t=deskEnv()+'\n材料：'+MATN[curMat]+'起點（'+SLIMES[SLIME].name+'）\n旋鈕：'+a+'\n更多：'+b;
  DESK.slots.forEach((s,i)=>{if(!s)return;const d=[];for(const k of DKEYS)if(dfmt(s.k[k])!==dfmt(PRESETS[s.base][k]))d.push(DNAME[k]+' '+dfmt(s.k[k]));
    t+='\n存檔 '+(i+1)+'（'+MATN[s.base]+'，預設 '+(s.pv||'?')+'）：'+(d.length?'跟'+MATN[s.base]+'預設不同的：'+d.join('、'):'跟預設一樣')});
  const ch=deskChanged();t+='\n這次動過：'+(ch.length?ch.join('、'):'沒有');
  for(const l of DESK.log.slice(-60))t+='\n'+l;   // 盲比紀錄全部帶上（最多留 60 行）：多米一組比十次，只帶最近 5 行會漏
  deskLive=null;return t+'\n#nienie-feel '+deskJSON()}
function deskImport(txt){const m=/#nienie-feel\s+(\{.*\})\s*$/m.exec(txt||'');if(!m)return '找不到 #nienie-feel 那一行。要貼的是「複製數值給 Agent」複製出來的整段字。';
  let o;try{o=JSON.parse(m[1])}catch(_){return '那一行讀不出來，可能被截斷了。'}
  if(!o||o.v!==2||!o.k||!PRESETS[o.base])return '格式不對（要 v2）。';
  const ok=s=>s&&PRESETS[s.base]&&s.k?{base:s.base,pv:s.pv||'',ps:s.ps||'',k:Object.fromEntries(DKEYS.map(k=>[k,typeof s.k[k]==='number'&&isFinite(s.k[k])?s.k[k]:PRESETS[s.base][k]]))}:null;
  DESK.slots=[0,1,2].map(i=>ok((o.s||[])[i]));deskApply(ok(o));
  return (o.ps&&o.ps!==deskStamp()?'匯入了。注意：這段字是在預設 '+(o.pv||'?')+' 上調的，現在的預設是 '+FEELVER+'。':'匯入了，數字跟那段字一樣。')}

// ---- 盲比（3-4 鏈四：知道哪個是新的就會偏）。兩格存檔隨機叫成 1 號、2 號，先給哪個也隨機；捏的時候看不到數字，選完才揭曉 ----
function blindStart(a,b){if(!DESK.slots[a]||!DESK.slots[b])return;const sw=Math.random()<.5,first=Math.random()<.5?0:1;
  DESK.blind={pair:[a,b],map:sw?[b,a]:[a,b],first,cur:first,n:0,t0:performance.now(),keep:deskSnap()};deskApply(DESK.slots[DESK.blind.map[first]]);deskSync();
  deskNote('盲比開始。先摸的是 '+(first+1)+' 號。用同一個手勢各捏幾下，幾秒內換過去再捏；選完才會告訴你哪個是哪個。')}
function blindShow(n){const B=DESK.blind;if(!B||B.cur===n)return;B.cur=n;B.n++;deskApply(DESK.slots[B.map[n]]);deskSync()}
function blindEnd(choice){const B=DESK.blind;if(!B)return;DESK.blind=null;
  if(choice==='cancel'){deskApply(B.keep);deskSync();deskNote('盲比取消，回到剛剛的數字。這次不記。');return}
  const q=($('feel-bq')&&$('feel-bq').value||'').trim(),sec=Math.round((performance.now()-B.t0)/1000),d=new Date(),p2=x=>('0'+x).slice(-2),A=DESK.slots[B.pair[0]],C=DESK.slots[B.pair[1]];
  const pick=choice==='same'?'分不出來':'選 '+(choice+1)+' 號＝存檔 '+(B.map[choice]+1);
  const line='盲比 '+p2(d.getMonth()+1)+'-'+p2(d.getDate())+' '+p2(d.getHours())+':'+p2(d.getMinutes())+'｜'+MATN[A.base]+'｜存檔 '+(B.pair[0]+1)+' 對 '+(B.pair[1]+1)+'｜差在：'+(deskDiff(A,C).join('、')||'沒有差')+'｜先摸 '+(B.first+1)+' 號｜換了 '+B.n+' 次、'+sec+' 秒｜'+pick+(q?'｜題目：'+q:'');
  DESK.log.push(line);if(typeof choice==='number')deskApply(DESK.slots[B.map[choice]]);else deskApply(B.keep);deskSync();
  deskNote('揭曉：1 號是存檔 '+(B.map[0]+1)+'，2 號是存檔 '+(B.map[1]+1)+'。'+(choice==='same'?'你說分不出來。':'你選的是存檔 '+(B.map[choice]+1)+'，現在用的就是它。')+'已經記一行，複製數值時會帶上。')}

// ---- 畫面 ----
function deskRow(host,row,more){const [key,name,hint,min,max,step]=row,lab=document.createElement('label');
  lab.innerHTML=`<span>${name}<s>${key}</s></span><output></output><small>${hint}</small><input type="range" min="${min}" max="${max}" step="${step}" aria-label="${name}"><em></em><i>黏土 ${dfmt(PRESETS.clay[key])}・麻糬 ${dfmt(PRESETS.mochi[key])}・果凍 ${dfmt(PRESETS.jelly[key])}</i>`;
  const inp=lab.querySelector('input'),out=lab.querySelector('output'),em=lab.querySelector('em');
  inp.addEventListener('input',()=>{mat[key]=parseFloat(inp.value);deskSync();if(typeof syncSliders==='function')syncSliders();deskSave()});
  host.appendChild(lab);DESK.fsl[key]={inp,out,em}}
function deskSync(){const B=DESK.blind,F2=DESK.fsl;
  for(const k in F2){F2[k].inp.value=mat[k];const u=deskUnit(k,mat[k]);F2[k].out.textContent=dfmt(mat[k])+(u?'｜'+u:'');F2[k].em.textContent=effNote(k)||''}
  const root=$('feel');if(!root||!root.firstChild)return;
  for(const b of root.querySelectorAll('[data-m]'))b.setAttribute('aria-pressed',String(b.getAttribute('data-m')===curMat));
  for(const b of root.querySelectorAll('[data-go]'))b.disabled=!DESK.slots[+b.getAttribute('data-go')];
  for(const b of root.querySelectorAll('[data-blind]')){const [x,y]=b.getAttribute('data-blind').split(',').map(Number);b.disabled=!(DESK.slots[x]&&DESK.slots[y])}
  const st=$('feel-strand');if(st){st.setAttribute('aria-pressed',String(mat.strand>=.5));st.textContent=mat.strand>=.5?'黏條 開':'黏條 關'}
  $('feel-main').hidden=!!B;$('feel-blind').hidden=!B;$('feel-io').hidden=!!B;if(B)$('feel-out').hidden=true;   // 盲比中連複製也收起來：複製出來的字會寫出現在是哪一組
  if(B)for(const b of root.querySelectorAll('[data-bs]'))b.setAttribute('aria-pressed',String(+b.getAttribute('data-bs')===B.cur));
  $('feel-prompt').hidden=!DESK.stale;if(DESK.stale)$('feel-prompt-t').textContent='預設已更新：你存的數字是在「'+DESK.stale+'」上調的，現在的預設是 '+FEELVER+'。';
  const g=$('lab-grey'),c=$('lab-circle');if(g)g.setAttribute('aria-pressed',String(LAB.grey));if(c)c.setAttribute('aria-pressed',String(LAB.circle));
  for(const b of root.querySelectorAll('[data-layer]')){const k=b.getAttribute('data-layer'),dead=(k==='hi'&&!(mat.shine>0))||(k==='wet'&&!(mat.shine>0&&mat.wet>=.5))||(k==='caustic'&&!(mat.caustic>0))||(k==='bubbles'&&!(mat.bubbles>0))||(k==='refr'&&!(mat.water>0))||(k==='dent'&&!(mat.dent>=.5))||(k==='mood'&&!(mat.moodColor>0))||(k==='round'&&!(mat.round>0));
    b.setAttribute('aria-pressed',String(!LAB.off[k]&&!dead));b.disabled=dead;b.title=dead?'這一層現在的參數是 0，本來就沒畫':''}}
function deskBuild(){const root=$('feel');if(!root)return;
  root.innerHTML=`<div class="feel-head"><b>手感調節台</b><span class="feel-ver">預設 ${FEELVER}</span><button id="feel-close">收起</button></div>
  <div class="feel-row" id="feel-prompt" hidden><span id="feel-prompt-t"></span><button id="feel-usenew">用新預設</button><button id="feel-keep">留著我的</button></div>
  <div id="feel-main" class="feel-box">
    <div class="feel-row"><span>從哪個材質開始</span><button data-m="clay">黏土</button><button data-m="mochi">麻糬</button><button data-m="jelly">果凍</button></div>
    <div id="feel-sliders"></div>
    <div class="feel-row"><span>韌的另一半</span><button id="feel-strand"></button><small>開：身體只拉到穩定的長度，再遠是黏條。關：身體自己拉到「韌」那麼長。</small></div>
    <details><summary>更多（副旋鈕）</summary><div id="feel-more"></div></details>
    <div class="feel-row"><span>存成</span><button data-save="0">1</button><button data-save="1">2</button><button data-save="2">3</button><span>換到</span><button data-go="0" disabled>1</button><button data-go="1" disabled>2</button><button data-go="2" disabled>3</button></div>
    <div class="feel-row"><span>盲比</span><button data-blind="0,1" disabled>1 對 2</button><button data-blind="0,2" disabled>1 對 3</button><button data-blind="1,2" disabled>2 對 3</button></div>
  </div>
  <div id="feel-blind" class="feel-box" hidden>
    <div class="feel-row"><span>盲比中</span><button data-bs="0">摸 1 號</button><button data-bs="1">摸 2 號</button></div>
    <input id="feel-bq" type="text" placeholder="這次比哪個詞？例：哪個比較彈（可以不填）" aria-label="這次比哪個詞">
    <div class="feel-row"><button data-bp="0">選 1 號</button><button data-bp="1">選 2 號</button><button data-bp="same">分不出來</button><button data-bp="cancel">取消</button></div>
  </div>
  <details id="feel-lab"><summary>量測</summary>
    <div class="feel-row"><button id="lab-grey">灰盒</button><button id="lab-circle">純圓</button><button id="lab-reset">讀數歸零</button></div>
    <p class="feel-note" id="lab-read"></p>
    <div class="feel-row"><span>圖層</span>${LAB.LAYERS.map(l=>`<button data-layer="${l[0]}">${l[1]}</button>`).join('')}</div>
    <p class="feel-note">灰盒：只留物理（平塗、沒有聲音、牠不會自己動、擺飾收起來）。純圓：圓心就是手指，量系統本身的落後。圖層：一層一層關掉，看每幀毫秒少多少。延遲和觸覺要在手機版量，網頁只有約 60 fps。</p>
  </details>
  <div class="feel-row" id="feel-io"><button id="feel-copy">複製數值給 Agent</button><button id="feel-paste">貼上匯入</button><button id="feel-def">回到預設</button></div>
  <textarea id="feel-out" rows="4" aria-label="手感數值" hidden></textarea>
  <p class="feel-note" id="feel-note">一次只動一條，用那一條底下寫的手勢捏幾下。兩組要比，存成兩格再按盲比。</p>`;
  let sec='';const host=$('feel-sliders');for(const r of KNOBS){if(r[6]!==sec){sec=r[6];const h=document.createElement('h4');h.textContent=sec;host.appendChild(h)}deskRow(host,r)}
  for(const r of MORE)deskRow($('feel-more'),r);
  const open=on=>{root.classList.toggle('hidden',!on);$('b-feel').setAttribute('aria-expanded',String(on));if(on)deskSync()};
  $('b-feel').addEventListener('click',()=>open(root.classList.contains('hidden')));$('feel-close').addEventListener('click',()=>open(false));
  root.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;const a=n=>b.getAttribute(n);
    if(a('data-m')){setMat(a('data-m'));DESK.stale=null;DESK.pv=FEELVER;DESK.ps=deskStamp();DESK.base0=deskSnap();deskSync();deskSave();deskNote('換成'+MATN[curMat]+'的預設值。')}
    else if(a('data-save')!==null){const i=+a('data-save');DESK.slots[i]=deskSnap();deskSync();deskSave();deskNote('現在的手感存成 '+(i+1)+'。')}
    else if(a('data-go')!==null){const i=+a('data-go');deskApply(DESK.slots[i]);deskNote('換到 '+(i+1)+'（'+MATN[curMat]+'起點）。馬上捏，幾秒內再換另一個。')}
    else if(a('data-blind')){const [x,y]=a('data-blind').split(',').map(Number);blindStart(x,y)}
    else if(a('data-bs')!==null)blindShow(+a('data-bs'))
    else if(a('data-bp')!==null){const v=a('data-bp');blindEnd(v==='same'||v==='cancel'?v:+v);deskSave()}
    else if(a('data-layer')){const k=a('data-layer');if(LAB.off[k])delete LAB.off[k];else LAB.off[k]=1;deskSync()}
    else if(b.id==='feel-strand'){mat.strand=mat.strand>=.5?0:1;deskSync();if(typeof syncSliders==='function')syncSliders();deskSave()}
    else if(b.id==='lab-grey'){labGrey(!LAB.grey);deskSync()}
    else if(b.id==='lab-circle'){LAB.circle=!LAB.circle;LAB.pd=false;deskSync()}
    else if(b.id==='lab-reset'){GRD.reset();PHYS.max=0}
    else if(b.id==='feel-usenew'){setMat(curMat);DESK.stale=null;DESK.pv=FEELVER;DESK.ps=deskStamp();DESK.base0=deskSnap();deskSync();deskSave();deskNote('換成新預設（'+MATN[curMat]+'）。存檔那幾格還留著，是舊預設上調的。')}
    else if(b.id==='feel-keep'){DESK.stale=null;DESK.pv=FEELVER;DESK.ps=deskStamp();deskSync();deskSave();deskNote('留著你的數字。之後按「回到預設」可以看新預設。')}
    else if(b.id==='feel-def'){setMat(SLIMES[SLIME].mat);DESK.slots=[null,null,null];DESK.stale=null;DESK.pv=FEELVER;DESK.ps=deskStamp();DESK.base0=deskSnap();deskSync();deskSave();deskNote('回到預設（'+MATN[curMat]+'），三格存檔也清掉了。盲比紀錄留著。')}
    else if(b.id==='feel-copy'){const txt=deskText(),o=$('feel-out');o.value=txt;o.hidden=false;
      const ok=()=>deskNote('複製好了，貼給 Agent 就行。同一段字也在下面的框裡。'),bad=()=>{o.focus();o.select();deskNote('這個瀏覽器不讓直接複製，數值在下面的框裡：長按框裡的字，全選，拷貝。')};
      try{navigator.clipboard?navigator.clipboard.writeText(txt).then(ok,bad):bad()}catch(_){bad()}}
    else if(b.id==='feel-paste'){const o=$('feel-out'),go=t=>{deskNote(deskImport(t));deskSave()};
      if(DESK.pasting&&o.value.includes("#nienie-feel")){DESK.pasting=false;go(o.value)}
      else{const ask=()=>{DESK.pasting=true;o.hidden=false;o.value='';o.focus();deskNote('把那段字貼進下面的框，再按一次「貼上匯入」。')};try{navigator.clipboard&&navigator.clipboard.readText?navigator.clipboard.readText().then(t=>t&&t.includes('#nienie-feel')?go(t):ask(),ask):ask()}catch(_){ask()}}}});
  setInterval(()=>{const e=$('lab-read');if(!e||root.classList.contains('hidden')||!$('feel-lab').open)return;const g=GRD.pct();
    e.textContent='物理 '+PHYS.ms.toFixed(1)+' 毫秒（2 秒內最長 '+PHYS.max.toFixed(1)+'）｜保險作用的格：拉到上限 '+g.hi+'%、壓到下限 '+g.lo+'%、防翻面 '+g.flip+'%、手指讓 '+g.give+'%｜手指最多讓 '+g.giveMax+' 個半徑、往外拉時 '+g.givePull+'｜'+g.frames+' 格'},500)}
// 開 app 時：上次留在台上的數字回來。舊格式（v2.39：{base,v,A,B}）搬成新格式，A、B 變成存檔 1、2
// 在別的預設上調的（指紋不一樣）：先記著是哪一版，問過多米「用新預設／留著我的」才換成現在的指紋；沒回答就關掉 app，下次還會再問
function deskLoad(){DESK.ps=deskStamp();let s=null;try{s=JSON.parse(localStorage.getItem('nienie.feel')||'null')}catch(_){}
  if(s&&s.v===2&&s.k){DESK.slots=[0,1,2].map(i=>(s.s||[])[i]||null);DESK.log=Array.isArray(s.log)?s.log:[];if((s.ps||'')!==DESK.ps){DESK.stale=s.pv||'舊版';DESK.pv=s.pv||'';DESK.ps=s.ps||''}deskApply({base:s.base,k:s.k})}
  else if(s&&s.v&&typeof s.v==='object'){const up=o=>o&&o.v?{base:o.base,pv:'v2.39',ps:'',k:{...Object.fromEntries(DKEYS.map(k=>[k,PRESETS[o.base]?PRESETS[o.base][k]:mat[k]])),...o.v}}:null;
    DESK.slots=[up(s.A),up(s.B),null];DESK.stale='v2.39 到 v2.51 的調節台';DESK.pv='v2.39';DESK.ps='';deskApply(up(s))}
  DESK.base0=deskSnap();deskSync()}
deskBuild();deskLoad();
