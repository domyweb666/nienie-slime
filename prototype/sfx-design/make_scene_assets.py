# 把多米生的窗台素材處理成網頁版用的檔案（綠幕去背、道具去背、壓縮）
# 用法：python -I make_scene_assets.py <素材資料夾> <輸出資料夾>
import os
import sys

import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)


def key_green(im):
    a = np.array(im.convert('RGBA')).astype(np.int32)
    ex = a[..., 1] - np.maximum(a[..., 0], a[..., 2])
    al = np.clip(255 - (ex - 40) * 3, 0, 255)
    spill = ex > 40
    a[..., 1] = np.where(spill, np.maximum(a[..., 0], a[..., 2]), a[..., 1])
    a[..., 3] = al
    return Image.fromarray(a.astype(np.uint8), 'RGBA')


def key_bg(im, box, lo=12):
    a = np.array(im.crop(box).convert('RGBA')).astype(np.int32)
    d = np.sqrt(((a[..., :3] - np.array([237, 232, 228])) ** 2).sum(-1))
    a[..., 3] = np.clip((d - lo) / 14, 0, 1) * 255
    # 只留最大的一塊會太麻煩，這裡靠裁切範圍避開其他物件；貼齊內容再存
    img = Image.fromarray(a.astype(np.uint8), 'RGBA')
    return img.crop(img.getchannel('A').point(lambda v: 255 if v > 24 else 0).getbbox())


plate = key_green(Image.open(os.path.join(src, '極簡奶油牆面綠色窗景.png')))
plate.save(os.path.join(out, 'plate.webp'), quality=88, method=6)
props = Image.open(os.path.join(src, '極簡陶器與多肉盆栽靜物.png'))
for name, box, w, lo in [('bowl', (225, 235, 725, 590), 420, 34), ('succ', (915, 140, 1245, 590), 220, 12), ('peb', (1465, 260, 1935, 580), 240, 12)]:
    p = key_bg(props, box, lo)   # 碗跟底色差很多，門檻拉高才不會留一圈白邊；盆子是米色，太高會吃掉
    p = p.resize((w, round(p.height * w / p.width)), Image.LANCZOS)
    p.save(os.path.join(out, name + '.webp'), quality=88, method=6)
for f in sorted(os.listdir(out)):
    i = Image.open(os.path.join(out, f))
    print(f, i.size, os.path.getsize(os.path.join(out, f)))
