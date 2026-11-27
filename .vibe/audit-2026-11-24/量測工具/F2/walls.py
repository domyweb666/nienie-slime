from common import *
from playwright.sync_api import sync_playwright
port=freeport();srv=serve(port)
with sync_playwright() as p:
    b,pg,errs=page(p,port)
    print(pg.evaluate('''()=>{F2.fresh(1,{});const w=worldWalls();return {W,H,R,walls:w,g:{l:SILL.g.l,r:SILL.g.r,fl:SILL.g.fl,sl:SILL.g.sl,sr:SILL.g.sr,U:SILL.g.U}}}'''))
    b.close()
    b,pg,errs=page(p,port,w=430,h=932)
    print(pg.evaluate('''()=>{F2.fresh(1,{});const w=worldWalls();return {W,H,R,walls:w,g:{l:SILL.g.l,r:SILL.g.r,fl:SILL.g.fl}}}'''))
    b.close()
srv.shutdown()
