import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
a="  const cs=R*mat.cSpace,cr=R*mat.cRad;"
assert s.count(a)==1
s=s.replace(a,"  const cs=R*mat.cSpace;let cr=R*mat.cRad;if(F1X.rc>0&&bnd.length&&HRX.length){let s0=0;const n=bnd.length;for(let k=0;k<n;k++){const i=bnd[k],j=bnd[(k+1)%n];s0+=Math.hypot(Q0X[j]-Q0X[i],Q0Y[j]-Q0Y[i])}cr*=Math.min(F1X.rc,Math.max(1,s0/HRC[HRX.length]))}")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
