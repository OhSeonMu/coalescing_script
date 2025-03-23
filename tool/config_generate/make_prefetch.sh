#!/bin/bash
cd ../../
source ./config.sh

make_idle_memory() {
	local file_name=$1

	new_file_name=idle_${file_name}
	cp ${file_name} ${new_file_name}

	total=$(wc -l < "${new_file_name}")
	target=$((total - 8))
	new_line='"idle_memory": 1'

	sed -i "${target}s/\$/,/" "${new_file_name}"
	sed -i "${target}a ${new_line}" "${new_file_name}"
}

make_perfect_tlb() {
	new_file=perfect_tlb.sh

	cp default.sh ${new_file}

	new_perfect_activate='        "perfect_activate": "LOAD",'
	new_line='        "perfect_tlb": true'
	sed -i "125s/\$/,/" "${new_file}"
	sed -i "125a ${new_perfect_activate}" "${new_file}"
	sed -i "126a ${new_line}" "${new_file}"
	
	new_activate='         "perfect_activate": "L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	new_line='         "perfect_cache": true,'
	sed -i "69a ${new_activate}" "${new_file}"
	sed -i "70a ${new_line}" "${new_file}"
	
	make_idle_memory $new_file
}

make_perfect_cache() {
	local cache=$1
	local line=$2

	new_file=perfect_${cache}.sh
	line_1=$line
	line_2=$((line + 1))
	new_activate='         "perfect_activate": "L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	new_line='         "perfect_cache": true,'

	cp default.sh ${new_file} 
	sed -i "${line_1}a ${new_activate}" "${new_file}"
	sed -i "${line_2}a ${new_line}" "${new_file}"
	
	make_idle_memory $new_file
}

make_asap() {
	new_line='        "enable_asap": 1'
	new_file=ptw_asap.sh

	cp default.sh ${new_file}

	sed -i "154s/\$/,/" "${new_file}"
	sed -i "154a ${new_line}" "${new_file}"
	
	make_idle_memory $new_file
}

make_ptempo() {
	local prefetcher=$1
	local pb_size=$2
	local cache=$3
	
	if [[ $pb_size == "0" ]]; then
		new_file=ptw_ptempo_${prefetcher}_${cache}.sh
	else
		new_file=ptw_ptempo_${prefetcher}_${pb_size}_${cache}.sh
	fi
	cp default.sh ${new_file}

	# LLC
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 0,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 0,'
	else
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 1,'
	fi
	sed -i "171a ${new_line_1}" "${new_file}"
	sed -i "172a ${new_line_2}" "${new_file}"

	# PTW
	new_line='        "enable_ptempo": 1'
	sed -i "154s/\$/,/" "${new_file}"
	sed -i "154a ${new_line}" "${new_file}"

	# PB
	new_activate='        "prefetch_activate": "LOAD",'
	new_line='        "prefetcher": "'"${prefetcher}"'"'

	if [[ $pb_size != "0" ]]; then
		sed -i "130s/32/${pb_size}/" "${new_file}"
	fi
	sed -i "139s/\$/,/" "${new_file}"
	sed -i "139a ${new_activate}" "${new_file}"
	sed -i "140a ${new_line}" "${new_file}"
	
	# L2C
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 0,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 1,'
	else
		new_line_1='"skip_ptempo": 1,'
		new_line_2='"enable_ptempo": 0,'
	fi
	sed -i "85a ${new_line_1}" "${new_file}"
	sed -i "86a ${new_line_2}" "${new_file}"

	# L1D
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_ptempo": 0,'
		new_line_2='"enable_ptempo": 1,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_ptempo": 1,'
		new_line_2='"enable_ptempo": 0,'
	else
		new_line_1='"skip_ptempo": 1,'
		new_line_2='"enable_ptempo": 0,'
	fi
	sed -i "69a ${new_line_1}" "${new_file}"
	sed -i "70a ${new_line_2}" "${new_file}"
	
	make_idle_memory $new_file
}

make_cache_prefetcher() {
	local cache=$1
	local activate=$2
	local name=$3
	local prefetcher=$4

	old_activate='"LOAD,PREFETCH",'
	if [[ $activate == "all" ]]; then
		new_activate='"LOAD,PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	elif [[ $activate == "data" ]]; then
		new_activate='"LOAD,PREFETCH",'
	elif [[ $activate == "at" ]]; then
		new_activate='"PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	fi

	if [[ $cache == "llc" ]]; then
		new_file=${activate}_${name}.sh
		line_1=170
		line_2=171
		old_prefetcher='"no",'
		new_prefetcher='"'"${prefetcher}"'",'
	elif [[ $cache == "l2" ]]; then
		new_file=${cache}_${activate}_${name}.sh
		line_1=85
		line_2=86
		old_prefetcher='"no"'
		new_prefetcher='"'"${prefetcher}"'"'
	fi

	
	cp default.sh ${new_file}
	sed -i "${line_1}s/${old_activate}/${new_activate}/" "${new_file}"
	sed -i "${line_2}s/${old_prefetcher}/${new_prefetcher}/" "${new_file}"
	
	make_idle_memory $new_file
}

