#!/bin/bash

source ./config.sh

APP=$1
APP_PATH=${RUN_APP[${APP}]}
INST_SKIP=${SKIP_INST[${APP}]}
PIN_DIR=${CHAMPSIM_PATH}/tracer/pin/pin-3.22-98547-g7a303a835-gcc-linux
TRACER_DIR=${CHAMPSIM_PATH}/tracer/pin/
TRACE_DIR=${CHAMPSIM_PATH}/trace

if [ "${APP}" = "dlrm" ]; then
	${BEFORE_APP[${APP}]}
fi

# For check STLB MISS MPKI 
# perf stat -e instructions,dtlb_store_misses.walk_completed $APP_PATH

# For SKIP_INST
# perf stat -e instructions $APP_PATH

# For Trace
${PIN_DIR}/pin -t ${TRACER_DIR}/obj-intel64/champsim_tracer.so -s 500000000 -t $INST_SKIP -o ${TRACE_DIR}/${APP}.champsimtrace -- ${APP_PATH} 
