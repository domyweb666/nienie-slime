W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/selftest.js'
s=open(W,encoding='utf-8',newline='').read()
a="  IMPSV.noSave = true; const IMP0 ="
assert s.count(a)==1
s=s.replace(a,"  SLP.openT = -99;   // v2.61 C1：時鐘歸零的項目不算「剛打開」（剛打開 40 秒不睡），不然量打盹的 T55 到 T57 等不到\r\n"+a)
open(W,'w',encoding='utf-8',newline='').write(s)
