import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
a="else for(let i=0;i<N;i++){const vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}"
assert s.count(a)==1
s=s.replace(a,"else if(F1X.vc>0&&!fingers.size&&t-lastTouch<(F1X.vcT||.8)&&!INTRO.on&&!SILL.hop){const lim=F1X.vc*R*dt;for(let i=0;i<N;i++){let vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;const sp=Math.hypot(vx,vy);if(sp>lim){vx*=lim/sp;vy*=lim/sp}PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}}"+a)
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
