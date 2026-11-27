import sys
sys.stdout.reconfigure(encoding='utf-8')
p=r'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2.md'
s=open(p,encoding='utf-8').read()
print(len(s), s.count('GPU 約 +0.45'), s.count('1.4 到 2.2 毫秒'))
