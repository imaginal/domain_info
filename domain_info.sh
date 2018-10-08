#!/bin/bash

init_dir()
{
	t=$1-`date +%Y%m%d-%H%M%S`
	mkdir $t && cd $t || exit 1
}

save_myip()
{
    curl -s https://httpbin.org/ip -o myip-httpbin.json
    curl -s https://api.ipify.org/ -o myip-ipify.txt
}

save_trace()
{
    traceroute $1 > $1-traceroute.txt 2>&1
}

save_whois()
{
    whois $1 > $1-whois.txt
    P=${1#*.}
    grep -q $1 $1-whois.txt || whois $P > $P-whois.txt
}

save_ns()
{
    dig +short $1 ns > $1-ns.txt
    grep -q $1 $1-whois.txt && awk 'BEGIN{ds=0} {
    if(tolower($0)~/'$1'/){ds=1}
    ns=""
    if($1~/Name/ && $2~/Server/){ns=$3}
    if($1~/nserver/){ns=$2}
    if(ds && ns){print ns}
    }' $1-whois.txt >> $1-ns.txt
}

save_ns_info()
{
    for d in `sort -dfu $1-ns.txt`
    do
        d=${d%.}
        p=${d#*.}
        if [[ $d == *GTLD-SERVERS.NET ]]
        then
            continue
        fi
        if [ -f ns-$d-dig.txt ]
        then
            continue
        fi
        whois $p > ns-$p-whois.txt
        dig $d any > ns-$d-dig.txt
        nslookup -debug $d > ns-$d-nslookup.txt
        nslookup -type=soa -debug $d >> ns-$d-nslookup.txt

        for i in `dig +short $d`
        do
            whois $i > ns-$d-$i-whois.txt
        done

        dig @$d +all $1 any > dig-$1-from-$d.txt
    done
}

save_ip()
{
    dig +all $1 any > $1-dig.txt
    nslookup -debug $1 > $1-nslookup.txt
    nslookup -debug -type=soa $1 >> $1-nslookup.txt
}

save_cert()
{
    echo -e "GET / HTTP/1.0\r\n\r\n" | openssl s_client -connect $1:443 \
        -prexit -debug -showcerts -msg -state -status >$1-cert.txt 2>&1
}

save_doc()
{
    curl -s -v -L $1 -o $1-source-curl.txt 2>$1-headers-curl.txt
    wget -q -S $1 -O $1-source-wget.txt 2>$1-headers-wget.txt
}

save_assets()
{
    UA="Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    p=${1#*.}
    mkdir page_with_assets && cd page_with_assets
    wget -U "$UA" -q --no-clobber --page-requisites --domains www.$1,$1,$p $1
}

init_dir $1
save_myip $1
save_trace $1
save_trace google.com
save_whois $1
save_ns $1
save_ns_info $1
save_ip $1
save_cert $1
save_doc $1
save_assets $1

