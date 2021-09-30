#!/bin/bash

set -uex

MARKER="${1:-}"

pytest_opts=(
    -rfEX
    --timeout 300
    --maxfail 500
    --showlocals
    --numprocesses 2
)

if [[ "${MARKER}" != "" ]]; then
    pytest_opts+=(-m "${MARKER}")
fi

python3 -m pip install --user pytest-timeout pytest-xdist
python3 -m pip install --user -v ".[all,test]"

pushd tests
python3 -c 'import cupy; cupy.show_config(_full=True)'
test_retval=0
timeout --signal INT --kill-after 60 18000 python3 -m pytest "${pytest_opts[@]}" . || test_retval=$?
popd

case ${test_retval} in
    0 )
        echo "Result: SUCCESS"
        ;;
    124 )
        echo "Result: TIMEOUT (INT)"
        exit $test_retval
        ;;
    137 )
        echo "Result: TIMEOUT (KILL)"
        exit $test_retval
        ;;
    * )
        echo "Result: FAIL ($test_retval)"
        exit $test_retval
        ;;
esac

python3 .pfnci/trim_cupy_kernel_cache.py --max-size $((5*1024*1024*1024)) --rm
