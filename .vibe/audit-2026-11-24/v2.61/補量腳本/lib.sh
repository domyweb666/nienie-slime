cd "$(dirname "$0")"; D=$(pwd -W); S=$(cd ..; pwd -W); N=$S/snap-new/prototype/web; O=$S/snap-v260/prototype/web; W1=$D/w1/prototype/web
PRE="if(typeof GREET!=='undefined')Object.assign(GREET,{st:'',until:-9,at:-9});EYE.user=-9;EYE.gx=0;EYE.gy=0;if('openT' in SLP)SLP.openT=-99;0"
A3='{"pullHold":1}'; A4='{"pullWhole":1}'; A5='{"pullSoft":1}'; ALL='{"pullHold":1,"pullWhole":1,"pullSoft":1}'
# run cells name over web procs extra...
run(){ c=$1;n=$2;o=$3;w=$4;p=$5;shift 5; [ -f out/r_$n.json ] && return; python tool/run.py $c "$D/out/r_$n" --procs $p --port $PORT --src "$w" --over "$o" --pre "$PRE" --nosnap "$@" > out/r_$n.log 2>&1; echo $(date +%T) $n $(tail -1 out/r_$n.log | cut -c1-100) >> out/q.log; }
