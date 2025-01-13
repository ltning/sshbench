#!/bin/sh

mode=$1
dest=$2

usage() {
    echo "Usage: ${0} <'connect'|'send'|'receive'> <destination>"
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

case "$mode" in
'connect')
    prefix=''
    command='echo -n'
    ;;
'send')
    prefix='dd if=/dev/zero bs=4k count=256 | '
    command='cat > /dev/null'
    ;;
'receive')
    prefix=''
    command='dd if=/dev/zero bs=4k count=256'
    ;;
*)
    echo "Mode must be one of connect, send, receive"
    usage
    ;;
esac

mkdir -p "$dest"
for m in $(cat macs) ; do
    for c in $(cat ciphers) ; do
        for k in $(cat kex) ; do
            echo
            echo "${dest}/${mode}__${m}__${c}__${k}.log"
            $prefix /usr/bin/time ssh -o MACs=$m -o Ciphers=$c -o KexAlgorithms=$k $dest "${command}" 2>&1 >/dev/null |
                tee -a "${dest}/${mode}__${m}__${c}__${k}.log"
            sleep 0.1 || break
        done
        sleep 0.1 || break
    done
    sleep .01 || break
done

(
    echo 'Mode MAC Cipher KEX Time'
    for f in ${dest}/*.log ; do
        echo -n "$f "
        cut -f 2 -w < $f | awk '{s+=$0}END{print s/NR}' RS=" "
    done | sort -gk 2 | head -10 | tr '_' ' '
) | column -t
