#!/usr/bin/env bash
PS=$(command -v ps)
GREP=$(command -v grep)
CUT=$(command -v cut)
NOHUP=$(command  -v nohup)


prog="/Users/zlatko/Business/Business/GitHub/programs_manager_script/test_cmd_1.sh -user=1234 -pass=123"


#echo ${prog}
#echo "ps -ax | grep ${prog} | grep -v grep |  cut -d' ' -f1,10-26"
res=$(eval "${PS} -ax | ${GREP} \"${prog}\" | ${GREP} -v grep |  ${CUT} -d' ' -f1,8-")
echo "${res}"

#exec nohup "${prog}" > /dev/null 2>&1 disown &
#exec ${NOHUP} bash ${prog} &
#cmd="exec nohup \"${prog}\"" > /dev/null 2>&1 & disown"
cmd="exec ${NOHUP} ${prog} > /dev/null 2>&1 & disown"
echo "CMD: " "${cmd}"
eval "${cmd}"
CURRENT_PID=$!
echo "Started ${prog} with pid: ${CURRENT_PID}"

res=$(eval "${PS} -ax | ${GREP} \"${prog}\" | ${GREP} -v grep |  ${CUT} -d' ' -f1,8-")
echo "Result: " "${res}"

#eval "echo ${res} | cut -d' ' -f1,60"