make_tlb_prefetcher() {
	local prefetcher=$1
	local pb_size=$2

	new_activate='        "prefetch_activate": "LOAD",'
	new_line='        "prefetcher": "'"${prefetcher}"'"'

	if [[ $pb_size == "0" ]]; then
		new_file=tlb_${prefetcher}.sh
	else
		new_file=tlb_${prefetcher}_${pb_size}.sh
	fi
	cp default.sh ${new_file}

	if [[ $pb_size != "0" ]]; then
		sed -i "130s/32/${pb_size}/" "${new_file}"
	fi
	if [[ $prefetcher == "miss" ]]; then
		sed -i "120s/0/32/" "${new_file}"
		sed -i "125s/false/true/" "${new_file}"
		sed -i "125s/\$/,/" "${new_file}"
		sed -i "125a ${new_activate}" "${new_file}"
		sed -i "126a ${new_line}" "${new_file}"
	else
		sed -i "139s/\$/,/" "${new_file}"
		sed -i "139a ${new_activate}" "${new_file}"
		sed -i "140a ${new_line}" "${new_file}"
	fi
	
	make_idle_memory $new_file
}

make_all_prefetcher() {
	local tlb_prefetcher=$1
	local pb_size=$2

	local l1_activate=$3
	local l1_name=$4
	local l1_prefetcher=$5
	
	local l2_activate=$6
	local l2_name=$7
	local l2_prefetcher=$8

	local l3_activate=$9
	local l3_name=${10}
	local l3_prefetcher=${11}

	new_file=${tlb_prefetcher}_${l1_name}_${l2_name}_${l3_name}.sh
	cp default.sh ${new_file}
	
	# LLC 
	old_activate='"LOAD,PREFETCH",'
	if [[ $l3_activate == "all" ]]; then
		new_activate='"LOAD,PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	elif [[ $l3_activate == "data" ]]; then
		new_activate='"LOAD,PREFETCH",'
	elif [[ $l3_activate == "at" ]]; then
		new_activate='"PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	fi

	line_1=170
	line_2=171
	old_prefetcher='"no",'
	new_prefetcher='"'"${l3_prefetcher}"'",'
	
	sed -i "${line_1}s/${old_activate}/${new_activate}/" "${new_file}"
	sed -i "${line_2}s/${old_prefetcher}/${new_prefetcher}/" "${new_file}"
	
	# PB
	new_activate='        "prefetch_activate": "LOAD",'
	new_line='        "prefetcher": "'"${tlb_prefetcher}"'"'

	if [[ $pb_size != "0" ]]; then
		sed -i "130s/32/${pb_size}/" "${new_file}"
	fi

	sed -i "139s/\$/,/" "${new_file}"
	sed -i "139a ${new_activate}" "${new_file}"
	sed -i "140a ${new_line}" "${new_file}"
	
	# L2C
	old_activate='"LOAD,PREFETCH",'
	if [[ $l2_activate == "all" ]]; then
		new_activate='"LOAD,PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	elif [[ $l2_activate == "data" ]]; then
		new_activate='"LOAD,PREFETCH",'
	elif [[ $l2_activate == "at" ]]; then
		new_activate='"PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	fi

	line_1=85
	line_2=86
	old_prefetcher='"no"'
	new_prefetcher='"'"${l2_prefetcher}"'"'
	
	sed -i "${line_1}s/${old_activate}/${new_activate}/" "${new_file}"
	sed -i "${line_2}s/${old_prefetcher}/${new_prefetcher}/" "${new_file}"
	
	# L1D
	old_activate='"LOAD,PREFETCH",'
	if [[ $l1_activate == "all" ]]; then
		new_activate='"LOAD,PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	elif [[ $l1_activate == "data" ]]; then
		new_activate='"LOAD,PREFETCH",'
	elif [[ $l1_activate == "at" ]]; then
		new_activate='"PREFETCH,L5_TRANSLATION,L4_TRANSLATION,L3_TRANSLATION,L2_TRANSLATION,L1_TRANSLATION",'
	fi

	line_1=69
	line_2=70
	old_prefetcher='"no"'
	new_prefetcher='"'"${l1_prefetcher}"'"'
	
	sed -i "${line_1}s/${old_activate}/${new_activate}/" "${new_file}"
	sed -i "${line_2}s/${old_prefetcher}/${new_prefetcher}/" "${new_file}"
	
	make_idle_memory $new_file
}
	
