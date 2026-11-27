import json,base64,io,sys
from PIL import Image,ImageDraw,ImageFont
o=json.load(open('e10.json',encoding='utf-8'))
f=ImageFont.truetype('C:/Windows/Fonts/msjh.ttc',22)
n=len(o);cols=4;rows=-(-n//cols)
W,H=393,330
im=Image.new('RGB',(W*cols,(H+32)*rows),'white');d=ImageDraw.Draw(im)
for i,(nm,u) in enumerate(o):
    a=Image.open(io.BytesIO(base64.b64decode(u.split(',')[1]))).convert('RGB')
    x=(i%cols)*W;y=(i//cols)*(H+32);im.paste(a,(x,y+32));d.text((x+8,y+3),nm,fill='black',font=f)
im=im.resize((im.width*3//4,im.height*3//4));im.save('states.png');print(im.size)
