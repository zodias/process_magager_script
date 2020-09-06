#!/usr/bin/env bash

VERSION="1.0"
WORKDIR="/tmp"
FILE_PROGRAMS="$PWD/programs_list.txt";
FILE_PIDS="${WORKDIR}/process_manager_pids.txt"
FILE_TMP_RES="${WORKDIR}/process_manager_tmp_results.txt"
VERBOSE="false"
OPTSPECS="hskrlpcv-:f:w:"

#COMMANDS
START='false'
KILL='false'
RESTART='false'
LIST='false'
PROCESSES='false'
CLEAN='false'

# Commands
PS=$(command -v ps)
GREP=$(command -v grep)
CUT=$(command -v cut)
WC=$(command -v wc)

# Arrays
declare -a PROGRAMS
declare -a PIDS
declare -a PIDS_START

declare -a PROGRAMS_RUNNING_ARRAY
declare -a PROGRAMS_STARTED_ARRAY
declare -a PROGRAMS_NOT_RUNNING_ARRAY=()

declare CURRENT_PROG
declare -i CURRENT_PROG_IS_RUNNING=0
declare -i CURRENT_PROG_PID=0

# Working variables
CURRENT_PID=""

function show_usage()
{
  echo "Version ${VERSION}"
  echo "Usage: ${0} [-h]                        Show this usage help"
  echo "Usage: ${0} [-s] [-f FILE_PROGRAMS] [-w WORKDIR] Start programs"
  echo "Usage: ${0} [-k] [-f FILE_PROGRAMS] [-w WORKDIR] Kill running programs"
  echo "Usage: ${0} [-r] [-f FILE_PROGRAMS] [-w WORKDIR] Restart running programs"
  echo "Usage: ${0} [-l] [-f FILE_PROGRAMS] [-w WORKDIR] List running programs"
  echo "Usage: ${0} [-p] [-f FILE_PROGRAMS] [-w WORKDIR] List running pids"
  echo "Usage: ${0} [-c] [-f FILE_PROGRAMS] [-w WORKDIR] List running pids"
  echo "OPTIONS: "
  echo "-h | --help       Show this usage help"
  echo "-s | --start      Start programs"
  echo "-k | --kill       Kill running programs"
  echo "-r | --restart    Restart programs. Implies ${0} -ks"
  echo "-l | --list       Lists found processes with names that matched provided in the file"
  echo "-p | --processes  List which pids are still running"
  echo "-c | --clean      Clean the file with recorded PIDs"
  echo "-f | --file       File with list of programms to start/kill"
  echo "-w | --workdir    Where to store list of PIDs"
  echo "-v | --verbose    Show work progress on screen"
  echo
  echo "DEFAULTS:"
  echo "WORKDIR=${WORKDIR}"
  echo "FILE_PROGRAMS=${FILE_PROGRAMS}"
  echo "FILE_PIDS=${FILE_PIDS}"
  echo
  echo "EXAMPLES"
}

## Functions
# error trap
function traperr() {
  echo "ERROR: ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
}

function print_files_to_be_used() {
    echo
    echo "Using files and dirs as follows:"
    echo "WORKDIR=${WORKDIR}"
    echo "FILE_PROGRAMS=${FILE_PROGRAMS}"
    echo "FILE_PIDS=${FILE_PIDS}"
    echo
}
function print_desired_actions() {
    if [ ${VERBOSE} == 'true' ]; then
        echo
        echo "Desired actions:"
        echo "START=${START}"
        echo "KILL=${KILL}"
        echo "RESTART=${RESTART}"
        echo "LIST=${LIST}"
        echo "PROCESSES=${PROCESSES}"
        echo "CLEAN=${CLEAN}"
        echo
    fi
}

function print_file_programs() {
    if [ ${START} != 'true' ]; then
        return
    fi

    if [ ${VERBOSE} == 'true' ]; then
        echo
        echo "Programs to execute: "
        for prog in "${PROGRAMS[@]}";
        do
            echo "${prog}"
        done
        echo
    fi
}

