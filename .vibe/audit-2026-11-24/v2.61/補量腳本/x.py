# x.py src port exp.js out.json argjson
import sys,json,os,time
HERE=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,HERE)
from drv import *
from playwright.sync_api import sync_playwright
src,port,exp,out,arg=sys.argv[1],int(sys.argv[2]),sys.argv[3],sys.argv[4],sys.argv[5] if len(sys.argv)>5 else '{}'
rd=lambda f:open(os.path.join(HERE,f),encoding='utf-8').read()
js='const ARG='+arg+';\n'+rd('lib2.js')+'\n'+rd(exp).replace('/*C3LIB*/',rd('c3lib.js'))
srv=serve(src,port);t0=time.time()
with sync_playwright() as p:
    b,pg,errs=page(p,port,'');pg.wait_for_timeout(1500)
    r=pg.evaluate('(async()=>{'+js+'\n})()');b.close()
json.dump(r,open(os.path.join(HERE,out),'w',encoding='utf-8'),ensure_ascii=False)
print(exp,out,arg,'n',len(r),'errs',errs[:3],'secs',round(time.time()-t0),flush=True);srv.shutdown()
