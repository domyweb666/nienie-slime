# 三個試做：p 慢摸跨放手累積、q 輕點不算嚇、r 手指按住 0.25 秒就不當節奏。用法：python apply.py <p|q|r> <prototype/web 資料夾> <輸出資料夾>
import sys, shutil, os
sys.stdout.reconfigure(encoding='utf-8')
k,src,dst=sys.argv[1:4]
if os.path.exists(dst): shutil.rmtree(dst)
shutil.copytree(src,dst)
f=os.path.join(dst,'index.html'); s=open(f,encoding='utf-8').read()
def rep(a,b):
    global s
    assert s.count(a)==1,(k,a[:50],s.count(a)); s=s.replace(a,b)
if k=='p':
    rep("  let g=null;for(const f of fingers.values())if(f.mode==='grab'&&(!g||SB(f)>SB(g)))g=f;\n  if(g){const st=SB(g),sp=Math.hypot(g.vxS,g.vyS)/R;\n    const v24=","""  let g=null;for(const f of fingers.values())if(f.mode==='grab'&&(!g||SB(f)>SB(g)))g=f;
  if(g){if(!g.pc)g.pc=[globalC.xc,globalC.yc];const spc=Math.hypot(g.vxS,g.vyS)*CAM.z/60,ins=Math.hypot(g.x-g.pc[0],g.y-g.pc[1])<R*1.1,wv=spc>.4?Math.exp(-(Math.log(spc/3)**2)/1.62):0;
    if(ins&&spc<12&&wv>.2&&!tickOn()&&MOOD.strain<.05&&fingers.size===1){PET.g=Math.min(3,PET.g+2*wv*dt);PET.last=t}else if(!ins||spc>14)PET.g=Math.max(0,PET.g-3*dt)}
  else if(t-PET.last>.6)PET.g=Math.max(0,PET.g-.6*dt);
  if(PET.g>1&&t-PET.last<.6){MOOD.c=Math.min(1,MOOD.c+.9*dt);IMP.tr=Math.min(1,IMP.tr+(.04+.04*PURR)*dt*3*(mat.trRate||1));IMP.w=Math.max(0,IMP.w-.05*dt*3)}
  if(g){const st=SB(g),sp=Math.hypot(g.vxS,g.vyS)/R;
    const v24=""")
    rep("const pt=(g&&(g.gentleT||0)>1||!g&&STK.g>1&&t-STK.last<.6)&&MOOD.c>.2","const pt=(g&&(g.gentleT||0)>1||!g&&STK.g>1&&t-STK.last<.6||PET.g>1&&t-PET.last<.6)&&MOOD.c>.2")
    s=s.replace("const LIFE={st:'rest'","const PET={g:0,last:-9};\nconst LIFE={st:'rest'",1)
elif k=='q':
    rep("MOOD.taps.push(t);MOOD.scare=Math.min(1,MOOD.scare+.45);MOOD.a=Math.min(1,MOOD.a+.3);MOOD.c=Math.max(-1,MOOD.c-.1);MOOD.cowerUntil=Math.max(MOOD.cowerUntil,t+.5);","MOOD.taps.push(t);{const hard=MOOD.taps.length>=3,h=hard?1:.15*(1-IMP.tr);MOOD.scare=Math.min(1,MOOD.scare+.45*h);MOOD.a=Math.min(1,MOOD.a+.3*(hard?1:.4));if(hard){MOOD.c=Math.max(-1,MOOD.c-.1);MOOD.cowerUntil=Math.max(MOOD.cowerUntil,t+.5)}}")
    rep("else if(quick){IMP.w+=taps>=3?.2:.04;","else if(quick){IMP.w+=taps>=3?.2:0;")
elif k=='r':
    rep("  if(ECHO.st!=='idle')return;   // v2.23 C6","  {let hold=false;for(const f of fingers.values())if(f.lure&&f.mode==='push'&&t-f.tDown>.25)hold=true;if(hold&&ECHO.st==='listen'){ECHO.st='idle';ECHO.taps.length=0}}\n  if(ECHO.st!=='idle')return;   // v2.23 C6")
open(f,'w',encoding='utf-8').write(s); print('ok',k,dst)
