import sys
import argparse
import os
import pdb


parser = argparse.ArgumentParser(description='Create simulated vcf')
parser.add_argument('-r', '--reference-fasta', action='store', dest='fasta', help='Reference fasta to check')
parser.add_argument('-i', '--reference-index', action='store', dest='fai', help='Reference fai to populate vcf header')
parser.add_argument('-o', '--output-basename', action='store', dest='out', help='Output vcf base name')

args = parser.parse_args()
out_vcf = open(args.out + ".vcf", "w")
# output header
out_vcf.write("##fileformat=VCFv4.2\n")
for line in open(args.fai):
    chr_info = line.rstrip('\n').split('\t')
    out_vcf.write("##contig=<ID=" + chr_info[0] + ",length=" + chr_info[1] + ">\n")
out_vcf.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSIMULATED\n")

chrom = ""
pos = 1
snp_dict = {"A": ",".join(["C", "G", "T"]), 
            "C": ",".join(["A", "G", "T"]),
            "T": ",".join(["A", "C", "G"]),
            "G": ",".join(["A", "C", "T"]),
            "a": ",".join(["c", "g", "t"]), 
            "c": ",".join(["a", "g", "t"]),
            "t": ",".join(["a", "c", "g"]),
            "g": ",".join(["a", "c", "t"])}
m = 100000
x = 1
for line in open(args.fasta):
    if x % m == 0:
        sys.stderr.write("Processed " + str(x) + " lines\n")
        sys.stderr.flush()
    if line[0] == ">":
        c = line.split()
        chrom = c[0][1:]
        pos = 1
    else:
        for i in range(0, len(line.rstrip("\n")), 1):
            if line[i] in snp_dict:
                out_vcf.write("\t".join([chrom, str(pos), ".", line[i], snp_dict[line[i]], ".", "GT", "0/1"]) + "\n")
            pos += 1
    x += 1
out_vcf.close()