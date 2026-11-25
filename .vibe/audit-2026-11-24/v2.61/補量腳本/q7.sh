. "$(dirname "$0")/lib.sh"; PORT=8997
r7(){ n=$1;o=$2;w=$3;sn=$4; [ -f out/r_i7_$n.json ] && return; python tool/run.py c7.json "$D/out/r_i7_$n" --procs ${PR:-4} --batch 1 --port $PORT --src "$w" --over "$o" --pre "$PRE" $sn > out/r_i7_$n.log 2>&1; echo $(date +%T) i7_$n $(tail -1 out/r_i7_$n.log | cut -c1-100) >> out/q.log; }
r7 def '{}' "$N" ""
r7 w1 '{}' "$W1" ""
r7 all "$ALL" "$N" ""
r7 v260 '{}' "$O" --nosnap
r7 off23 '{"rough":0,"tapSoft":0,"petSlow":0,"wakeSoft":0,"nearFast":0,"greetLook":0,"brJit":0,"bumpSoft":0,"eyeTrue":0,"snd61":0}' "$N" --nosnap
for k in rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61; do r7 no_$k "{\"$k\":0}" "$N" --nosnap; done
echo Q7 >> out/q.log
