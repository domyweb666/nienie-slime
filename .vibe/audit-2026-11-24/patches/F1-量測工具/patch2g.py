import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
def rep(a,b):
    global s
    assert s.count(a)==1,(s.count(a),a[:80]); s=s.replace(a,b)
rep("const a=strainStep(X,Y,mat.capLo,mat.stretchCap*capG(),true)","const a=strainStep(X,Y,mat.capLo,mat.stretchCap*capG()*f1Ease(),true)")
rep("function remeshCheck(dt){","let F1C0=1,F1CT=-9;function f1Ease(){if(!(F1X.ce>0)||F1CT<0||t<F1CT)return 1;const u=Math.min(1,(t-F1CT)/F1X.ce);return F1C0+(1-F1C0)*u*u*(3-2*u)}\nfunction remeshCheck(dt){")
rep("  DENTS.length=0;CAPG=1;\n","  DENTS.length=0;CAPG=1;if(F1X.ce>0){if(back){F1CT=-9}else{let m=0;for(let e=0,k=0,n=EDG.length;e<n;e+=2,k++){const i=EDG[e],j=EDG[e+1],l=Math.hypot(X[i]-X[j],Y[i]-Y[j])/EDL[k];if(l>m)m=l}F1C0=Math.min(1,m*1.02/mat.stretchCap);F1CT=t}}\n")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
