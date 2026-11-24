import sys,json,time
from drv import *
from playwright.sync_api import sync_playwright
src,port=sys.argv[1],int(sys.argv[2]);srv=serve(src,port)
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context(viewport={'width':393,'height':852},has_touch=True).new_page();errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:200]))
    E=pg.evaluate
    for k in range(3):
        pg.goto(f'http://127.0.0.1:{port}/index.html?all=1');r=[]
        for i in range(14):
            pg.wait_for_timeout(100);r.append(E('[+t.toFixed(2),GREET.st,t<GREET.until?1:0,+EYE.gy.toFixed(2)]'))
        print('開機',k,[x for i,x in enumerate(r) if i%3==0],'首看',next((x[0] for x in r if x[2]),None),'種子',E('BRAIN.seed'))
    n=E('SLIMES.length');o=[]
    for i in list(range(n))+[0]:
        E('i=>{const e=document.getElementById("s-"+i);e.scrollIntoView()}',i);pg.click(f'#s-{i}',force=True);pg.wait_for_timeout(1300)
        o.append(E('[SLIMES[SLIME].id,t<GREET.until||GREET.st?1:0,SLP.openT>0?1:0,BMEM.cell.join("")]'))
    print('換十隻一圈',o)
    # 切背景再回來（醒著、睡著）
    hide="v=>{Object.defineProperty(document,'hidden',{configurable:true,get:()=>v});document.dispatchEvent(new Event('visibilitychange'))}"
    for nm,pre in (('醒','SLP.on=false;EYE.user=-9;GREET.until=-9'),('睡','SLP.on=true;SLP.k=1;LIFE.st="sleep";EYE.user=-9;GREET.until=-9')):
        for k in range(5):
            E(pre);pg.wait_for_timeout(200);E(hide,True);pg.wait_for_timeout(300);E(hide,False);a=E('[SLP.on,GREET.st]');pg.wait_for_timeout(700);q=E('[t<GREET.until?1:0,+EYE.gx.toFixed(2),+EYE.gy.toFixed(2),+SLP.k.toFixed(2),EYE.mode]');pg.wait_for_timeout(1400);z=E('[+SLP.k.toFixed(2),EYE.mode]')
            if k in(0,4):print('切回來',nm,k,a,q,z)
    E("dispatchEvent(new Event('blur'))");pg.wait_for_timeout(50);E("dispatchEvent(new Event('focus'))");pg.wait_for_timeout(600);print('focus',E('t<GREET.until'))
    # 睡著真的用滑鼠點
    for tr in (0,.5,.95):
        E('tr=>{IMP.tr=tr;IMP.w=0;SLP.on=true;SLP.k=1;LIFE.st="sleep";BRAIN.z=.9;BRAIN.m=.15;MOOD.taps=[];window.__v=[];if(!window.__sp){window.__sp=sfxPlay;sfxPlay=(k,...a)=>{window.__v.push(k);return window.__sp(k,...a)}}}',tr)
        q=E('(()=>{const v=viewV();return [(globalC.xc-CAM.x)*CAM.z+v.x,(globalC.yc-CAM.y)*CAM.z+v.y]})()');pg.mouse.move(*q);pg.mouse.down();pg.wait_for_timeout(120);pg.mouse.up();pg.wait_for_timeout(900)
        print('滑鼠點睡著的 熟',tr,'還睡',E('SLP.on'),E('window.__v.filter(k=>/voice/.test(k))'))
    # 調節台
    E("document.getElementById('feel').classList.remove('hidden');document.getElementById('feel').style.display='block'")
    R=[]
    for t in ('b158','fix','pull','fix'):
        pg.eval_on_selector(f'[data-61t="{t}"]','e=>e.click()');R.append((t,E("KEYS61.map(k=>+mat[k]).join('')"),E("[...document.querySelectorAll('[data-61t]')].map(b=>b.getAttribute('aria-pressed')[0]).join('')")))
    for g in range(5):
        pg.eval_on_selector(f'[data-61g="{g}"]','e=>e.click()');a=E("KEYS61.filter(k=>mat[k]<.5&&!PULL3.includes(k)).join(',')");pg.eval_on_selector(f'[data-61g="{g}"]','e=>e.click()');R.append((g,a))
    for x in R:print('調節台',x)
    pg.wait_for_timeout(1500);print('錯誤',errs);b.close()
srv.shutdown()
