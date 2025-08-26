#!/bin/bash
export FAST_DB_HOME="/scratchNVM0/zczhu/ycsb_working_home"
./run_ycsb_basic.sh 1
./run_ycsb_basic.sh 4
./run_ycsb_scale.sh 16 true
./run_ycsb_scale.sh 16 false
