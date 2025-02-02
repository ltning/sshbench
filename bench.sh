#!/bin/sh
# shellcheck disable=SC3000-SC4000

mode=$1
dest=$2

usage() {
    echo "Usage: ${0} <mode> <destination> [show [<number>]|<iterations>]"
    echo
    echo "Mode is one of 'connect', 'send' or 'receive'."
    echo
    echo "Destination is a host name or IP, optionally prefixed by username@."
    echo
    echo "If 'show' is given, benchmarking is skipped and existing results are shown."
    echo "The optional <number> specifies how many of the results are shown; by"
    echo "default only the top 10 fastest are displayed."
    echo
    echo "Alternatively, if instead of 'show' a number is given for <iterations>,"
    echo "the benchmark is run that many times before showing the results. The"
    echo "<number> can in this case not be overridden."
    echo
    echo "Results shown are an average of all collected results for the given host/mode."
    exit
}

if [ ! "$mode" ] ; then
    echo 'Mode not specified!'
    usage
fi

if [ ! "$dest" ] ; then
    echo 'Dest not specified!'
    usage
fi

kex=$(ssh -Q kex|grep -Ev -- '-(group-exchange|sha1|sha512|md5|nistp[^2])')
if [ -f "kex.lst" ] ; then
    kex=$(cat kex.lst)
fi

macs=$(ssh -Q macs|grep -Ev -- '-(sha1|512|md5)')
if [ -f "macs.lst" ] ; then
    macs=$(cat macs.lst)
fi

ciphers=$(ssh -Q cipher | grep -Ev -- '(3des|aes1[^2]|aes2)')
if [ -f "ciphers.lst" ] ; then
    ciphers=$(cat ciphers.lst)
fi

case "$mode" in
'connect')
    prefix=''
    command='echo -n'
    ;;
'send')
    prefix='dd if=/dev/zero bs=4k count=2048'
    command='cat > /dev/null'
    ;;
'receive')
    prefix=''
    command='dd if=/dev/zero bs=4k count=2048'
    ;;
*)
    echo "Mode must be one of connect, send, receive"
    usage
    ;;
esac

showstats() {
    local _dest="$1"
    local _mode="$2"
    local _top="$3"
    local f

    local headcmd="head -10"
    if [ "${_top}" ] ; then
        if top=$(echo "${_top}" | grep -Ev '[^0-9]' | grep -E '[0-9]') ; then
            headcmd="head -${top}"
        elif [ "${_top}" = 'all' ] ; then
            headcmd="cat"
        else
            echo "Could not decipher number of lines to show (${_top}); ignoring"
        fi
    fi

    if [ -d "$_dest" ] ; then
        (
            echo 'Destination Mode MAC Cipher KEX Time'
            for f in "${_dest}"/"${_mode}"__*.log ; do
                echo -n "$f " | sed -e 's/\.log//' -e 's/\// /'
                cut -f 2 -w < "$f" | awk '{s+=$0}END{print s/NR}' RS=" "
            done | sort -gk 3 | $headcmd | tr '_' ' '
        ) | column -t
    else
        echo "${_dest} directory not found!"
    fi
}

runbench() {
    mkdir -p "$dest"
    for m in $macs ; do
        for c in $ciphers ; do
            for k in $kex ; do
                echo
                echo "${dest}/${mode}__${m}__${c}__${k}.log"
                if [ "$prefix" ] ; then
                    $prefix 2>/dev/null | /usr/bin/time ssh -o MACs="$m" -o Ciphers="$c" -o KexAlgorithms="$k" "$dest" "${command} 2>/dev/null" 2>&1 >/dev/null |
                        tee -a "${dest}/${mode}__${m}__${c}__${k}.log"
                else
                    /usr/bin/time ssh -o MACs="$m" -o Ciphers="$c" -o KexAlgorithms="$k" "$dest" "${command} 2>/dev/null" 2>&1 >/dev/null |
                        tee -a "${dest}/${mode}__${m}__${c}__${k}.log"
                fi
                sleep 0.1 || break
            done
            sleep 0.1 || break
        done
        sleep .01 || break
    done
}

if ! [ "$3" = 'show' ] ; then
    if iterations=$(echo "$3" | grep -Ev '[^0-9]' | grep -E '[0-9]') ; then
        for i in $(jot -n "$iterations") ; do
            echo "Executing iteration $i of $iterations .."
            runbench
        done
    else
        runbench
    fi
fi
showstats "$dest" "$mode" "$4"
