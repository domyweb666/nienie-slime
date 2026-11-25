. "$(dirname "$0")/lib.sh"; export PYTHONIOENCODING=utf-8
python stx.py "$N" 8998 out/t70long.json t70 "pre=window.T70LONG=1" > out/t70long.log 2>&1; echo $(date +%T) T70LONG $(head -1 out/t70long.log | cut -c1-200) >> out/q.log