# make_tlb_cache_prefetcher ${tlb_prefetcher} ${pb_size} ${cache}
make_tlb_cache_prefetcher() {
	local prefetcher=$1
	local pb_size=$2
	local cache=$3

	new_activate='        "prefetch_activate": "LOAD",'
	new_line='        "prefetcher": "'"${prefetcher}"'"'

	if [[ $pb_size == "0" ]]; then
		new_file=tlb_${prefetcher}_${cache}.sh
	else
		new_file=tlb_${prefetcher}_${pb_size}_${cache}.sh
	fi
	cp default.sh ${new_file}

	# LLC
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 0,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 0,'
	else
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 1,'
	fi
	sed -i "171a ${new_line_1}" "${new_file}"
	sed -i "172a ${new_line_2}" "${new_file}"

	# PB / STLB
	if [[ $prefetcher != "miss_cache" ]]; then
		if [[ $pb_size != "0" ]]; then
			sed -i "130s/32/${pb_size}/" "${new_file}"
		fi
		sed -i "139s/\$/,/" "${new_file}"
		sed -i "139a ${new_activate}" "${new_file}"
		sed -i "140a ${new_line}" "${new_file}"
	else
		sed -i "120s/0/32/" "${new_file}"
		sed -i "125s/false/true/" "${new_file}"
		sed -i "125s/\$/,/" "${new_file}"
		sed -i "125a ${new_activate}" "${new_file}"
		sed -i "126a ${new_line}" "${new_file}"
	fi
	
	# L2C
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 0,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 1,'
	else
		new_line_1='"skip_tcp": 1,'
		new_line_2='"enable_tcp": 0,'
	fi
	sed -i "85a ${new_line_1}" "${new_file}"
	sed -i "86a ${new_line_2}" "${new_file}"

	# L1D
	if [[ $cache == "l1" ]]; then
		new_line_1='"skip_tcp": 0,'
		new_line_2='"enable_tcp": 1,'
	elif [[ $cache == "l2" ]]; then
		new_line_1='"skip_tcp": 1,'
		new_line_2='"enable_tcp": 0,'
	else
		new_line_1='"skip_tcp": 1,'
		new_line_2='"enable_tcp": 0,'
	fi
	sed -i "69a ${new_line_1}" "${new_file}"
	sed -i "70a ${new_line_2}" "${new_file}"

	make_idle_memory $new_file
}

cd ${CHAMPSIM_PATH}/tcp_config

# IDLE MEMORY
make_idle_memory default.sh

# PERFECT TLB
make_perfect_tlb

# PERFECT CACHE
make_perfect_cache l1 69
make_perfect_cache l2 85
make_perfect_cache l3 171

# ASAP
make_asap

# Prefetch Tempo
for cache in l1 l2 l3
do
for tlb_prefetcher in sp asp mp dp 
do
	make_ptempo ${tlb_prefetcher} 0 ${cache}
done
done

# LLC ALL PREFETCHER
for cache in llc l2
do
for activate in all data at
do
	make_cache_prefetcher $cache $activate spp spp_dev 
	make_cache_prefetcher $cache $activate ampm va_ampm_lite
	make_cache_prefetcher $cache $activate berti berti
	make_cache_prefetcher $cache $activate bingo bingo
	make_cache_prefetcher $cache $activate ip ip_stride
	make_cache_prefetcher $cache $activate next next_line
	make_cache_prefetcher $cache $activate casp casp 
	make_cache_prefetcher $cache $activate cdp cdp
done
done

# TLB PREFETCHER
for tlb_prefetcher in sp asp mp dp miss dp_slot_1 dp_slot_2 dp_slot_4 dp_slot_8
do
for pb_size in 0 # 1 2 4 8 16 32 64 128 256 512
do
	make_tlb_prefetcher ${tlb_prefetcher} ${pb_size}
done
done

# TLB CACHE PREFETCHER
for cache in l1 l2 l3
do
for tlb_prefetcher in sp_cache sp_tlb_cache asp_cache asp_tlb_cache dp_cache dp_tlb_cache miss_cache 
do
for pb_size in 0 # 1 2 4 8 16 32 64 128 256 512
do
	make_tlb_cache_prefetcher ${tlb_prefetcher} ${pb_size} ${cache}
done
done
done

:<<"END"
# ALL PREFETCHER
# make_all_prefetcher \
# 	tlb_prefetcher pb_size l1_activate l1_name l1_prefetcher l2_activate l2_name l2_prefetcher l3_activate l3_name l3_prefetcher
for tlb_prefetcher in sp asp mp dp
do
for pb_size in 0
do
l1_activate=data 
l1_name=next
l1_prefetcher=next_line
l2_activate=data
l2_name=ip
l2_prefetcher=ip_stride

make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	data no no 
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at spp spp_dev 
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at ampm va_ampm_lite
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at berti berti
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at bingo bingo
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at ip ip_stride
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at next next_line
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at casp casp 
make_all_prefetcher \
	$tlb_prefetcher $pb_size $l1_activate $l1_name $l1_prefetcher $l2_activate $l2_name $l2_prefetcher \
	at cdp cdp 
done
done
END

