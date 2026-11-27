from PIL import Image,ImageDraw,ImageFont
import numpy as np
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/out/'
O='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/.vibe/audit-2026-11-24/v2.61/'
F=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',24)
for nm,src in (("外框打結","細脖子2"),):
    a,b=[Image.open(D+f'{src}_s{s}.png').convert('RGB') for s in (0,1)]
    d=np.abs(np.asarray(a).astype(int)-np.asarray(b).astype(int)).max(2)
    ys,xs=np.where(d>8);print(nm,'差>8的像素',len(ys),'占畫面%.2f%%'%(100*len(ys)/d.size),'最大差',d.max(),'範圍',(xs.min(),ys.min(),xs.max(),ys.max()) if len(ys) else None,'差>40',(d>40).sum())
    pa,pb=[Image.open(D+f'{src}_s{s}_plain.png').convert('RGB') for s in (0,1)]
    dp=np.abs(np.asarray(pa).astype(int)-np.asarray(pb).astype(int)).max(2);print('   單色背景 差>8',(dp>8).sum(),'最大',dp.max())
    c=[('舊皮 skinU 0',a),('新皮 skinU 1',b),('新皮，背景換單色',pb)]
    w,h=a.size;T=Image.new('RGB',(w*3+40,h+50),'white');dr=ImageDraw.Draw(T)
    for i,(t,im) in enumerate(c): T.paste(im,(i*(w+20),50));dr.text((i*(w+20)+10,8),nm+'  '+t,fill='black',font=F)
    T=T.crop((0,0,T.size[0],50+1400));T.save(O+'皮-新舊並排-'+nm+'.png')
    Image.fromarray((np.clip(d*4,0,255)).astype('uint8')).save(D+'diff_'+nm+'.png')
# 放大尖端
a,b=[Image.open(D+f'拉遠_s{s}.png').convert('RGB').crop((560,470,740,740)).resize((540,810),Image.LANCZOS) for s in (0,1)]
T=Image.new('RGB',(1640,810),'white');T.paste(a,(0,0));T.paste(b,(550,0));p=Image.open(D+'拉遠_s1_plain.png').convert('RGB').crop((560,470,740,740)).resize((540,810),Image.LANCZOS);T.paste(p,(1100,0));T.save(D+'tip.png')
