import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
def rep(a,b):
    global s
    assert s.count(a)==1,(s.count(a),a[:80]); s=s.replace(a,b)
rep("  const cgx=globalC.cs,cgy=globalC.sn;\n  N=n2;bnd=nbnd;","  const cgx=globalC.cs,cgy=globalC.sn,f1gx=globalC.xc,f1gy=globalC.yc;let f1mx=0,f1my=0;for(let i=0;i<N;i++){f1mx+=X[i];f1my+=Y[i]}f1mx/=N;f1my/=N;\n  N=n2;bnd=nbnd;")
rep("  DENTS.length=0;CAPG=1;if(F1X.ce>0)","  if(F1X.hs){let a=0,b=0;for(let i=0;i<N;i++){a+=X[i];b+=Y[i]}const sx=a/N-f1mx,sy=b/N-f1my;HOMEX+=sx;HOMEY+=sy;if(CPX!=null){CPX+=sx;CPY+=sy}globalC.xc=f1gx+sx;globalC.yc=f1gy+sy}\n  DENTS.length=0;CAPG=1;if(F1X.ce>0)")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
