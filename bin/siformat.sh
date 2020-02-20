#!/usr/bin/env ksh

# this works in korn shell only, pass numbers (even as 1e3) as arguments and get suffix-formatted strings
# works up to 1e18, only k,M,G,T...
# decimal sep is ".", comma "," is discarded, e.g. 123456,42 is 42 while 1234.56 is 1.2k

printf "%#d\n" "$@" 