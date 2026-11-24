from PIL import Image
import numpy as np
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/out/'
def go(n,src):
    a,b=[Image.open(D+f'{src}_s{s}_plain.png').convert('RGB') for s in (0,1)]
    d=np.abs(np.asarray(a).astype(int)-np.asarray(b).astype(int)).max(2)
    ys,xs=np.where(d>30);box=(max(0,xs.min()-30),max(0,ys.min()-30),min(786,xs.max()+30),min(1704,ys.max()+30));print(n,box)
    dd=Image.fromarray(np.clip(d*2,0,255).astype('uint8')).convert('RGB')
    w,h=box[2]-box[0],box[3]-box[1];k=1.0
    T=Image.new('RGB',(w,h*3+20),'white')
    for i,im in enumerate((a,b,dd)): T.paste(im.crop(box),(0,i*(h+10)))
    T.save(D+'c_'+n+'.png')
go('two','兩指');go('neck','細脖子4')
