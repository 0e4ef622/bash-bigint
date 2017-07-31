# use to make a negative bigint since i dont use two's complement
# TODO also for numbers that are bigger than 2^63-1
bigint() {
    local n=$1;
    [ $n -lt 0 ] && (( n = (~n + 1) ^ (1 << 63) ));
    echo $n;
}

_bigint_add() {
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    local l1=${#n1[@]};
    local l2=${#n2[@]};
    if [ $l2 -gt $l1 ]; then
        l1=$l2;
        # we dont care about the shorter one ¯\_(ツ)_/¯
    fi

    declare -ai sum=0;
    local carry=0;
    local i=0;
    while [ $i -lt $l1 ] || [ $carry -gt 0 ]; do
        local tmpsum=$(( n1[i] + n2[i] + carry ));
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
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    # if the first one isn't bigger, then there's an problem
    local l1=${#n1[@]};

    declare -ai diff=0;
    local carry=0;
    local i=0;
    while [ $i -lt $l1 ] || [ $carry -gt 0 ]; do
        local tmpdiff=$(( n1[i] - n2[i] - carry ));
        if [ $tmpdiff -lt 0 ]; then
            carry=1;
            (( tmpdiff ^= 1 << 63 ));
        else
            carry=0;
        fi
        diff[$i]=$tmpdiff;
        ((++i));
    done
    while [ ${#diff[@]} -gt 1 ] && [ ${diff[-1]} -eq 0 ]; do
        unset diff[-1];
    done
    echo ${diff[@]}; # they're all numbers anyways so no quoting
}

# deal with when the second number is bigger than the first one
_bigint_presubt() {
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    if _bigint_nosign_ge n1 n2; then
        _bigint_subtract n1 n2;
    else
        local t=($(_bigint_subtract n2 n1));
        bigint_negate t;
    fi
}

_bigint_nosign_ge() {
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    local l1=${#n1[@]};
    local l2=${#n2[@]};
    if   [ $l1 -gt $l2 ]; then return 0;
    elif [ $l1 -lt $l2 ]; then return 1;
    else
        local i=0;
        while [ $i -lt $l1 ]; do
            local d1=${n1[i]} d2=${n2[i]};
            if   [ $d1 -gt $d2 ]; then
                return 0;
            elif [ $d1 -lt $d2 ]; then
                return 1;
            fi
            ((i++));
        done
    fi
    return 0;
}

bigint_mnegate() { # modify the reference
    (( $1 ^= 1 << 63 ));
}

bigint_negate() { # return an new bigint
    eval local t='(${'$1'[@]})';
    (( t ^= 1 << 63 ));
    echo ${t[@]};
}

# ex. a=($(bigint_add n1 n2)) yes those parentheses are necessary if assigning
# also n1 and n2 are variable names
bigint_add() {
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    local sign1=$(( n1 & (1<<63) ));
    local sign2=$(( n2 & (1<<63) ));
    local t t1 t2;
    if   [ $sign1 -eq 0 ] && [ $sign2 -eq 0 ]; then _bigint_add n1 n2;
    elif [ $sign1 -ne 0 ] && [ $sign2 -eq 0 ]; then
        t=($(bigint_negate n1));
        bigint_subtract n2 t;
    elif [ $sign1 -eq 0 ] && [ $sign2 -ne 0 ]; then
        t=($(bigint_negate n2));
        bigint_subtract n1 t;
    else
        t1=($(bigint_negate n1));
        t2=($(bigint_negate n2));
        t1=($(_bigint_add t1 t2));
        bigint_negate t1
    fi
}

bigint_subtract() {
    # prevent variable shadowing
    eval local n='("${'$1'[*]}" "${'$2'[*]}")';
    local n1=(${n[0]});
    local n2=(${n[1]});

    local sign1=$(( n1 & (1<<63) ));
    local sign2=$(( n2 & (1<<63) ));
    local t t1 t2;
    if   [ $sign1 -eq 0 ] && [ $sign2 -eq 0 ]; then
        _bigint_presubt n1 n2;
    elif [ $sign1 -ne 0 ] && [ $sign2 -eq 0 ]; then
        t=($(bigint_negate n1));
        t=($(bigint_add t n2));
        bigint_negate t;
    elif [ $sign1 -eq 0 ] && [ $sign2 -ne 0 ]; then
        t=($(bigint_negate n2));
        bigint_add n1 t;
    else
        t1=($(bigint_negate n1));
        t2=($(bigint_negate n2));
        _bigint_presubt t2 t1;
    fi
}
