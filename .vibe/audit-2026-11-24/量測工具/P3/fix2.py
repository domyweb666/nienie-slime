import sys
sys.stdout.reconfigure(encoding='utf-8')
p='P3.md'; s=open(p,encoding='utf-8').read()
def rep(a,b):
    global s
    assert s.count(a)==1,(a[:40],s.count(a)); s=s.replace(a,b)
rep("## 附錄 E：別的觀察（沒有深入）","## 附錄 E：別的觀察（沒有往下查）")
rep("**原理**：關係不是從不出錯，是出錯後會修；修得快慢看熟不熟。","**原理**：關係會出錯，出錯後修得回來；修得快慢看熟不熟。")
open(p,'w',encoding='utf-8').write(s)
