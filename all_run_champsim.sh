#!/bin/bash
source ./config.sh
source ./app_name.sh

# app=$1
# champsim_type=$2

run_all() {
	local app=$1

	rm ${RESULT_PATH}/${app}_perform.csv
	for champsim_type in "${SIMULATOR_NAMES_RUN[@]}"; do
		rm ${DATA_PATH}/${app}_${champsim_type}.output
		${CHAMPSIM_PATH}/bin/${champsim_type} \
			-w 100000000 -i 250000000 \
			${CHAMPSIM_PATH}/trace/$app >> ${DATA_PATH}/${app}_${champsim_type}.output &
	done 

	wait

	echo "type,cycles,IPC" >> ${RESULT_PATH}/${app}_perform.csv
	for champsim_type in "${SIMULATOR_NAMES[@]}"; do
		rm ${RESULT_PATH}/${app}_${champsim_type}_dram_state.csv
		rm ${RESULT_PATH}/${app}_${champsim_type}_dram_latency.csv
		rm ${RESULT_PATH}/${app}_${champsim_type}_latency.csv
		rm ${RESULT_PATH}/${app}_${champsim_type}_prefetch.csv
		rm ${RESULT_PATH}/${app}_${champsim_type}.csv
		awk '/=== Simulation DISTRIBUTION CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}_distribution.csv"
		awk '/=== Simulation DARM STATE CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}_dram_state.csv"
		awk '/=== Simulation AVG DARM LATENCY CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}_dram_latency.csv"
		awk '/=== Simulation AVG MISS LATENCY CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}_latency.csv"
		awk '/=== Simulation PREFETCH CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}_prefetch.csv"
		awk '/=== Simulation CSV ===/ { flag=1; next } flag && NF == 0 { flag=0 } flag { print }
		' "${DATA_PATH}/${app}_${champsim_type}.output" > "${RESULT_PATH}/${app}_${champsim_type}.csv"

		line=$(cat "${DATA_PATH}/${app}_${champsim_type}.output" | grep "Simulation complete")
		cycles=$(echo "$line" | grep -oP "cycles: \K[0-9]+")
		ipc=$(echo "$line" | grep -oP "cumulative IPC: \K[0-9.]+(?= )")
		echo "${champsim_type},${cycles},${ipc}" >> ${RESULT_PATH}/${app}_perform.csv
	done 
}

unzip_trace() {
	local trace_file=$1
	cd ${TRACE_PATH}
	cp ${trace_file} ${CHAMPSIM_PATH}/trace/${trace_file}
	
	cd ${CHAMPSIM_PATH}/trace/ 
	echo unzip ${trace_file}
	case "${trace_file}" in 
		*.xz)
			echo "Decompressing $trace_file using xz..."
			unxz "$trace_file"
			;;
		*.gz)
			echo "Decompressing $trace_file using gzip..."
			gunzip "$trace_file"
			;;
		*.bz2)
			echo "Decompressing $trace_file using bzip2..."
			bunzip2 "$trace_file"
			;;
		*)
			echo "Unsupported file extension for compression: $trace_file"						
			;;
	esac
}

cd $(pwd)/tool/config_generate
#
./config_champsim.sh
cd ../../

for ((i=0; i<${#TRACE_FILES[@]}; i++)); do
	trace_file=${TRACE_FILES[$i]}

	echo $trace_file
	if [ "$i" -eq 0 ]; then
		unzip_trace $trace_file
	fi
	trace_file="${trace_file%.*}"

	if [ $((i+1)) -lt ${#TRACE_FILES[@]} ]; then
		next_trace_file=${TRACE_FILES[$((i+1))]}
		unzip_trace $next_trace_file &
	fi

	echo run ${trace_file}
	run_all ${trace_file} &	
	
	wait

	echo rm ${trace_file}
	rm ${CHAMPSIM_PATH}/trace/${trace_file}
done
