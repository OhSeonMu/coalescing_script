#!/bin/bash
cd ../../
source ./config.sh

# champsim_type=$1

for champsim_type in "${SIMULATOR_NAMES_RUN[@]}"; do
	cd ${CHAMPSIM_PATH}
	echo ${champsim_type}
	./config.sh ./tcp_config/${champsim_type}.sh
	make -j 50
	rm ./bin/${champsim_type}
	mv ./bin/champsim ./bin/${champsim_type}
done
