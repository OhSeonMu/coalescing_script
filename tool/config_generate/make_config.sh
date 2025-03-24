#!/bin/bash
cd ../../
source ./config.sh

cd ${CHAMPSIM_PATH}/tcp_config

make_coalescing() {
        TLB_TYPE=$1
	BLOCK_TYPE=$2
	SUPER_PAGE_SIZE=$3
	
	CONFIG_FILE="default.sh"
	
	if [[ $TLB_TYPE == "0" ]]; then
		TLB_PAGE_SIZE="4096"
		NEW_CONFIG_FILE="coalescing"
	else
		TLB_PAGE_SIZE=${SUPER_PAGE_SIZE}
		NEW_CONFIG_FILE="coalescing_tlb"
	fi

	BCOALESCING=0
	ABCOALESCING=0
	AABCOALESCING=0
	AAABCOALESCING=0
	if [[ $BLOCK_TYPE == "0" ]]; then
		NEW_CONFIG_FILE="${NEW_CONFIG_FILE}.sh"
		# NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_${SUPER_PAGE_SIZE}"
	elif [[ $BLOCK_TYPE == "1" ]]; then
		BCOALESCING=1
		NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_block.sh"
		# NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_block_${SUPER_PAGE_SIZE}"
	elif [[ $BLOCK_TYPE == "2" ]]; then
		BCOALESCING=1
		ABCOALESCING=1
		NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_ablock.sh"
		# NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_ablock_${SUPER_PAGE_SIZE}"
	elif [[ $BLOCK_TYPE == "3" ]]; then
		BCOALESCING=1
		ABCOALESCING=1
		AABCOALESCING=1
		NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_aablock.sh"
	else
		BCOALESCING=1
		ABCOALESCING=1
		AABCOALESCING=1
		AAABCOALESCING=1
		NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_aaablock.sh"
		# NEW_CONFIG_FILE="${NEW_CONFIG_FILE}_aablock_${SUPER_PAGE_SIZE}"
	fi
	
	if [[ $TLB_TYPE == "0" && $BLOCK_TYPE == "0" ]]; then
		COALESCING=0
		TRANSLATION="false"
	else
		COALESCING=1
		TRANSLATION="true"
	fi

	jq --argjson super_page_size ${SUPER_PAGE_SIZE} \
	   --argjson tlb_page_size ${TLB_PAGE_SIZE} \
	   --argjson translation ${TRANSLATION} \
	   --argjson enable_coalescing ${COALESCING} \
	   --argjson enable_bcoalescing ${BCOALESCING} \
	   --argjson enable_abcoalescing ${ABCOALESCING} \
	   --argjson enable_aabcoalescing ${AABCOALESCING} \
	   --argjson enable_aaabcoalescing ${AAABCOALESCING} \
	   --argjson minor_fault_penalty 200 \
	   '.super_page_size = $super_page_size |
	   .tlb_page_size = $tlb_page_size |
	   .L1D.coalescing_translation = $translation |
	   .L1I.coalescing_translation = $translation |
	   .PTW.enable_calloc = 1 |
	   .PTW.enable_coalescing = $enable_coalescing |
	   .PTW.enable_bcoalescing = $enable_bcoalescing |
	   .PTW.enable_abcoalescing = $enable_abcoalescing |
	   .PTW.enable_aabcoalescing = $enable_aabcoalescing |
	   .PTW.enable_aaabcoalescing = $enable_aaabcoalescing |
	   .virtual_memory.super_pte_page_size = $super_page_size |
	   .virtual_memory.minor_fault_penalty = $minor_fault_penalty
	   ' "$CONFIG_FILE" > "$NEW_CONFIG_FILE"
}

for tlb_type in 0 1; do
for block_type in 0 1 2 3 4; do
for super_page_size in 32768; do # 16384 32768 65536
make_coalescing $tlb_type $block_type $super_page_size
done
done
done
