import re
src=open('C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/shots.py',encoding='utf-8').read()
a=src.index('out={}');src=src[:a]
src+='''
GO="""async cells=>{PB.deep=false;const s0=PB.step,seen={};let cid='';PB.step=(a,v)=>{const r=s0(a,v),q=PB.trace[PB.trace.length-1];if(a==='hold'&&q.nk<.09&&q.nk>.02&&!seen[cid]&&Object.keys(seen).length<4){seen[cid]=q;SH.take('細脖子'+Object.keys(seen).length)}return r};for(const c of cells){if(Object.keys(seen).length>=4)break;PB.trace=[];cid=c.id;PB.run(c)}PB.step=s0;const r=SH.img;r.info=seen;return r}"""
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio']);cx=b.new_context(viewport={'width':393,'height':852},device_scale_factor=2,has_touch=True);cx.add_init_script(INI);pg=cx.new_page();pg.set_default_timeout(0)
    pg.goto('http://127.0.0.1:9100/index.html',wait_until='load');pg.wait_for_timeout(2500);pg.evaluate(open(D+'tool/probe.js',encoding='utf-8').read());pg.evaluate('PB.init()');pg.evaluate(HLP);pg.evaluate('PB.slime(2);PB.over={}')
    r=pg.evaluate(GO,[c for c in cells if c['k']=='pull' and c['dir']!='x']);print(json.dumps(r.pop('info'),ensure_ascii=False));b.close()
srv.shutdown()
for k,v in r.items():
    if isinstance(v,str): open(D+'out/'+k+'.png','wb').write(base64.b64decode(v.split(',')[1]))
'''
exec(compile(src,'neck','exec'))
