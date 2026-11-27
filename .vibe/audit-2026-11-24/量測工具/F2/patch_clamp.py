import sys
sys.stdout.reconfigure(encoding='utf-8')
P=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix4/prototype/web/index.html'
s=open(P,encoding='utf-8').read()
a="    if(JELX.mode===9){const Rz=R*zz,T=jelThick("
assert s.count(a)==1
b="    {const w0=worldWalls(),cl=(v0,lo,hi)=>v0<lo?lo:v0>hi?hi:v0,xl=isFinite(w0.l)?A*w0.l+E+rr:-1e9,xr=isFinite(w0.r)?A*w0.r+E-rr:1e9,yb=isFinite(w0.b)?D*w0.b+F-rr:1e9;if(Math.abs(B)<1e-9&&Math.abs(C)<1e-9&&xl<xr)for(let i=0;i<n;i++){const x=IX[2*i];if(x>xl-rr*2&&x<xr+rr*2)IX[2*i]=cl(x,xl,xr);if(IX[2*i+1]>yb)IX[2*i+1]=yb}}   // 貼牆的線往裡挪一個半徑，不然裁掉一半又變細\n"
s=s.replace(a,b+a)
open(P,'w',encoding='utf-8').write(s);print('ok')
