# usage: shot.py <FZS|P4S|TWO> seed frame outprefix [over json] [extra js file] [web]
from common import *
from playwright.sync_api import sync_playwright
import base64,io
from PIL import Image
DIAG='''()=>{ // 診斷圖：左＝實際畫面；右＝原始遮罩（灰）＋皮（半透明紅）＋外框點＋翻面三角（黃）
 draw();F2.readSkin();F2.readRaw();const W1=F2.W1,H1=F2.H1;const k=document.createElement('canvas');k.width=W1*2;k.height=H1*2;const g=k.getContext('2d');g.fillStyle='#fff';g.fillRect(0,0,k.width,k.height);
 const im=g.createImageData(W1,H1);for(let i=0;i<W1*H1;i++){const r=F2.raw[i],s=F2.skin[i];let c=[255,255,255];if(r&&s)c=[200,200,205];else if(r&&!s)c=[255,90,70];else if(!r&&s)c=[90,160,255];im.data[4*i]=c[0];im.data[4*i+1]=c[1];im.data[4*i+2]=c[2];im.data[4*i+3]=255}
 const t1=document.createElement('canvas');t1.width=W1;t1.height=H1;t1.getContext('2d').putImageData(im,0,0);g.imageSmoothingEnabled=false;g.drawImage(t1,0,0,W1*2,H1*2);
 const S=p=>{const q=F2.scr(p[0],p[1]);return[q[0]*2,q[1]*2]};
 g.lineWidth=.6;g.strokeStyle='rgba(0,0,0,.18)';for(let e=0;e<EDG.length;e+=2){const a=S([X[EDG[e]],Y[EDG[e]]]),b=S([X[EDG[e+1]],Y[EDG[e+1]]]);g.beginPath();g.moveTo(a[0],a[1]);g.lineTo(b[0],b[1]);g.stroke()}
 for(let q=0;q<TRI.length;q+=3){const a=TRI[q],b=TRI[q+1],c=TRI[q+2];if(.5*((X[b]-X[a])*(Y[c]-Y[a])-(Y[b]-Y[a])*(X[c]-X[a]))<-.02*TRA[q/3]){const A=S([X[a],Y[a]]),B=S([X[b],Y[b]]),C=S([X[c],Y[c]]);g.fillStyle='rgba(255,200,0,.45)';g.beginPath();g.moveTo(A[0],A[1]);g.lineTo(B[0],B[1]);g.lineTo(C[0],C[1]);g.fill()}}
 g.lineWidth=1.6;g.strokeStyle='#0a0';g.beginPath();bnd.forEach((i,n)=>{const a=S([X[i],Y[i]]);n?g.lineTo(a[0],a[1]):g.moveTo(a[0],a[1])});g.closePath();g.stroke();
 for(const f of fingers.values()){const a=[f.sx*2,f.sy*2];g.strokeStyle='#f0f';g.lineWidth=3;g.beginPath();g.arc(a[0],a[1],14,0,7);g.stroke()}
 return k.toDataURL('image/png')}'''
def main():
    fn,seed,frame,out=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4]
    over=json.loads(sys.argv[5]) if len(sys.argv)>5 and sys.argv[5] else {}
    extra=open(sys.argv[6],encoding='utf-8').read() if len(sys.argv)>6 and sys.argv[6]!='-' else None
    web=sys.argv[7] if len(sys.argv)>7 else WEB
    port=freeport();srv=serve(port,web)
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        if extra: pg.evaluate(extra)
        pg.evaluate(open(BASE+'/tools/fzskin.js',encoding='utf-8').read())
        pg.evaluate("()=>{document.getElementById('hint').style.display='none';document.getElementById('view').style.display='none';document.getElementById('brand')&&(document.getElementById('brand').style.display='none')}")
        pg.evaluate('''async ([fn,seed,frame,over])=>{await window[fn]({seeds:[seed],over,stopAt:[seed,frame]})}''',[fn,seed,frame,over])
        m=pg.evaluate('()=>{const m=F2.measure();return m}');print(fn,seed,frame,fmt(m))
        pg.evaluate('()=>{draw()}')
        pg.screenshot(path=out+'_a.png')
        d=pg.evaluate(DIAG);open(out+'_b.png','wb').write(base64.b64decode(d.split(',')[1]))
        b.close()
    A=Image.open(out+'_a.png').convert('RGB');B=Image.open(out+'_b.png').convert('RGB').resize(A.size)
    C=Image.new('RGB',(A.width*2,A.height));C.paste(A,(0,0));C.paste(B,(A.width,0));C=C.resize((C.width//2,C.height//2));C.save(out+'.png');os.remove(out+'_b.png')
    srv.shutdown()
main()
