// 情緒通道幅度：固定在休息，量寬、高、面積、呼吸、眼睛、體色
const S={
 neutral:{},
 trust:{tr:.9},
 wary:{w:.9},
 comfort:{f:()=>{MOOD.c=1;MOOD.a=.15}},
 scare:{f:()=>{MOOD.scare=1}},
 cower:{f:()=>{MOOD.cowerUntil=t+1}},
 asleep:{f:()=>{SLP.on=true;LIFE.st='sleep'}},
 moodGood:{f:()=>{BRAIN.m=.8;BRAIN.mS=.8}},
 moodBad:{f:()=>{BRAIN.m=-.8;BRAIN.mS=-.8}},
 happyPose:{f:()=>{if(!(t-MOOD.happyT<.3))MOOD.happyT=t}},
 panting:{f:()=>{BRX.exert=1}},
 trustGood:{tr:.9,f:()=>{BRAIN.m=.8;BRAIN.mS=.8}},
 waryBad:{w:.9,f:()=>{BRAIN.m=-.8;BRAIN.mS=-.8}}
};
function lab(r,g,b){const f=v=>{v/=255;return v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4)};r=f(r);g=f(g);b=f(b);let x=(.4124*r+.3576*g+.1805*b)/.95047,y=.2126*r+.7152*g+.0722*b,z=(.0193*r+.1192*g+.9505*b)/1.08883;const q=v=>v>.008856?Math.cbrt(v):7.787*v+16/116;x=q(x);y=q(y);z=q(z);return[116*y-16,500*(x-y),200*(y-z)]}
function patch(dx,dy,rad){const[sx,sy]=scr(globalC.xc+dx*R,globalC.yc+dy*R),D=DPR,x0=Math.round((sx-rad)*D),y0=Math.round((sy-rad)*D),n=Math.round(rad*2*D),im=ctx.getImageData(x0,y0,n,n).data;let r=0,g=0,b=0,k=0;for(let i=0;i<im.length;i+=4){r+=im[i];g+=im[i+1];b+=im[i+2];k++}return[r/k,g/k,b/k]}
const out={};
for(const bg of ['day','night']){VIEW.bg=bg;
for(const k in S){const s=S[k];fresh(5,{},{tr:s.tr||0,w:s.w||0,settle:200});
  const keep=()=>{if(LIFE.st!=='sleep'){LIFE.st='rest'}LIFE.until=t+1e6;GAIT.on=false;BRAIN.s=0;IMP.tr=s.tr||0;IMP.w=s.w||0;EYE.user=t+1;if(s.f)s.f()};
  for(let i=0;i<60*5;i++){keep();update(DT)}
  const H=[],Wd=[],Ar=[],ey=[],wd=[],lines=[];for(let i=0;i<60*24;i++){keep();update(DT);const g=geo();H.push(g.h);Wd.push(g.w);Ar.push(g.A);ey.push(EYE.openD);wd.push(EYE.wideD)}
  // 呼吸：高度的峰值間隔與峰對峰
  const mean=a=>a.reduce((x,y)=>x+y,0)/a.length;const sm=[];for(let i=0;i<H.length;i++){let q=0,c=0;for(let j=Math.max(0,i-6);j<=Math.min(H.length-1,i+6);j++){q+=H[j];c++}sm.push(q/c)}
  const pk=[];for(let i=20;i<sm.length-20;i++){let ok=true;for(let j=i-20;j<=i+20;j++)if(sm[j]>sm[i]){ok=false;break}if(ok&&(!pk.length||i-pk[pk.length-1]>40))pk.push(i)}
  const per=pk.length>1?(pk[pk.length-1]-pk[0])/(pk.length-1)/60:null;let pp=[];for(let a=0;a+1<pk.length;a++){let mn=1e9;for(let j=pk[a];j<pk[a+1];j++)mn=Math.min(mn,sm[j]);pp.push(sm[pk[a]]-mn)}
  const med=a=>{const b=[...a].sort((x,y)=>x-y);return b.length?b[b.length>>1]:null};
  draw();const c0=patch(0,.15,R*.22),c1=patch(0,-.45,R*.12);
  out[bg+'.'+k]={w:r2(mean(Wd)),h:r2(mean(H)),A:r2(mean(Ar)),per:per&&r2(per),pp:r2(med(pp)||0),ppW:r2(Math.max(...Wd)-Math.min(...Wd)),open:r3(mean(ey)),wide:r3(mean(wd)),mode:EYE.mode,rgb:c0.map(Math.round),lab:lab(...c0).map(r2),rgbTop:c1.map(Math.round),labTop:lab(...c1).map(r2),tint:[tint(getComputedStyle(document.documentElement).getPropertyValue('--body').trim())]};
}}
out.R=R;out.eye={ew:R*.88*.082*.68,eh:R*.88*.118*.68};
return out;
