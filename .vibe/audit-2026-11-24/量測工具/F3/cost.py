import sys,os
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from vis import evaljs
for x in evaljs(open(os.path.join(HERE,'cost.js'),encoding='utf-8').read(),{}): print(x)
