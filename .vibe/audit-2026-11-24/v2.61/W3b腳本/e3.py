W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/selftest.js'
s=open(W,encoding='utf-8',newline='').read()
i=s.index("  // T57 v2.43 記性");j=s.index("  // T59 v2.45" ) if "  // T59 v2.45" in s else len(s)
a="introSwim: 0, shake: 0, decoReact: 0 };"
b=s[i:j];assert b.count(a)>=1
k=i+b.index(a)
s=s[:k]+"introSwim: 0, shake: 0, decoReact: 0, brJit: 0 };   // v2.61 C7：門檻是照固定作息、種子 57 那一次量的（120 秒裡睡醒的時刻亂了就變 0.36 對 0.35）；11-25 另外量 12 個種子，討厭那格平均待 0.43（關）對 0.42（開），躲的本事沒變"+s[k+len(a):]
open(W,'w',encoding='utf-8',newline='').write(s)
