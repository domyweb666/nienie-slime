"""揉的循環對抓著時的雨（v2.61 B1 驗收，2026-11-25）。只讀不寫。

公式同 .vibe/audit-2026-11-24/整理-即時回饋.md 第 1 條（腳本前身是 量測工具/F3/mask.py）：均方比均方、350 Hz 四階高通當手機喇叭、
揉的音量 0.7 × 手速、低通 1400 + 2600n、總音量 0.9；雨 0.25 × 1.6 × 抓著時的比例。雨的兩聲道取平均能量（這樣算出來的舊檔是
−35／−28／−20／−10，跟稽核一致）；四檔各算一次再平均 dB。沒算播放時的變速（±6%），真機喇叭要實聽。
用法：python measure_rub.py
"""
import os
import subprocess
import sys

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, resample_poly, sosfilt

sys.stdout.reconfigure(encoding='utf-8')
SR = 48000
RES = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'ios', 'NieNie', 'Resources')
SPEEDS = (60, 120, 240, 600)   # 點／秒
R_PT = 106.1
SPK = butter(4, 350, 'high', fs=SR, output='sos')


def db(v):
    return 20 * np.log10(np.maximum(v, 1e-12))


def rms(x):
    return np.sqrt((x ** 2).mean())


def rain_db():
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', os.path.join(RES, 'amb-rain-bed.m4a'), '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'],
                       capture_output=True, check=True)
    x = np.frombuffer(r.stdout, np.float32).astype(float).reshape(-1, 2)[SR:SR * 61] * 0.25 * 1.6
    return db(rms(sosfilt(SPK, x, axis=0)))


def rub_db(x44):
    x = np.tile(resample_poly(x44, 160, 147), 3)   # 繞三圈取中間那圈，濾波器的頭不算
    n0 = len(x) // 3
    out = []
    for v in SPEEDS:
        n = min(1, v / R_PT / 5)
        y = sosfilt(SPK, sosfilt(butter(2, 1400 + 2600 * n, 'low', fs=SR, output='sos'), x))[n0:2 * n0]
        out.append(db(rms(y * 0.7 * n * 0.9)))
    return np.array(out)


def stats(x):
    n = len(x) // 441
    e = db(np.sqrt((x[:n * 441].reshape(n, 441) ** 2).mean(axis=1)))
    tp = db(np.abs(resample_poly(np.tile(x, 2), 4, 1)).max())
    return '峰值 %.1f（重取樣真峰值 %.1f） RMS %.1f 最尖 10 毫秒對中位 %.1f 超過 −35 的時間 %.0f%%　接縫差 %.4f（檔內相鄰差 99 百分位 %.4f）' % (
        db(np.abs(x).max()), tp, db(rms(x)), e.max() - np.median(e), 100 * (e > -35).mean(), abs(x[0] - x[-1]), np.percentile(np.abs(np.diff(x)), 99))


def main():
    load = lambda tag: [wavfile.read(os.path.join(RES, 'ai-rub-%s-%02d.wav' % (tag, i)))[1] / 32768.0 for i in range(1, 5)]
    rain, S = rain_db(), {'舊': load('loop'), '新': load('loop61')}
    L = {k: np.array([rub_db(x) for x in v]) for k, v in S.items()}
    for k in S:
        for i, x in enumerate(S[k]):
            print('%s %02d %s' % (k, i + 1, stats(x)))
    print('手速 %s 點／秒，揉比雨（dB）' % '／'.join(map(str, SPEEDS)))
    for k in S:
        for d in (0.6, 0.3):
            print('%s檔 雨 %.1f：%s' % (k, d, np.round((L[k] - rain - db(d)).mean(axis=0), 1)))
    up = L['新'] - db(0.3) - L['舊'] + db(0.6)
    print('新檔雨 0.3 比 舊檔雨 0.6：', np.round(up.mean(axis=0), 1))
    for i, r in enumerate(up):
        print('  %02d' % (i + 1), np.round(r, 1))


if __name__ == '__main__':
    main()
