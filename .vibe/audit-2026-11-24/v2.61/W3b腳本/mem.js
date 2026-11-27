// 記地方：討厭的那格待多久／對照，多種子，brJit 1 對 0
const R1={};const set=(o)=>{for(const k in PRESETS)Object.assign(PRESETS[k],o);Object.assign(mat,o)};const qs=new URLSearchParams(location.search),S0=+qs.get('s'),N0=+(qs.get('n')||3);
for(const jit of [0,1]){set({brJit:jit});const r=[];for(let s=S0;s<S0+N0;s++){const one=[];for(const bad of [0,1]){open(s*31+7,{tr:.7});BRAIN.seed=s*977+57;BRAIN.z=.3;BRAIN.q=.3;BRAIN.e=.4;E4.count=0;BMEM.cell=[0,0,0,0,0];const m=memCellAt(SILL.g.bx);if(bad)BMEM.cell[m]=-.8;let c=0,n=0;steps(120*60,()=>{n++;if(SILL.plane==='room'&&memCellAt(globalC.xc)===m)c++});one.push(+(c/n).toFixed(3))}r.push(one)}R1['jit'+jit]=r}
return R1;
