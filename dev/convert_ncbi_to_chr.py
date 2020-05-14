import sys
import argparse
import os
import gzip
import re
import pdb


parser = argparse.ArgumentParser(description='Convert vcf with NCBI acession numbers to chr entries compatible with existing refs')
parser.add_argument('-v', '--reference-vcf', action='store', dest='vcf', help='Reference vcf to convert')
parser.add_argument('-t', '--ncbi-tbl', action='store', dest='table', help='NCBI table found here: https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.39_GRCh38.p13/GCF_000001405.39_GRCh38.p13_assembly_report.txt')

args = parser.parse_args()
id_dict = {}
tbl = open(args.table)
head_phrase = "# Sequence-Name"
# ucsc style chr, preferred
u_idx = 0
# ncbi backup if no ucsc
n_idx = 0
# acession number to replace
a_idx = 0
for line in tbl:
    if re.search(head_phrase, line):
        head = line.rstrip('\n').split('\t')
        u_idx = head.index("UCSC-style-name")
        n_idx = head.index(head_phrase)
        a_idx = head.index("RefSeq-Accn")
        break

if u_idx > 0 or n_idx > 0:
    sys.stderr.write('Labels found, populating conversion dict\n')
else:
    sys.stderr.write('Could not correct columns in header. Check logic and inputs and try again\n')
    exit(1)
for line in tbl:
    info = line.rstrip('\n').split('\t')
    if info[u_idx] != "na":
        id_dict[info[a_idx]] = info[u_idx]
    else:
        id_dict[info[a_idx]] = info[n_idx]
tbl.close()
sys.stderr.write('Finished dict, parsing vcf\n')
sys.stderr.flush()

warning = {}
vcf = gzip.open(args.vcf)

for data in vcf:
    line = data.decode()
    if line[0] == "#":
        sys.stdout.write(line)
    else:
        info = line.split('\t')
        if info[0] in id_dict:
            info[0] = id_dict[info[0]]
        elif info[0] not in warning:
            warning[info[0]] = 0
        else:
            warning[info[0]] += 1
        sys.stdout.write("\t".join(info))
vcf.close()

