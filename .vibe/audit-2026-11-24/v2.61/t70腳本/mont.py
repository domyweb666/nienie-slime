import sys
from PIL import Image
D='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/out/'
n=sys.argv[1];box=tuple(map(int,sys.argv[2].split(',')));k=float(sys.argv[3])
ims=[]
for suf in ('','_norefr','_plain'):
    ims.append([Image.open(D+f'{n}_s{s}{suf}.png').convert('RGB').crop(box) for s in (0,1)])
w,h=ims[0][0].size;w=int(w*k);h=int(h*k)
O=Image.new('RGB',(w*6+50,h),'white')
for j,r in enumerate(ims):
    for i,im in enumerate(r): O.paste(im.resize((w,h),Image.LANCZOS),((j*2+i)*(w+10),0))
O.save(D+'m_'+n+'.png');print(O.size)
