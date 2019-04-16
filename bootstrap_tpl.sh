#!/bin/bash
# cd $LAMBDA_TASK_ROOT
# ./lamb-d
set -euo pipefail
export AWS_EXECUTION_ENV=lamb-D
exec $LAMBDA_TASK_ROOT/lib/ld-linux-x86-64.so.2 --library-path $LAMBDA_TASK_ROOT/lib $LAMBDA_TASK_ROOT/bin/lamb-d ${_HANDLER}
