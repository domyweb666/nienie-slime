import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
def rep(a,b,c=1):
    global s
    assert s.count(a)==c,(s.count(a),a[:100]); s=s.replace(a,b)
rep("    if(sw>0){const cs=effSlip();","    if(sw>0&&!(F1X.gv&&F1S>.25&&Math.hypot(sx,sy)>0&&(f.slx||0)*sx+(f.sly||0)*sy>0&&Math.hypot(f.slx||0,f.sly||0)>R*(F1X.gvL||.3))){const cs=effSlip();")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
