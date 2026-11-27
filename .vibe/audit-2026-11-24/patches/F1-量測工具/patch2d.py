import os
p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/src2/prototype/web/index.html'
s=open(p,encoding='utf-8').read()
a="return F1S<.25?1:Math.max(F1X.crMin||.02,1-(F1S-.25)/.25)}"
assert s.count(a)==1
s=s.replace(a,"const g0=F1S<.25?1:Math.max(F1X.crMin||.02,1-(F1S-.25)/.25);return 1-pullK()*(1-g0)}")
# 逃跑：身體還很長就先不逃（長度超過原本 flL 倍時，逃的距離縮到 0，等縮短再說）
b="  if(MOOD.strainMax>.15){flee("
assert s.count(b)==1
s=s.replace(b,"  if(MOOD.strainMax>.15&&F1X.fl&&f1Per()>F1X.fl*HRC[HRX.length]){MOOD.strainMax=0;MOOD.scare=Math.min(1,MOOD.scare+.5);return}\n  if(MOOD.strainMax>.15){flee(")
open(p+'.t','w',encoding='utf-8').write(s);os.replace(p+'.t',p);print('ok')
