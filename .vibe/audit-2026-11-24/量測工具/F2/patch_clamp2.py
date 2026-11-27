import sys
sys.stdout.reconfigure(encoding='utf-8')
P=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix4/prototype/web/index.html'
s=open(P,encoding='utf-8').read()
a="{const x=IX[2*i];if(x>xl-rr*2&&x<xr+rr*2)IX[2*i]=cl(x,xl,xr);if(IX[2*i+1]>yb)IX[2*i+1]=yb}}"
assert s.count(a)==1
s=s.replace(a,"if(IX[2*i+1]>yb)IX[2*i+1]=yb}")   # 只挪地板（左右是軟牆，挪了會在螢幕邊多出小塊）
open(P,'w',encoding='utf-8').write(s);print('ok')
