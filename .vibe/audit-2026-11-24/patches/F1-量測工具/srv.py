import sys,json,os,time,threading,http.server,socketserver,functools
sys.stdout.reconfigure(encoding='utf-8')
CH='C:/Program Files/Google/Chrome/Application/chrome.exe'
class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*x): pass
class SV(socketserver.ThreadingTCPServer):
    allow_reuse_address=True; request_queue_size=256; daemon_threads=True
    def handle_error(self,*x): pass
def serve(webdir,port):
    srv=SV(('127.0.0.1',port),functools.partial(Q,directory=webdir))
    threading.Thread(target=srv.serve_forever,daemon=True).start()
    return srv
