#!/bin/bash

# Download and compile the origin rocksdb
if [ ! -e ../rocksdb-8.9.1/librocksdb.so.8.9 ]; then
  ./download_and_compile_default_rocksdb.sh
fi

# Compile the Mnemosyne
if [ ! -e ../skew-aware-rocksdb-8.9.1/librocksdb.so.8.9 ]; then
  cd ../skew-aware-rocksdb-8.9.1
  make clean && make -j 32
  cd -
fi



workload_types=("a" "b" "c" "d" "f")
workload_types=("b")
runs=3
fieldlength=9
field_len_dist="uniform"
operationcount=100000000
recordcount=100000000
target_file_size_base=134217728 #128MB
size_ratio=10
level_size_base=$(echo "${target_file_size_base} * 4" | bc)
#operationcount=100000
#recordcount=100000
dynamic_cmpct="false"
#block_cache_size=419430400
#block_cache_size=209715200
#block_cache_size=104857600
#block_cache_size=536870912
#block_cache_size=2684354560  #50GB data
#block_cache_size=2147483648 #40GB data
#block_cache_size=1610612736 #30GB data
#block_cache_size=1073741824 #20GB data
block_cache_size=536870912 #10GB data
bpk=2
threads=16
methods=("mnemosyne-plus" "mnemosyne" "default")
#methods=("default")
# Remember to specify your database path here to use a dedicated storage device
DB_HOME="/data/ycsb_working_home/"
#DB_HOME="./"
DB_HOME="/scratchNVM1/zczhu/test_db_dir2/ycsb_working_home"
cp rocksdb/rocksdb.properties rocksdb/rocksdb.origin_properties
sed -i "s|rocksdb\.dbname=.*|rocksdb.dbname=${DB_HOME}|g" rocksdb/rocksdb.properties
mkdir -p "exp"
for i in `seq 1 ${runs}`
do
  mkdir -p "exp/run${i}"
  for method in ${methods[@]}
  do
	cp rocksdb/options.ini rocksdb/origin_options.ini
	cp rocksdb/options-exp-${method}.ini rocksdb/options.ini
	sed -i "s|block_cache={capacity=33554432}|block_cache={capacity=${block_cache_size}}|g" rocksdb/options.ini
	sed -i "s|level_compaction_dynamic_level_bytes=true|level_compaction_dynamic_level_bytes=${dynamic_cmpct}|g" rocksdb/options.ini
	sed -i "s|target_file_size_base=33554432|target_file_size_base=${target_file_size_base}|g" rocksdb/options.ini
	sed -i "s|write_buffer_size=33554432|write_buffer_size=${target_file_size_base}|g" rocksdb/options.ini
	sed -i "s|max_bytes_for_level_base=134217728|max_bytes_for_level_base=${level_size_base}|g" rocksdb/options.ini
	sed -i "s|max_bytes_for_level_multiplier=4|max_bytes_for_level_multiplier=${size_ratio}|g" rocksdb/options.ini
  	for workload_type in ${workload_types[@]}
  	do
	  cp workloads/workload${workload_type} workloads/workload-temp
	  echo "fieldlength=${fieldlength}" >> workloads/workload-temp
	  echo "field_len_dist=${field_len_dist}" >> workloads/workload-temp
	  sed -i "s/operationcount=100000/operationcount=${operationcount}/g" workloads/workload-temp
	  sed -i "s/recordcount=100000/recordcount=${recordcount}/g" workloads/workload-temp
	  sed -i "s/bloomfilter:5:false/bloomfilter:${bpk}:false/g" rocksdb/options.ini
	  if [ ${method} == "default" ]; then
		make clean && make EXTRA_CXXFLAGS="-I../rocksdb-8.9.1/include" EXTRA_LDFLAGS="-L../rocksdb-8.9.1 -ldl -lz -lsnappy -lzstd -lbz2 -llz4"
	  	echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 | tee "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt""
          	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 > "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt"
		make clean && make EXTRA_CXXFLAGS="-I../skew-aware-rocksdb-8.9.1/include" EXTRA_LDFLAGS="-L../skew-aware-rocksdb-8.9.1 -ldl -lz -lsnappy -lzstd -lbz2 -llz4"
	  else
	        sed -i "s|max_bits_per_key_granularity=5|max_bits_per_key_granularity=${bpk}|g" rocksdb/options.ini
          	echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 > "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt""
          	#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../skew-aware-rocksdb-8.9.1 ./ycsb -load -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 > "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt"
          	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../skew-aware-rocksdb-8.9.1 ./ycsb -load -run -db rocksdb -threads ${threads} -P workloads/workload-temp -P rocksdb/rocksdb.properties -s -p status.interval=120 > "exp/run${i}/${method}_workload${workload_type}_ycsb_result.txt"
	  fi
	  grep -A60 "DUMPING STATS" ${DB_HOME}/LOG > exp/run${i}/${method}_workload${workload_type}_ycsb_dumped_stats.txt
	  mv ${DB_HOME}/LOG exp/run${i}/${method}_workload${workload_type}_ycsb_LOG.txt
	  cat workloads/workload-temp > "exp/run${i}/workload${workload_type}.txt"
	  rm workloads/workload-temp
	  rm ${DB_HOME}/*
  	done
	mv rocksdb/origin_options.ini rocksdb/options.ini
  done
done
mv rocksdb/rocksdb.origin_properties rocksdb/rocksdb.properties
