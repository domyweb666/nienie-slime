const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};
const ON=Object.fromEntries(KEYS61.map(k=>[k,PRESETS.clay[k]])),OFF=K61.all0;const mean=a=>a.reduce((x,y)=>x+y,0)/(a.length||1),sd1=a=>a.length>1?Math.sqrt(mean(a.map(x=>(x-mean(a))**2))):0;
const qs=new URLSearchParams(location.search),nm=qs.get('m'),sd=+qs.get('s'),MIN=+(qs.get('min')||60);set(nm==='off'?OFF:ON);
open(sd,{tr:.3});const cb=BMEM,ivs=[],dur=[],awake=[],first={},act={},order=[],falls=[],LG=[];let was=false,on0=-1,off0=-1,nd=false,na=false,sl=0;
const op=brainPick,og=brainGo;brainPick=c=>{const w=op(c);if(nd){first[w]=(first[w]||0)+1;nd=false}if(na&&w!=='rest'){act[w]=(act[w]||0)+1;order.push(w);na=false}return w};
const up=q=>Math.abs(Math.atan2(Math.sin(q.a),Math.cos(q.a))),st={};
let nan=0;steps(MIN*3600,i=>{if(SLP.on)sl++;if(SLP.on!==was){if(SLP.on){if(on0>=0)ivs.push(t-on0);if(off0>=0)awake.push(t-off0);on0=t}else{dur.push(t-on0);off0=t;nd=na=true}was=SLP.on}
 for(const p of PROPS){if(!p.deco)continue;const f=!!(p.gone||up(p)>.6);if(f&&!st[p.im])falls.push([p.im,Math.round(t),drRecent(p.catT,4)?'cat':'self',SLP.on?1:0]);st[p.im]=f}
 if(i%3600===0&&!isFinite(X[0]))nan++});
const n=k=>LOG.filter(x=>x[1]===k).length,c={};for(const x of LOG)c[x[1]]=(c[x[1]]||0)+1;
return {m:nm,sd,MIN,睡次:dur.length,間隔:[Math.round(mean(ivs)),Math.round(sd1(ivs)),Math.round(Math.min(...ivs)),Math.round(Math.max(...ivs))],ivs:ivs.map(Math.round),睡長:[Math.round(mean(dur)),Math.round(sd1(dur))],醒長:[Math.round(mean(awake)),Math.round(sd1(awake))],睡pct:Math.round(sl/(MIN*36)),第一決定:first,第一動作:act,order,falls,fallSelf:falls.filter(f=>f[2]==='self').length,fallCat:falls.filter(f=>f[2]==='cat').length,topple:n('fx.topple'),fallout:n('fx.fallout'),startle:n('voice.startle'),voice:LOG.filter(x=>/^voice/.test(x[1])).length,knock:LOG.filter(x=>/^knock/.test(x[1])).length,total:LOG.length,kinds:c,nan};