function print_file_pids() {
    if [ ${VERBOSE} == 'true' ]; then
        echo
#        echo "Found PIDs: ${PIDS}"
        for pid in "${PIDS[@]}";
        do
            echo "${pid}"
        done
        echo
    fi
}

function read_file_programs() {
    if [ ${VERBOSE} == 'true' ]; then
        echo
        echo "Reading programs from ${FILE_PROGRAMS}"
        echo
    fi
    if [[ -f "$FILE_PROGRAMS" ]]; then
        while IFS= read -r line
        do
            ln=${line}
            PROGRAMS+=("${ln}")
#            echo "Line: ${ln}"
        done < "${FILE_PROGRAMS}"
        else
            echo "Check file or permissions for ${FILE_PROGRAMS}"
    fi
}

function check_which_are_running() {
    echo "Checking running programs"
    declare -a RUNNING
    declare -i key
    declare  -i rows_num
#    echo "${PROGRAMS[@]}"
    for prog in "${PROGRAMS[@]}";
        do
          CURRENT_PROG_IS_RUNNING=0
          echo "===="
#          echo "Program: ${prog}"
            cmd="${PS} -ax | ${GREP} \"${prog}\" | ${GREP} -v grep |  ${CUT} -d' ' -f1,8-"
#            proc=$(eval "${PS} -ax | ${GREP} \"${prog}\" | ${GREP} -v grep |  ${CUT} -d' ' -f2,9-")
#            res=$(eval "${PS} -ax | ${GREP} \"${prog}\" | ${GREP} -v grep |  ${CUT} -d' ' -f1,8-")
            echo "CMD: " "${cmd}"
            res=$(eval "${cmd}" > ${FILE_TMP_RES})
            CURRENT_PROG="${prog}"
            check_and_set_running_proc

#            rows_cmd="echo ${res} | ${CUT} -d \"\n"" -f1 | ${WC} -l"
#            rows_num="$(eval "${row_cmd}")"
#            echo "Rows:" ${rows_num}

#            echo "Res " "${res}"
#            echo "Key $(eval "echo ${res} | ${CUT} -d ' ' -f1")"
#            key="$(eval "echo \"${res}\" | ${CUT} -d ' ' -f1")"
#            echo "Value $(eval "echo \"${res}\" | ${CUT} -d ' ' -f2")"
#            val="$(eval "echo \"${res}\" | ${CUT} -d ' ' -f2")"
#            if [ "${key}" -gt 0 ]; then
#              PROGRAMS_RUNNING_ARRAY[${key}]="${val}";
#              else
#                PROGRAMS_NOT_RUNNING_ARRAY+=("${prog}");
#                echo "NOT RUNNING: " "${prog}";
#            fi

            if [ "${CURRENT_PROG_IS_RUNNING}" -eq 1 ]; then
              PROGRAMS_RUNNING_ARRAY[${CURRENT_PROG_PID}]="${CURRENT_PROG}";
              echo "RUNNING: " "${CURRENT_PROG_PID}" " ${CURRENT_PROG}"
              else
                PROGRAMS_NOT_RUNNING_ARRAY+=("${CURRENT_PROG}");
                echo "NOT RUNNING: " "${CURRENT_PROG}";
            fi
        done;



}

function check_and_set_running_proc() {
#  local RP_ARR
  CURRENT_PROG_IS_RUNNING=0;
  if [[ -f "${FILE_TMP_RES}" ]]; then
          while IFS= read -r line
          do
              ln=$(eval "echo \"${line}\" | ${CUT} -d ' ' -f2-");
              CURRENT_PROG_PID=$(eval "echo \"${line}\" | ${CUT} -d ' ' -f1");
#              RP_ARR+=("${ln}")
              echo "Line: ${ln}"
          if [ "${CURRENT_PROG}" == "${ln}" ]; then
            echo "Matched Prog " "${CURRENT_PROG}"
            CURRENT_PROG_IS_RUNNING=1
            fi
          done < "${FILE_TMP_RES}"
          else
              echo "Check file or permissions for ${FILE_PROGRAMS}"
    fi
}

