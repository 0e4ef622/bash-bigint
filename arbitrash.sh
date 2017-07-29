ap_num() { # use to make a negative bigint since i dont use two's complement
    local n=$1;
    [ $n -lt 0 ] && (( n = (~n + 1) ^ (1 << 63) ));
    echo $n;
}

_ap_add() {
    eval local l1='${#'$1'[@]}';
    eval local l2='${#'$2'[@]}';
    if [ $l2 -gt $l1 ]; then
        l1=$l2;
        # we dont care about the shorter one ¯\_(ツ)_/¯
    fi

    declare -ai sum=0;
    local carry=0;
    local i=0;
    while [ $i -lt $l1 ] || [ $carry -gt 0 ]; do
        local tmpsum=$(( $1[i] + $2[i] + carry ));
        if [ $tmpsum -lt 0 ]; then
            carry=1;
            (( tmpsum ^= 1 << 63 ));
        else
            carry=0;
        fi
        sum[$i]=$tmpsum;
        ((++i));
    done
    echo ${sum[@]}; # they're all numbers anyways
}

ap_add() { # ex. a=($(ap_add n1 n2)) yes those parentheses are necessary if assigning
    local sign1=$(( $1 & (1<<63) ? 1 : 0));
    local sign2=$(( $2 & (1<<63) ? 1 : 0));
    local t t1 t2;
    if   [ $sign1 = 0 ] && [ $sign2 = 0 ]; then _ap_add $1 $2;
    elif [ $sign1 = 1 ] && [ $sign2 = 0 ]; then
        t=$1[@];
        t=(${!t});
        (( t ^= 1 << 63 ));
        ap_subtract $2 t;
    elif [ $sign1 = 0 ] && [ $sign2 = 1 ]; then
        t=$2[@];
        t=(${!t});
        (( t ^= 1 << 63 ));
        ap_subtract $1 t;
    else
        t1=$1[@];
        t2=$2[@];
        t1=(${!t1});
        t2=(${!t2});
        (( t1 ^= 1 << 63 ));
        (( t2 ^= 1 << 63 ));
        t1=($(_ap_add t1 t2));
        (( t1 ^= 1 << 63 ));
        echo ${t1[@]};
    fi
}
