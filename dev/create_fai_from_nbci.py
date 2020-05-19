import sys
import argparse
import os
import gzip
import re
import pdb


parser = argparse.ArgumentParser(description='Convert NCBI xml to UCSC compatible fai')
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
        l_idx = head.index("Sequence-Length")
        break

if u_idx > 0 or n_idx > 0:
    sys.stderr.write('Labels found, populating conversion dict\n')
else:
    sys.stderr.write('Could not correct columns in header. Check logic and inputs and try again\n')
    exit(1)
running = 0
for line in tbl:
    info = line.rstrip('\n').split('\t')
    out_write = ""
    if info[u_idx] != "na":
        out_write = info[u_idx] + "\t" + info[l_idx] + "\t" + str(running) + "\t100\t101"
    else:
        out_write = info[n_idx] + "\t" + info[l_idx] + "\t" + str(running) + "\t100\t101"
    print(out_write)
    running += int(info[l_idx])
tbl.close()
