#!/bin/bash

tests=(
    # basic addition functionality
    'a=5; bigint_add a a'                          '10'
    'a=$((1<<62)); bigint_add a a'                 '0 1'
    'a=(80 25 3); b=(1 0 1); bigint_add a b'       '81 25 4'
    'a=(3 3); b=$(((1<<63)-1)); bigint_add a b'    '2 4'
    'a=($(bigint -1)); b=1; bigint_add a b'        '0'
    'a=($(bigint -1)); b=1; bigint_add b a'        '0'
    'a=($(bigint -1)); bigint_add a a'             "$(( 2 ^ (1<<63) ))"

    # basic subtraction functionality
    'a=5; bigint_subtract a a'              '0'
    'a=30; b=12; bigint_subtract a b'       '18'
    'a=(0 0 1); b=1; bigint_subtract a b'   "$(((1<<63)-1)) $(((1<<63)-1))"
    'a=($(bigint -1)); b=1; bigint_subtract a b'   "$(( 2 ^ (1<<63) ))"
    'a=($(bigint -1)); b=1; bigint_subtract b a'   '2'
    'a=($(bigint -1)); bigint_subtract a a'        '0'
    'a=30; b=12; bigint_subtract b a;'             "$(( 18 ^ (1<<63) ))"

    # variable shadowing
    'n1=20; n2=5; bigint_add n1 n2'      '25'
    'n1=20; n2=5; bigint_add n2 n1'      '25'
    't=18; t2=4; bigint_subtract t t2'   '14'
    'n=8; bigint_add n n'                '16'
    'n=8; bigint_subtract n n'           '0'
)

. arbitrash.sh

fail() {
    echo "Test \`${tests[$1]}' failed. Expected \`${tests[$1+1]}', got \`$2'";
}

i=0;
l=${#tests[@]};
while [ $i -lt $l ]; do
    out=$(eval "${tests[i]}");
    if [ "$out" != "${tests[i+1]}" ]; then
        failed=1;
        fail $i "$out";
    fi
    ((i+=2));
done

if [ -v failed ]; then
    exit 1;
else
    echo "Passed all tests!";
fi
