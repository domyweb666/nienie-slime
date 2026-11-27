p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
def rep(a,b,c=1):
    global s
    assert s.count(a)==c,(s.count(a),a[:100]); s=s.replace(a,b)
rep("const $=id=>document.getElementById(id);","const $=id=>document.getElementById(id);window.F1X={};",1)
# 1 空中：只有整團不加阻尼，身體裡面照材質
rep("for(let i=0;i<N;i++){const vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}",
"if(F1X.ad&&SILL.on&&SILL.air&&!(INTRO.on&&INTRO.ph==='air')){let mx=0,my=0;for(let i=0;i<N;i++){mx+=X[i]-PX[i];my+=Y[i]-PY[i]}mx/=N;my/=N;const dd=mat.damp;for(let i=0;i<N;i++){const vx=mx+(X[i]-PX[i]-mx)*dd,vy=my+(Y[i]-PY[i]-my)*dd;PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}}else for(let i=0;i<N;i++){const vx=(X[i]-PX[i])*damp,vy=(Y[i]-PY[i])*damp;PX[i]=X[i];PY[i]=Y[i];X[i]+=vx+Gh*dt*dt;Y[i]+=vy+G*dt*dt}")
# 2 換回原本網格：乾淨才換
rep("if(REM.n>0&&HB.length===bnd.length&&remesh(true))","if(REM.n>0&&HB.length===bnd.length&&(!F1X.bg||!ringCrossed()&&!ringCrossedQ()&&flipCount(X,Y)<=(F1X.bg>1?0:2))&&(!(F1X.bl>0)||f1Per()<F1X.bl*HRC[HRX.length])&&remesh(true))")
rep("function remeshCheck(dt){","function f1Per(){let s=0;const n=bnd.length;for(let k=0;k<n;k++){const i=bnd[k],j=bnd[(k+1)%n];s+=Math.hypot(QX[j]-QX[i],QY[j]-QY[i])}return s}\nfunction remeshCheck(dt){")
# 3 放寬上限：只在手指真的在動的時候
rep("if(held){if(gap>.12&&mat.stretchCap>0)","if(held){if(gap>.12&&mat.stretchCap>0&&(!F1X.cg||f1Moving()))")
rep("function capGrowStep(dt){","function f1Moving(){for(const f of fingers.values())if(f.mode==='grab'&&Math.hypot(f.vxS||0,f.vyS||0)>R*.3)return true;return false}\nfunction capGrowStep(dt){")
# 4 手指停著：不再記形（不流）
rep("*RATE.kc*dt*g)*(mat.rubSpeed>0&&tickOn()?0:1);","*RATE.kc*dt*g)*(mat.rubSpeed>0&&tickOn()?0:1)*(F1X.cr?f1Creep(dt):1);")
rep("function plasticity(dt){","let F1S=0;function f1Creep(dt){F1S=f1Moving()?0:F1S+dt;return F1S<.25?1:Math.max(F1X.crMin||.02,1-(F1S-.25)/.25)}\nfunction plasticity(dt){")
# 6 往裡拉：整隻先跟
rep("f.mode='grab';f.ax=f.x;f.ay=f.y;f.fx=f.x;f.fy=f.y;f.stretch=0;f.ex=0;f.ey=0;f.sb=0;f.step=0;f.hold=0;f.press=0;f.pressOn=false;f.peak=0;f.on=false;fingerGrab","f.mode='grab';f.ax=f.x;f.ay=f.y;f.fx=f.x;f.fy=f.y;f.stretch=0;f.ex=0;f.ey=0;f.sb=0;f.step=0;f.hold=0;f.press=0;f.pressOn=false;f.peak=0;f.on=false;f.r0x=f.x-globalC.xc;f.r0y=f.y-globalC.yc;fingerGrab")
rep("  if(grab)fingerGrab(f,p);","  if(grab){f.r0x=p.x-globalC.xc;f.r0y=p.y-globalC.yc;fingerGrab(f,p)}")
rep("const dx=sx/n,dy=sy/n,dl=Math.hypot(dx,dy);if(dl<1e-9)return[0,0,n];const S=slideLen(),st=S*Math.tanh((1-dragFollow())*dl/S);return[dx-dx/dl*st,dy-dy/dl*st,n]}",
"let dx=sx/n,dy=sy/n,dl=Math.hypot(dx,dy);if(dl<1e-9)return[0,0,n];let cx0=0,cy0=0;if(F1X.iw&&n===1){const f=[...fingers.values()].find(q=>q.mode==='grab');if(f&&f.r0x!=null){const rl=Math.hypot(f.r0x,f.r0y);if(rl>R*.1){const ux=f.r0x/rl,uy=f.r0y/rl,p=-(dx*ux+dy*uy);if(p>0){const wt=smooth01((rl/R-.15)/.35),c=Math.min(p,rl*(F1X.iwK||1.6))*wt;cx0=-ux*c;cy0=-uy*c;dx-=cx0;dy-=cy0;dl=Math.hypot(dx,dy)||1e-9}}}}const S=slideLen(),st=S*Math.tanh((1-dragFollow())*dl/S);return[cx0+dx-dx/dl*st,cy0+dy-dy/dl*st,n]}")
open(p,'w',encoding='utf-8').write(s);print('patched')
