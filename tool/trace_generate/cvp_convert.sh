#!/bin/bash
cd ../../
source ./config.sh

for trace_file in "${TRACE_FILES[@]}"; do 
	echo $trace_file
	trace_file_1="${trace_file%.*}"
	${CHAMPSIM_PATH}/tracer/cvp_converter/cvp_tracer ${TRACE_PATH}/${trace_file} | xz > ${TRACE_PATH}/${trace_file_1}.xz
	rm ${TRACE_PATH}/${trace_file}
done
