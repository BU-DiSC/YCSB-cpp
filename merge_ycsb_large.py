import sys

runs = int(sys.argv[1])
exp_dir = sys.argv[2]
workload = "b" 
methods = ["mnemosyne-plus", "mnemosyne", "default"]
scales = ["10G", "20G", "30G", "40G", "50G"]
dynamic=False
scale_suffix = "-exp-bpk-2-th16"
if dynamic:
    scale_suffix += "-dynamic"
else:
    scale_suffix += "-no-dynamic"

def aggregate(filename, result, scale_index):
    infile = open(filename, "r")
    data = infile.readlines()
    infile.close()
    for i in range(len(data)):
        line = data[i].strip()
        if line.startswith("Load throughput") and workload == "Load":
            result[scale_index] += float(line.split(':')[-1].strip())
            break
        elif line.startswith("Run throughput") and workload != "Load":
            result[scale_index] += float(line.split(':')[-1].strip())
            break

def output(filename, result):
    outfile = open(filename, "w")
    header = "scales"
    for m in methods:
        header += "," + m
    header += "\n"
    outfile.write(header)
    for i in range(len(scales)):
        line = scales[i]
        for m in methods:
            line += "," + str(round(result[m][i],2))
        line += "\n"
        outfile.write(line)
    outfile.close()


total_results = dict()
for i in range(len(methods)): 
    total_results[methods[i]] = [0 for _ in scales]
    for j in range(len(scales)):
        for k in range(1, runs+1):
            aggregate(exp_dir + "/" + scales[j] + scale_suffix + "/run" + str(k) + "/" + methods[i] + "_workload" + workload + "_ycsb_result.txt", total_results[methods[i]], j)
    for j in range(len(scales)):
        total_results[methods[i]][j] /= runs*1.0

if dynamic:
    output(exp_dir + "/ycsb_scalability_workload" + workload + "_dynamic_exp.txt", total_results)
else:
    output(exp_dir + "/ycsb_scalability_workload" + workload + "_no_dynamic_exp.txt", total_results)



