#!/bin/bash
source ./config.sh
source ./app_name.sh
trace_file=605.mcf_s-1536B.champsimtrace.xz

run_all() {
	local app=$1
	rm ${RESULT_ONE_PATH}/${app}_perform.csv
	for champsim_type in "${SIMULATOR_NAMES_RUN[@]}"; do
		rm ${DATA_ONE_PATH}/${app}_${champsim_type}.output
		${CHAMPSIM_PATH}/bin/${champsim_type} \
			-w 100000000 -i 250000000 \
			$app >> ${DATA_ONE_PATH}/${app}_${champsim_type}.output &
			# $app $app $app $app >> ${DATA_ONE_PATH}/${app}_${champsim_type}.output &
			# -w 100000000 -i 250000000 \
	done 
	wait

	echo "type,cycles,IPC" >> ${RESULT_ONE_PATH}/${app}_perform.csv
	for champsim_type in "${SIMULATOR_NAMES[@]}"; do
		rm ${RESULT_ONE_PATH}/${app}_${champsim_type}_dram_state.csv
		rm ${RESULT_ONE_PATH}/${app}_${champsim_type}_dram_latency.csv
		rm ${RESULT_ONE_PATH}/${app}_${champsim_type}_latency.csv
		rm ${RESULT_ONE_PATH}/${app}_${champsim_type}_prefetch.csv
		rm ${RESULT_ONE_PATH}/${app}_${champsim_type}.csv
		awk '/=== Simulation DISTRIBUTION CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}_distribution.csv"
		awk '/=== Simulation DARM STATE CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}_dram_state.csv"
		awk '/=== Simulation AVG DARM LATENCY CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}_dram_latency.csv"
		awk '/=== Simulation AVG MISS LATENCY CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}_latency.csv"
		awk '/=== Simulation PREFETCH CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}_prefetch.csv"
		awk '/=== Simulation CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_ONE_PATH}/${app}_${champsim_type}.output" > "${RESULT_ONE_PATH}/${app}_${champsim_type}.csv"

		line=$(cat "${DATA_ONE_PATH}/${app}_${champsim_type}.output" | grep "Simulation complete")
		cycles=$(echo "$line" | grep -oP "cycles: \K[0-9]+")
		ipc=$(echo "$line" | grep -oP "cumulative IPC: \K[0-9.]+(?= )")
		echo "${champsim_type},${cycles},${ipc}" >> ${RESULT_ONE_PATH}/${app}_perform.csv
	done 
}

cd $(pwd)/tool/config_generate
#
# ./make_config.sh
# ./config_champsim.sh
cd ../../

echo $trace_file
cd ${TRACE_PATH}

cd ${CHAMPSIM_PATH}/trace/ 
trace_file="${trace_file%.*}"

echo run ${trace_file}
run_all ${trace_file}	
