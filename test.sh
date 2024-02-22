#!/bin/bash

workload_types=("a" "b" "c" "d" "f")
#workload_types=("a")
runs=3
fieldlength=9
field_len_dist="uniform"
operationcount=30000000
recordcount=30000000
#operationcount=100000
#recordcount=100000
#cache_size=99614720
bpk=2
methods=("workloadaware" "monkey" "default")
mkdir -p "exp"
for i in `seq 1 ${runs}`
do
  mkdir -p "exp/run${i}"
  for method in ${methods[@]}
  do
	cp rocksdb/options.ini rocksdb/origin_options.ini
	cp rocksdb/options-exp-${method}.ini rocksdb/options.ini
  	for workload_type in ${workload_types[@]}
  	do
	  cp workloads/workload${workload_type} workloads/workload-temp
	  echo "fieldlength=${fieldlength}" >> workloads/workload-temp
	  echo "field_len_dist=${field_len_dist}" >> workloads/workload-temp
	  sed -i "s/operationcount=100000/operationcount=${operationcount}/g" workloads/workload-temp
	  sed -i "s/recordcount=100000/recordcount=${recordcount}/g" workloads/workload-temp
	  sed -i "s/bloomfilter:5:false/bloomfilter:${bpk}:false/g" rocksdb/options.ini
	  echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../Mnemosyne/skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 | tee "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt""
          LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../Mnemosyne/skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 | tee "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt"
	  grep -A60 "DUMPING STATS" /data/ycsb_working_home/LOG > exp/run${i}/${method}_workload${workload_type}_ycsb_dumped_stats.txt
	  cat workloads/workload-temp > "exp/run${i}/workload${workload_type}.txt"
	  rm workloads/workload-temp
	  rm /data/ycsb_working_home/*

  	done
	mv rocksdb/origin_options.ini rocksdb/options.ini
  done
done
