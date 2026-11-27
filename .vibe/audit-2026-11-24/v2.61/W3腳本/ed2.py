W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/selftest.js'
s=open(W,encoding='utf-8',newline='').read();a="  // T70 v2.61 破皮（A7）。"
assert s.count(a)==1 and 'T71' not in s
s=s.replace(a,open('t71.txt',encoding='utf-8').read().replace('\r\n','\n').replace('\n','\r\n')+a)
h="   v2.61（11-25）：加 T70"
s=s.replace(h,"   v2.61（11-25）：加 T71（W3：睡醒、手指放旁邊、打開先看你、眼睛、換隻記憶）\r\n"+h)
open(W,'w',encoding='utf-8',newline='').write(s)
