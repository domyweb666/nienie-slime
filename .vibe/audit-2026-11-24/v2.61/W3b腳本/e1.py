W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/selftest.js'
s=open(W,encoding='utf-8',newline='').read()
def rep(a,b):
    global s
    assert s.count(a)==1,(s.count(a),a[:60]);s=s.replace(a,b)
rep("不然量打盹的 T55 到 T57 等不到","不然量打盹的 T55 到 T57 等不到\r\n  Object.assign(GREET, { st: '', until: -9, at: -9 }); EYE.user = -9; BRAIN.seed = 20261114;   // v2.61 C4：開頁面時的「先看你」把眼睛看哪裡排到第 3 秒左右、大腦的亂數起點也是真的亂數；時鐘歸零後每一項的頭幾秒眼睛都在看你、少抽亂數，後面整串手抖錯開（11-25：開關全關也紅 v226、v252，就是這個）" if "\r\n" in s else None)
rep("const carry = (k, v, n) => { fresh({}); const q","const carry = (k, v, n) => { fresh({ bumpSoft: 0 }); /* v2.61 C7：這裡沒有手指，牠自己碰到的只晃不倒；量的是「帶動」那套算式，關掉 */ const q")
rep("    const tap = (over, tr) => { fresh(over, tr); steps(120); SLP.on = true;","    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };\r\n    const tap = (over, tr) => { fresh(over, tr); steps(120); SLP.on = true;")
open(W,'w',encoding='utf-8',newline='').write(s)
