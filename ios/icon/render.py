# slime.svg -> PNG：手邊沒有 SVG 轉檔工具，這張圖只有漸層、兩條貝茲路徑、圓、圓角矩形、一條粗線，照 SVG 的數字用 PIL 畫 4 倍再縮小
import sys
from PIL import Image, ImageDraw

SS = 4
N = 1024 * SS


def lerp(a, b, t):
    return a + (b - a) * t


def cubic(p0, p1, p2, p3, n=200):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def quad(p0, p1, p2, n=200):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]))
    return out


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def render(out, size):
    # 背景：上 #3A4C08 到下 #101601 的直向漸層
    top, bot = hexc('#3A4C08'), hexc('#101601')
    col = Image.new('RGB', (1, N))
    px = col.load()
    for y in range(N):
        t = y / (N - 1)
        px[0, y] = tuple(round(lerp(top[k], bot[k], t)) for k in range(3))
    im = col.resize((N, N), Image.NEAREST)
    d = ImageDraw.Draw(im)

    # 史萊姆：translate(512 860) scale(1.05)；深色那片再往下 26
    def T(p, dy=0.0):
        return ((512 + 1.05 * p[0]) * SS, (860 + 1.05 * (p[1] + dy)) * SS)

    blob = cubic((-300, 0), (-300, -270), (-150, -375), (0, -375)) + cubic((0, -375), (150, -375), (300, -270), (300, 0)) + quad((300, 0), (0, 40), (-300, 0))
    d.polygon([T(p, 26) for p in blob], fill=hexc('#8446D6'))
    d.polygon([T(p) for p in blob], fill=hexc('#C690FF'))
    for cx, cy, r in ((-105, -225, 34), (90, -150, 24), (15, -285, 18)):
        x, y = T((cx, cy))
        rr = 1.05 * r * SS
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=hexc('#E2C4FF'))

    # 耳機：粗線（圓頭）＋兩個圓角矩形
    cream = hexc('#F8EAD2')
    band = quad((240, 520), (240, 160), (512, 160)) + quad((512, 160), (784, 160), (784, 520))
    pts = [(x * SS, y * SS) for x, y in band]
    w = 56 * SS
    d.line(pts, fill=cream, width=w, joint='curve')
    for x, y in pts[::4] + [pts[0], pts[-1]]:
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=cream)
    for x in (170, 724):
        d.rounded_rectangle([x * SS, 460 * SS, (x + 130) * SS, (460 + 220) * SS], radius=60 * SS, fill=cream)

    im.resize((size, size), Image.LANCZOS).save(out)


if __name__ == '__main__':
    render(sys.argv[1], int(sys.argv[2]))
    print('ok', sys.argv[1], sys.argv[2])
