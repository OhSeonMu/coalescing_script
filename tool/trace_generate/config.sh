#!/bin/bash
cd ../../

APP_PATH=$(pwd)/../app
CHAMPSIM_PATH=$(pwd)/../ChampSim
DATA_PATH=$(pwd)/../raw_data
RESULT_PATH=$(pwd)/../result
TRACE_PATH=$(pwd)/../trace

declare -A RUN_APP
declare -A BEFORE_APP
declare -A SKIP_INST


# For RUN_APP
# xsbench
RUN_APP["xsbench"]="${APP_PATH}/XSBench/openmp-threading/XSBench -g 20000"
# dlrm
RUN_APP["dlrm"]="./bench/dlrm_s_benchmark.sh"
# gups
RUN_APP["gups"]="${APP_PATH}/gups/gups_vanilla 30 2048000 1024"
# geenomicsbench
RUN_APP["genomicsbench"]="${APP_PATH}/genomicsbench/benchmarks/kmer-cnt/kmer-cnt \
	--reads ${APP_PATH}/genomicsbench/data/input-datasets/kmer-cnt/large/Loman_E.coli_MAP006-1_2D_50x.fasta \
	--config ${APP_PATH}/genomicsbench/tools/Flye/flye/config/bin_cfg/asm_raw_reads.cfg --threads 1 --debug"
# graphBig
RUN_APP["bc"]="${APP_PATH}/graphBIG/benchmark/bench_betweennessCentr/bc --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["bfs"]="${APP_PATH}/graphBIG/benchmark/bench_BFS/bfs --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["cc"]="${APP_PATH}/graphBIG/benchmark/bench_connectedComp/connectedcomponent --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["gc"]="${APP_PATH}/graphBIG/benchmark/bench_graphColoring/graphcoloring --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["pr"]="${APP_PATH}/graphBIG/benchmark/bench_pageRank/pagerank --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["sssp"]="${APP_PATH}/graphBIG/benchmark/bench_shortestPath/sssp --dataset ${APP_PATH}/graphBIG/dataset"
RUN_APP["tc"]="${APP_PATH}/graphBIG/benchmark/bench_triangleCount/tc --dataset ${APP_PATH}/graphBIG/dataset"
# Prefetch Test
RUN_APP["sp"]="${APP_PATH}/prefetech_test/sp_test.o"

# For BEFORE_APP
BEFORE_APP["dlrm"]="cd ${APP_PATH}/dlrm"

# Calculate # of instructions for data loading by using perf and modification benchmark (do only load data)
# To generage trace file 
SKIP_INST["xsbench"]=44723892498
# SKIP_INST["dlrm"]=
SKIP_INST["gups"]=17035551709
SKIP_INST["genomicsbench"]=10933947157
SKIP_INST["bc"]=179235979894
SKIP_INST["bfs"]=175539202806
SKIP_INST["cc"]=174938291730
SKIP_INST["gc"]=179159514671
SKIP_INST["pr"]=177784828249
SKIP_INST["sssp"]=194078600594
SKIP_INST["tc"]=318226815479

SKIP_INST["sp"]=318226815479
