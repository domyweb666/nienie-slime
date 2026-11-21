"""ElevenLabs 音檔接收器（2026-11-21）。內建瀏覽器存不了下載檔，Chrome 按下載鍵又常漏，所以改成：
在 Chrome 的 ElevenLabs 歷史頁攔 URL.createObjectURL 拿到頁面載入的 opus，fetch POST 到這裡存檔。
Chrome 第一次會問「存取區域網路裝置」，要多米按允許。用法：python el_recv.py <輸出資料夾>（聽 127.0.0.1:8799）
頁面端的程式碼見 .vibe/HANDOFF.md「重生音效的流程」。
"""
import http.server, os, re, sys, urllib.parse

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)


class H(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', 'https://elevenlabs.io')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Access-Control-Allow-Private-Network', 'true')

    def do_OPTIONS(self):
        self.send_response(204); self._cors(); self.end_headers()

    def do_GET(self):
        # 收檔頁：只收 https://elevenlabs.io 傳來的訊息 {name, buf}，轉存給自己（同源 POST），再回報
        page = b"""<!doctype html><meta charset=utf-8><title>recv</title><body>waiting
<script>let n=0;addEventListener('message',async e=>{if(e.origin!=='https://elevenlabs.io')return;const {name,buf}=e.data||{};
const r=await fetch('/save?name='+encodeURIComponent(name),{method:'POST',body:buf});n++;document.body.textContent='saved '+n;
e.source.postMessage({ack:name,ok:r.ok},'https://elevenlabs.io')});</script>"""
        self.send_response(200); self.send_header('Content-Type', 'text/html; charset=utf-8'); self.end_headers(); self.wfile.write(page)

    def do_POST(self):
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        name = (q.get('name') or [''])[0]
        if not re.fullmatch(r'[A-Za-z0-9.\-]{1,60}', name) or '..' in name:
            self.send_response(400); self._cors(); self.end_headers(); return
        n = int(self.headers.get('Content-Length', '0'))
        if n <= 0 or n > 5_000_000:
            self.send_response(400); self._cors(); self.end_headers(); return
        data = self.rfile.read(n)
        with open(os.path.join(OUT, name), 'wb') as f:
            f.write(data)
        print('saved', name, len(data), flush=True)
        self.send_response(200); self._cors(); self.end_headers(); self.wfile.write(b'ok')

    def log_message(self, *a):
        pass


http.server.HTTPServer(('127.0.0.1', 8799), H).serve_forever()
