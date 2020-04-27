import sys
import argparse
import os
import pdb

parser = argparse.ArgumentParser(description='Get ACTG-only bed, and non-ACTG summary')
parser.add_argument('-r', '--reference-fasta', action='store', dest='fasta', help='Reference fasta to check')

args = parser.parse_args()
chrom = ""
pos = 0
canon = ["A", "C", "T", "G", "a", "c", "t", "g"]
n_ct = 0
non_n_ct = {}
# get all non-ACTG pos
temp = []
m = 100000
x = 1
# track last entry for comparison
j = 0
# init matrix
for line in open(args.fasta):
    if x % m == 0:
        sys.stderr.write("Processed " + str(x) + " lines\n")
        sys.stderr.flush()
    if line[0] == ">":
        c = line.split()
        chrom = c[0][1:]
        pos = 0
    else:
        for i in range(0, len(line.rstrip("\n")), 1):
            if line[i] not in canon:
                start = pos + i
                end = pos + i + 1
                if len(temp) == 0:
                    temp.append([chrom, start, end, line[i]])
                else:
                    if chrom == temp[j][0] and temp[j][2] == start and temp[j][3] == line[i]:
                        temp[j][2] = end
                    else:
                        temp.append([chrom, start, end, line[i]])
                        j += 1
                if line[i] == "N" or line[i] == "n":
                    n_ct += 1
                elif line[i] not in non_n_ct:
                    non_n_ct[line[i]] = 0
                else:
                    non_n_ct[line[i]] += 1
        pos += len(line.rstrip("\n"))
    x += 1

sys.stderr.write("Finished getting positions\nSummary: N positions " + str(n_ct) + "\n")
for key in non_n_ct:
    sys.stderr.write(key + "\t" + str(non_n_ct[key]) + "\n")
sys.stderr.flush()
for i in range(len(temp)):
    temp[i][1] = str(temp[i][1])
    temp[i][2] = str(temp[i][2])
    print("\t".join(temp[i]))