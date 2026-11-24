const S={neutral:{},wary:{w:.9},comfort:{f:()=>{MOOD.c=1;MOOD.a=.15}},cower:{f:()=>{MOOD.cowerUntil=t+1}},asleep:{f:()=>{SLP.on=true;LIFE.st='sleep'}},moodBad:{f:()=>{BRAIN.m=-.8;BRAIN.mS=-.8}},trust:{tr:.9}};
const out={};
for(const k in S){const s=S[k];fresh(5,{},{tr:s.tr||0,w:s.w||0,settle:200});const keep=()=>{if(LIFE.st!=='sleep')LIFE.st='rest';LIFE.until=t+1e6;GAIT.on=false;BRAIN.s=0;IMP.tr=s.tr||0;IMP.w=s.w||0;EYE.user=t+1;if(s.f)s.f()};for(let i=0;i<300;i++){keep();update(DT)}let w=0,h=0,A=0,con=0,n=0;for(let i=0;i<60*12;i++){keep();update(DT);const g=geo();w+=g.w;h+=g.h;A+=g.A;n++;let x0=1e9,x1=-1e9;for(const j of bnd)if(Y[j]>SILL.g.fl-3){x0=Math.min(x0,X[j]);x1=Math.max(x1,X[j])}con+=x1-x0}out[k]={w:r2(w/n*.16565),h:r2(h/n*.16565),A:r2(A/n),con:r2(con/n*.16565)}}
return out;
