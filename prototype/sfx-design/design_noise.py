"""捏捏史萊姆的白噪音背景（2026-11-19，多米：Higgsfield 生的白噪音不對，改成程式在本機合成）。

做法：在頻域直接畫出想要的頻譜，再做一次反傅立葉轉換。這樣出來的雜訊本身就是週期性的，
頭接尾完全沒有接縫，不用交叉淡化。左右聲道各自一組亂數，聽起來比較寬。

三種顏色先做出來給多米試聽：
  white：白噪音，所有頻率一樣大，4.5 kHz 以上慢慢往下收（純白噪音在手機上很刺）
  pink ：粉紅噪音，頻率每高一倍小 3 dB，像下雨、像遠處的瀑布
  brown：棕噪音，頻率每高一倍小 6 dB，像低沉的風、像飛機艙；手機喇叭 300 Hz 以下出不來，用手機聽會很小聲

輸出格式跟 make_ambience.py 的 bed 一樣（120 秒一輪、頭尾各墊 1 秒、−26 dB RMS），選定後可以直接接進 amb.json。
用法：python design_noise.py            → 試聽檔寫到 prototype/sfx-design/preview/noise-<顏色>.m4a
      python design_noise.py --web [--ios] → 寫 amb-noise-<顏色>-bed.m4a 到 prototype/web/sfx/（與 ios/NieNie/Resources/）
每次結果都一樣（固定亂數種子）。
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy.io import wavfile

sys.stdout.reconfigure(encoding='utf-8')
SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PREVIEW = os.path.join(HERE, 'preview')
WEB = os.path.join(ROOT, 'prototype', 'web', 'sfx')
IOS = os.path.join(ROOT, 'ios', 'NieNie', 'Resources')

BED_LEN = 120.0   # 秒，跟雨、柴火一樣
PAD = 1.0         # AAC 頭尾墊的秒數（播放端只循環 PAD 到 PAD+LOOP）
TARGET_DB = -26.0 # 跟雨的底一樣大聲
HP = 40.0         # 40 Hz 以下拿掉（聽不到，只會吃音量）

COLORS = {
    # 名稱：(每高一倍降幾 dB, 高頻開始收的頻率, 說明)
    'white': (0.0, 4500.0, '白噪音（高頻收過）'),
    'pink': (3.0, 9000.0, '粉紅噪音'),
    'brown': (6.0, 0.0, '棕噪音'),
}


def shaped_noise(n, slope_db, lp_hz, rng):
    """長度 n 的週期性雜訊：頻域每個頻率給隨機相位、照斜率給大小。"""
    f = np.fft.rfftfreq(n, 1 / SR)
    mag = np.zeros_like(f)
    ok = f > 0
    mag[ok] = (f[ok] / 1000.0) ** (-slope_db / 20 / np.log10(2))   # 每高一倍降 slope_db
    mag *= 1 / np.sqrt(1 + (HP / np.maximum(f, 1e-9)) ** 8)        # 四階高通
    if lp_hz:
        mag *= 1 / np.sqrt(1 + (f / lp_hz) ** 4)                    # 二階低通，慢慢收
    phase = rng.uniform(0, 2 * np.pi, len(f))
    spec = mag * np.exp(1j * phase)
    spec[0] = 0
    x = np.fft.irfft(spec, n)
    return x / np.sqrt(np.mean(x ** 2))


def db(x):
    return 20 * np.log10(np.maximum(x, 1e-12))


def band_share(x, lo):
    """lo Hz 以上的能量佔幾成（手機喇叭大概 300 Hz 以上才出得來）。"""
    m = x.mean(axis=1)
    p = np.abs(np.fft.rfft(m)) ** 2
    f = np.fft.rfftfreq(len(m), 1 / SR)
    return float(p[f >= lo].sum() / p.sum())


def make(color, seed):
    slope, lp_hz, _ = COLORS[color]
    rng = np.random.default_rng(seed)
    n = int(BED_LEN * SR)
    x = np.stack([shaped_noise(n, slope, lp_hz, rng) for _ in range(2)], axis=1)
    x *= 10 ** (TARGET_DB / 20)
    return x


def write_m4a(path, x, kbps=160):
    with tempfile.TemporaryDirectory() as td:
        w = os.path.join(td, 'a.wav')
        wavfile.write(w, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'aac', '-b:a', f'{kbps}k', path], check=True)


def main():
    web = '--web' in sys.argv
    outs = ([WEB] + ([IOS] if '--ios' in sys.argv else [])) if web else [PREVIEW]
    for k, color in enumerate(COLORS):
        x = make(color, 20261119 + k)
        p = int(PAD * SR)
        padded = np.concatenate([x[-p:], x, x[:p]])
        # 接縫檢查：尾巴最後一個樣本到開頭第一個樣本的跳動，跟一般相鄰樣本的跳動比
        jump = np.abs(x[0] - x[-1]).max()
        typical = np.percentile(np.abs(np.diff(x, axis=0)), 99)
        rms_db = db(np.sqrt(np.mean(x ** 2)))
        peak_db = db(np.abs(x).max())
        print('%-5s %s：RMS %.1f dB、峰值 %.1f dB、300 Hz 以上佔 %.0f%%、接縫跳動 %.4f（一般相鄰樣本 99%% 在 %.4f 以內）' % (
            color, COLORS[color][2], rms_db, peak_db, 100 * band_share(x, 300), jump, typical))
        for d in outs:
            name = ('amb-noise-%s-bed.m4a' % color) if web else ('noise-%s.m4a' % color)
            write_m4a(os.path.join(d, name), padded if web else x)
    print('寫到', '、'.join(outs))


if __name__ == '__main__':
    main()