function prepare_data() {
    echo "Preparing data ..."
    read_file_programs
    check_which_are_running
}

function list() {
        echo "================="
        echo " RUNNING " "${#PROGRAMS_RUNNING_ARRAY[@]}"
        echo "================="

        for key in "${!PROGRAMS_RUNNING_ARRAY[@]}";
        do
          echo "PID:" "${key}" " Program: " "${PROGRAMS_RUNNING_ARRAY[${key}]}";
        done

        echo "================="
        echo " NOT RUNNING " "${#PROGRAMS_NOT_RUNNING_ARRAY[@]}"
        echo "================="

        for not_running in "${PROGRAMS_NOT_RUNNING_ARRAY[@]}";
        do
          echo "Program: " "${not_running}";
        done
}

function kill_programs() {
    echo 'Killing running programs'
    for key in "${!PROGRAMS_RUNNING_ARRAY[@]}";
    do
          echo "Killing PID:" "${key}" " Program: " "${PROGRAMS_RUNNING_ARRAY[${key}]}";
          kill_cmd="kill ${key}"
#          echo "KILL CMD: " "${kill_cmd}"
          $(eval "${kill_cmd}")
          echo "Done"
    done
}

function start_programs() {
    if [ ${VERBOSE} == 'true' ]; then
        echo
        echo "Staring programs from ${FILE_PROGRAMS}"
        echo
    fi
    echo "=== BEGIN ===" >> ${FILE_PIDS}
    for prog in "${PROGRAMS_NOT_RUNNING_ARRAY[@]}";
    do
        cmd="exec ${NOHUP} ${prog} > /dev/null 2>&1 & disown"
#        echo "CMD: " "${cmd}"
        eval "${cmd}"
        CURRENT_PID=$!
#        echo "CPID: " "${CURRENT_PID}"
        PIDS_START+=${CURRENT_PID}
        if [ ${VERBOSE} == 'true' ]; then
            echo "Started ${prog} with pid: ${CURRENT_PID}"
        fi
        echo ${CURRENT_PID} ${prog} >> ${FILE_PIDS}
    done
    echo "=== END ===" >> ${FILE_PIDS}
#    echo "Pids : " ${PIDS_START}
}


## !_Functions

# Process command line arguments
if [ "$#" == "0" ]; then
    show_usage
    exit 1
fi

while getopts ${OPTSPECS} OPTION
do
  case ${OPTION} in
    h)
        show_usage
        ;;
    s)
        START='true'
        ;;
    k)
        KILL='true'
        ;;
    r)
        RESTART='true'
        ;;
    l)
        LIST='true'
        ;;
    p)
        PROCESSES='true'
        ;;
    c)
        CLEAN='true'
        ;;
    v)
      VERBOSE='true'
      echo "Verbose mode ON"
      ;;
    
      # Long options
    -)
       echo "Received long option ${OPTARG}"
       case "${OPTARG}" in
        help)
              show_usage
              ;;
        start)
            START='true'
            ;;
        kill)
            KILL='true'
            ;;
        restart)
            RESTART='true'
            ;;
        list)
            LIST='true'
            ;;
        processes)
            PROCESSES='true'
            ;;
        clean)
            CLEAN='true'
            ;;
        verbose)
            VERBOSE='true'
            echo "Verbose mode ON"
            ;;
       esac
      
  esac
done

# Show what files the script will use
print_files_to_be_used

# Read and preprare prerequisite data
prepare_data

# Show what user wants
print_desired_actions
print_file_programs
print_file_pids

# Execute decision

if [ ${LIST} == 'true' ]; then
    list
fi

if [ ${KILL} == 'true' ]; then
    kill_programs
fi

if [ ${START} == 'true' ]; then
    start_programs
fi

if [ ${RESTART} == 'true' ]; then
    kill_programs
    start_programs
fi


#Say bye
echo '======='
echo ' Done'
echo '======='
#read -r LINE < ${FILE_PROGRAMS}
#
#echo ${LINE}




