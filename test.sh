#!/bin/bash

workload_types=("a" "b" "c" "d" "f")
#workload_types=("a")
runs=3
fieldlength=9
field_len_dist="uniform"
operationcount=80000000
recordcount=80000000
#operationcount=100000
#recordcount=100000
dynamic_cmpct="false"
block_cache_size=419430400
bpk=3
threads=1
methods=("workloadaware" "monkey" "default")
# Remember to specify your database path here to use a dedicated storage device
#DB_HOME="/data/ycsb_working_home/"
DB_HOME="./"
#methods=("workloadaware" "monkey")
cp rocksdb/rocksdb.properties rocksdb/rocksdb.origin_properties
sed -i 's/rocksdb\.dbname=\.\//rocksdb.dbname=${DB_HOME}/g' rocksdb/rocksdb.properties
mkdir -p "exp"
for i in `seq 1 ${runs}`
do
  mkdir -p "exp/run${i}"
  for method in ${methods[@]}
  do
	cp rocksdb/options.ini rocksdb/origin_options.ini
	cp rocksdb/options-exp-${method}.ini rocksdb/options.ini
	sed -i "s/block_cache={capacity=33554432}/block_cache={capacity=${block_cache_size}}/g" rocksdb/options.ini
	sed -i "s/level_compaction_dynamic_level_bytes=true/level_compaction_dynamic_level_bytes=${dynamic_cmpct}/g" rocksdb/options.ini
  	for workload_type in ${workload_types[@]}
  	do
	  cp workloads/workload${workload_type} workloads/workload-temp
	  echo "fieldlength=${fieldlength}" >> workloads/workload-temp
	  echo "field_len_dist=${field_len_dist}" >> workloads/workload-temp
	  sed -i "s/operationcount=100000/operationcount=${operationcount}/g" workloads/workload-temp
	  sed -i "s/recordcount=100000/recordcount=${recordcount}/g" workloads/workload-temp
	  sed -i "s/bloomfilter:5:false/bloomfilter:${bpk}:false/g" rocksdb/options.ini
	  echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../Mnemosyne/skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 | tee "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt""
          LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../Mnemosyne/skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 > "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt"
	  grep -A60 "DUMPING STATS" /data/ycsb_working_home/LOG > exp/run${i}/${method}_workload${workload_type}_ycsb_dumped_stats.txt
	  mv ${DB_HOME}/LOG exp/run${i}/${method}_workload${workload_type}_ycsb_LOG.txt
	  cat workloads/workload-temp > "exp/run${i}/workload${workload_type}.txt"
	  rm workloads/workload-temp
	  rm ${DB_HOME}/*
  	done
	mv rocksdb/origin_options.ini rocksdb/options.ini
  done
done
mv rocksdb/rocksdb.origin_properties rocksdb/rocksdb.properties
