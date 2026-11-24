# 招牌特效在拉長時的樣子（湯圓 5、布丁 8、珍奶 9、蝶豆 6）：拉 4R 按住、快甩、放手
from common import *
from playwright.sync_api import sync_playwright
import base64,io
from PIL import Image
port=freeport();srv=serve(port)
JS='''([slime,d,n,hold])=>{chooseSlime(slime,false,false);F2.fresh(1,{shine:0,opaque:.9});const c=globalC,bi=F2.edgePt(0.15,-1),[sx,sy]=F2.scr(X[bi]+(c.xc-X[bi])*.25,Y[bi]+(c.yc-Y[bi])*.25);
 if(FX().purple){const [qx,qy]=F2.scr(c.xc-R*.3,c.yc);F2.ev('pointerdown',1,qx,qy);for(let i=0;i<70;i++){F2.ev('pointermove',1,qx+Math.sin(i*.4)*R*.2,qy+Math.cos(i*.3)*R*.1);update(F2.DT)}F2.ev('pointerup',1,qx,qy);for(let i=0;i<10;i++)update(F2.DT)}
 F2.ev('pointerdown',1,sx,sy);for(let i=0;i<4;i++)update(F2.DT);let e=[sx,sy];for(let s=1;s<=n;s++){e=F2.clampS(sx-.2*d*R*s/n,sy-d*R*s/n);F2.ev('pointermove',1,e[0],e[1]);update(F2.DT)}for(let i=0;i<hold;i++)update(F2.DT);draw();
 const k=document.createElement("canvas");k.width=393;k.height=852;k.getContext("2d").drawImage(cv,0,0,393,852);
 // 珍珠有幾顆中心在皮外（路徑外）
 F2.readSkin();let po=0;if(FX().pearls)for(const p of PEARL.list){const [x,y]=F2.scr(p.x,p.y);if(!F2.skin[Math.round(y)*393+Math.round(x)])po++}
 return [k.toDataURL("image/jpeg",.9),SLIMES[slime].name,po,REM.n]}'''
with sync_playwright() as p:
    b,pg,errs=page(p,port);rows=[]
    for sl in (5,8,9,6):
        row=[]
        for d,n,hold in ((0,1,0),(4.5,50,40),(4.5,6,3)):
            r=pg.evaluate(JS,[sl,d,n,hold]);row.append(Image.open(io.BytesIO(base64.b64decode(r[0].split(',')[1]))));print(r[1],d,n,hold,'珍珠在皮外',r[2],'補點',r[3])
        rows.append(row)
    C=Image.new('RGB',(393*3*2,852*2))
    for i,row in enumerate(rows):
        for j,im in enumerate(row): C.paste(im,(((i%2)*3+j)*393,(i//2)*852))
    C.resize((393*3,852)).save(BASE+'/shots/fx.jpg',quality=88)
    print(errs);b.close()
srv.shutdown()
