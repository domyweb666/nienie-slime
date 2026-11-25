cd "$(dirname "$0")"; bash qF.sh; until grep -q 'T70LONG' out/q.log; do sleep 10; done; bash qA.sh
