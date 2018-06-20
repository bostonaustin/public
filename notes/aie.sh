#!/bin/bash

# set -x

# wrapper for AIE Manager to give nodes more time to properly restart

validNodes=('adm' 'idxlib1a' 'idxlib1b' 'idxlib1c' 'idxlib1d' 'idxlib1e' 'idxlib1f' 'idxlib2a' \
'idxlib2b' 'idxlib2c' 'idxlib2d' 'idxlib2e' 'idxlib2f' 'srclib1a' 'srclib1b' 'srclib1c' 'srclib1d' 'srclib1e' 'srclib1f' '\
srclib1g' 'srclib1h' 'srclib1i' 'srclib1j' 'srclib1k' 'srclib1l' 'srclib2a' 'srclib2b' 'srclib2c' 'srclib2d' '\
srclib2e' 'srclib2f' 'srclib2g' 'srclib2h' 'srclib2i' 'srclib2j' 'srclib2k' 'srclib2l' 'telib1' 'telib2' '\
perfmon' 'store' 'null')

row1Index=('idxlib1a' 'idxlib1b' 'idxlib1c' 'idxlib1d' 'idxlib1e' 'idxlib1f)
row1Search=(srclib1a' 'srclib1b' 'srclib1c' 'srclib1d' 'srclib1e' 'srclib1f' \
'srclib1g' 'srclib1h' 'srclib1i' 'srclib1j' 'srclib1k' 'srclib1l')

row2Index=('idxlib2a' 'idxlib2b' 'idxlib2c' 'idxlib2d' 'idxlib2e' 'idxlib2f')

row2Search=('srclib2a' 'srclib2b' 'srclib2c' 'srclib2d' 'srclib2e' 'srclib2f' \
'srclib2g' 'srclib2h' 'srclib2i' 'srclib2j' 'srclib2k' 'srclib2l')

admte=('adm' 'telib1' 'telib2')

test=('srclib1f' 'idxlib1f' 'srclib2f' 'idxlib2f')

function run_that {
   case ${target} in
        admte )
            for node in ${admte[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            ;;
        row1 )
            for node in ${row1Index[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            for node in ${row1Search@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            ;;
        row2 )
            for node in ${row2Index[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            for node in ${row2Search[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            ;;
        all )
            for node in ${validNodes[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            ;;
        test )
            for node in ${test[@]}; do
                /home/de636162/austin_aie_manager.py -c ${action} -n ${node}
                sleep 90
            done
            ;;
        \? )
            #echo "something else horribly wrong there ${1} and ${2} ... die"
            usage
            exit 1
            ;;
    esac
}

function usage {
            echo "Usage: ./aie [action] [target] "
            echo "    ./aie -h                       # displays this helpful message"
            echo "    ./aie restart admte            # restart all the TE nodes plus the ADM console"
            echo "    ./aie stop row1                # restart all the ROW1 nodes searchers + indexers"
            echo "    ./aie status                   # restart all the nodes in the cluster"
            echo "    ./aie start all                # restart all the ROW1 nodes searchers + indexers"
}


action="${1}"
target="${2}"


case "${action:-status}" in
    status )
        /home/de636162/austin_aie_manager.py
        exit 0
        ;;
    restart )
        run_that
        ;;
    start )
        run_that
        ;;
    stop )
        run_that
        ;;
    \? )
        usage
        exit 1
        ;;
esac


# DEBUG
# echo "${action} is the action and ${target} is the target"