import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
def rep(a,b,c=1):
    global s
    assert s.count(a)==c,(s.count(a),a[:100]); s=s.replace(a,b)
# 回正：尖端每秒最多 up 個 R
rep("  const rotK=-gAng*Math.min(.2,grabbing?Math.min(mat.upright*mat.anchor*mat.gripRot,mat.gripUp>=0?mat.gripUp:1):mat.upright);","  let rotK=-gAng*Math.min(.2,grabbing?Math.min(mat.upright*mat.anchor*mat.gripRot,mat.gripUp>=0?mat.gripUp:1):mat.upright);if(F1X.up>0&&!grabbing){let rm=0;for(const i of bnd){const q=(X[i]-cx)**2+(Y[i]-cy)**2;if(q>rm)rm=q}const lim=F1X.up*R*dt/Math.max(R*.5,Math.sqrt(rm));rotK=Math.max(-lim,Math.min(lim,rotK))}")
# 小結拉直：一次最多動 uk 個點距
rep("dx=tx-X[c],dy=ty-Y[c];X[c]+=dx;Y[c]+=dy;PX[c]+=dx;PY[c]+=dy}","dx0=tx-X[c],dy0=ty-Y[c],dl0=Math.hypot(dx0,dy0),kk0=F1X.uk>0&&dl0>h*F1X.uk?h*F1X.uk/dl0:1,dx=dx0*kk0,dy=dy0*kk0;X[c]+=dx;Y[c]+=dy;PX[c]+=dx;PY[c]+=dy}")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
