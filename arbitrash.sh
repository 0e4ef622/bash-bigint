# use to make a negative bigint since i dont use two's complement
# TODO also for numbers that are bigger than 2^63-1
bigint() {
    local n=$1;
    [ $n -lt 0 ] && (( n = (~n + 1) ^ (1 << 63) ));
    echo $n;
}

_bigint_add() {
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
    echo ${sum[@]}; # they're all numbers anyways so no quoting
}

_bigint_subtract() {
    # if the first one isn't bigger, then there's an problem
    eval local l1='${#'$1'[@]}';

    declare -ai diff=0;
    local carry=0;
    local i=0;
    while [ $i -lt $l1 ] || [ $carry -gt 0 ]; do
        local tmpdiff=$(( $1[i] - $2[i] - carry ));
        if [ $tmpdiff -lt 0 ]; then
            carry=1;
            (( tmpdiff ^= 1 << 63 ));
        else
            carry=0;
        fi
        diff[$i]=$tmpdiff;
        ((++i));
    done
    echo ${diff[@]}; # they're all numbers anyways so no quoting
}

# deal with when the second number is bigger than the first one
_bigint_presubt() {
    # TODO
}

_nosign_bigint_gt() {
    eval local l1='${#'$1'[@]}';
    eval local l2='${#'$2'[@]}';
    if   [ $l1 -gt $l2 ]; then return 0;
    elif [ $l1 -le $l2]; then return 1;
    else
        local i=0;
        while [ $i -lt $l1 ]; do
            local n1=$(($1[$i])) n2=$(($1[$i]));
            if   [ $n1 -gt $n2 ]; then
                return 0;
            elif [ $n1 -lt $n2 ]; then
                return 1;
            fi
            ((i++));
        done
    fi
    return 1;
}

bigint_mnegate() { # modify the reference
    (( $1 ^= 1 << 63 ));
}

bigint_negate() { # return an new bigint
    local t=$1[@];
    t=(${!t});
    (( t ^= 1 << 63 ));
    echo ${t[@]};
}

# ex. a=($(bigint_add n1 n2)) yes those parentheses are necessary if assigning
# also n1 and n2 are variable names
bigint_add() {
    local sign1=$(( $1 & (1<<63) ));
    local sign2=$(( $2 & (1<<63) ));
    local t t1 t2;
    if   [ $sign1 -eq 0 ] && [ $sign2 -eq 0 ]; then _bigint_add $1 $2;
    elif [ $sign1 -ne 0 ] && [ $sign2 -eq 0 ]; then
        t=($(bigint_negate $1));
        bigint_subtract $2 t;
    elif [ $sign1 -eq 0 ] && [ $sign2 -ne 0 ]; then
        t=($(bigint_negate $2));
        bigint_subtract $1 t;
    else
        t1=($(bigint_negate $1));
        t2=($(bigint_negate $2));
        t1=($(_bigint_add t1 t2));
        bigint_negate t1
    fi
}

bigint_subtract() {
    local sign1=$(( $1 & (1<<63) ));
    local sign2=$(( $2 & (1<<63) ));
    local t t1 t2;
    if   [ $sign1 -eq 0 ] && [ $sign2 -eq 0 ]; then
        _bigint_presubt $1 $2;
    elif [ $sign1 -ne 0 ] && [ $sign2 -eq 0 ]; then
        t=($(bigint_negate $1));
        t=($(bigint_add t $2));
        bigint_negate t;
    elif [ $sign1 -eq 0 ] && [ $sign2 -ne 0 ]; then
        t=($(bigint_negate $2));
        bigint_add $1 t;
    else
        t1=($(bigint_negate $1));
        t2=($(bigint_negate $2));
        _bigint_presubt t2 t1;
    fi
}
