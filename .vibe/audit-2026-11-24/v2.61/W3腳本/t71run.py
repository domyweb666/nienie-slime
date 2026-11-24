import sys,json,re,shutil,os
from drv import *
from playwright.sync_api import sync_playwright
W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/selftest.js'
s=open(W,encoding='utf-8',newline='').read()
if "VIEW.bg = 'room'" in s: s=s.replace("VIEW.bg = 'room'","VIEW.bg = VIEW0.bg");open(W,'w',encoding='utf-8',newline='').write(s)
i=s.index('  // T1 輕按 0.1 秒');j=s.index('  // T71 v2.61 W3');k=s.index('  // T70 v2.61 破皮')
code=s[:i]+"  res.PASS={};const sc=(x,y)=>{const v=viewV(),q=cv.getBoundingClientRect();return[(x-CAM.x)*CAM.z+v.x+q.left,(y-CAM.y)*CAM.z+v.y+q.top]};\n"+s[j:k]+"\n return {r:res.T71_w3,p:res.PASS}})()"
srv=serve('../snap2',9410)
with sync_playwright() as p:
    b,pg,errs=page(p,9410);r=pg.evaluate('async c=>await (0,eval)(c)',code);print(json.dumps(r,ensure_ascii=False),errs);b.close()
srv.shutdown()
