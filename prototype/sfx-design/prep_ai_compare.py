"""把 Higgsfield（Mirelo SFX）生的史萊姆音效整理成可以跟現有合成音並排試聽的版本（2026-11-19）。

原始檔在專案外面 `E:\\捏捏史萊姆\\素材\\higgsfield\\slime\\`（00 到 18，mp3，各 3 到 4 秒）。
AI 生的音量差很多（峰值從 −0.5 到 −35 dB 都有），直接跟合成音比會被音量騙，所以這支：
  1. 量每段的峰值、RMS、有聲音的長度（比峰值小 40 dB 以內的部分）
  2. 頭尾的空白剪掉（留 30 毫秒），尾巴 80 毫秒淡出
  3. 峰值拉到 −12 dB（跟 v3 合成音的峰值上限一樣）
  4. 寫成 mp3 到 prototype/web/sfx/ai/，試聽頁 prototype/web/sfx/compare-ai.html 讀它
這一步只是試聽用，還沒切成 app 用的一顆一顆短音。
用法：python prep_ai_compare.py [--src 素材資料夾]
"""
import json
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
OUT = os.path.join(ROOT, 'prototype', 'web', 'sfx', 'ai')
SRC = os.path.join(os.path.dirname(ROOT), '素材', 'higgsfield', 'slime')
PEAK_DB = -12.0


def load(path):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '1', '-ar', str(SR), '-'],
                       capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float32).astype(np.float64)


def db(x):
    return 20 * np.log10(np.maximum(x, 1e-12))


def main():
    src = SRC
    if '--src' in sys.argv:
        src = sys.argv[sys.argv.index('--src') + 1]
    out = OUT
    if '--out' in sys.argv:   # 11-21：ElevenLabs 那批寫到 sfx/el/（--src 素材/elevenlabs/slime/_opus --out ../web/sfx/el）
        out = os.path.abspath(sys.argv[sys.argv.index('--out') + 1])
    os.makedirs(out, exist_ok=True)
    info = {}
    for name in sorted(os.listdir(src)):
        if not name.endswith(('.mp3', '.opus')):
            continue
        x = load(os.path.join(src, name))
        pk = np.max(np.abs(x))
        hop = int(0.01 * SR)
        n = len(x) // hop
        env = np.sqrt((x[:n * hop].reshape(n, hop) ** 2).mean(axis=1))
        on = np.where(db(env) > db(pk) - 40)[0]
        a = max(0, on[0] * hop - int(0.03 * SR))
        b = min(len(x), (on[-1] + 1) * hop + int(0.03 * SR))
        y = x[a:b].copy()
        fo = min(len(y), int(0.08 * SR))
        y[-fo:] *= np.linspace(1, 0, fo) ** 2
        gain = PEAK_DB - db(pk)
        y *= 10 ** (gain / 20)
        stem = os.path.splitext(name)[0]
        with tempfile.TemporaryDirectory() as td:
            w = os.path.join(td, 'a.wav')
            wavfile.write(w, SR, (np.clip(y, -1, 1) * 32767).astype(np.int16))
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', w, '-c:a', 'libmp3lame', '-b:a', '128k',
                            os.path.join(out, stem + '.mp3')], check=True)
        info[stem] = {'peak_db': round(float(db(pk)), 1), 'rms_db': round(float(db(np.sqrt(np.mean(x ** 2)))), 1),
                      'active_s': round((b - a) / SR, 2), 'gain_db': round(float(gain), 1)}
        print('%-20s 原峰值 %6.1f dB、RMS %6.1f dB、有聲音 %.2f 秒、放大 %+5.1f dB' % (
            stem, info[stem]['peak_db'], info[stem]['rms_db'], info[stem]['active_s'], gain))
    with open(os.path.join(out, 'ai.json'), 'w', encoding='utf-8') as f:
        json.dump(info, f, ensure_ascii=False, indent=1)
    print('寫到', out)


if __name__ == '__main__':
    main()
