import sys,os
D=os.path.dirname(os.path.abspath(__file__))+'/'
sys.path.insert(0,D+'tool')
from srv import *
from playwright.sync_api import sync_playwright
srv=serve(D+'web61',8992)
ST="()=>KEYS61.map(k=>mat[k]).join('')+' tier='+[...document.querySelectorAll('[data-61t][aria-pressed=true]')].map(b=>b.textContent)+' pull='+[...document.querySelectorAll('[data-61p]')].map(b=>b.getAttribute('aria-pressed')==='true'?1:0).join('')+' '+SLIMES[SLIME].name+'/'+curMat"
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);pg=cx.new_page();errs=[];pg.on('pageerror',lambda e:errs.append(str(e)[:150]))
    U='http://127.0.0.1:8992/index.html'
    pg.goto(U,wait_until='load');pg.wait_for_timeout(1500);pg.click('#b-feel');pg.wait_for_timeout(300)
    def c(sel,nm): pg.click(sel);pg.wait_for_timeout(120);print(nm,pg.evaluate(ST))
    print('起',pg.evaluate(ST))
    c('[data-61t=b158]','158');c('[data-sl="0"]','158後換隻');c('[data-m="mochi"]','158後換材質');c('[data-61t=pull]','全開');c('[data-sl="2"]','全開後換隻');c('[data-61t=fix]','只修錯')
    c('[data-save="0"]','存1');c('[data-61p=pullHold]','A3');c('[data-61p=pullSoft]','A5');c('[data-61g="1"]','關記你組');c('[data-save="1"]','存2');c('[data-go="0"]','換1');c('[data-go="1"]','換2');c('[data-style="jelly"]','風格');c('[data-go="1"]','換2')
    t=pg.evaluate("deskText()");print('匯出',t.split('\n')[-2][:60],'| json含拉',t.count('pullHold'));print('匯入一致',pg.evaluate("(()=>{const a=deskText();for(const k of PULL3)mat[k]=0;deskImport(a);return a===deskText()})()"))
    pg.evaluate("(document.getElementById('feel').scrollTop=0)");pg.screenshot(path=D+'desk.png')
    pg.reload(wait_until='load');pg.wait_for_timeout(1500);print('重整',pg.evaluate(ST))
    c2=lambda s:pg.evaluate(f"document.querySelector('{s}').click()");c2('#feel-def');print('回預設',pg.evaluate(ST))
    for q in('0','1','hold,soft'):
        pg.goto(U+'?pull='+q,wait_until='load');pg.wait_for_timeout(1200);c2('#b-feel');pg.evaluate("deskApply({base:'clay',k:{...deskPick(),pullWhole:1}})");pg.evaluate("setMat('jelly')")
        print('pull='+q,pg.evaluate("PULL3.map(k=>mat[k]).join('')"),'三檔鈕',pg.evaluate("document.querySelectorAll('[data-61t],[data-61p]').length"),'畫面含字',pg.evaluate("/pullHold|pullWhole|pullSoft/.test(document.body.innerText+document.getElementById('t-out').value+deskText())"))
    print('版',pg.evaluate("document.title+' '+document.querySelector('.feel-ver').textContent+' '+document.getElementById('brand').innerText"),'errs',errs)
    b.close()
