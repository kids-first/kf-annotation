import sys
import argparse
import json
import gzip
from pysam import VariantFile
import os


parser = argparse.ArgumentParser(description='Compare called vcf to a reference vcf and output vars seen in called and not in ref')
parser.add_argument('-r', '--reference-vcf', action='store', dest='ref_vcf', help='reference vcf, like dbSNP, to compare to')
parser.add_argument('-c', '--called-vcf', action='store', dest='call_vcf', help='Called vcf to search for variants not found in reference vcf')
parser.add_argument('-o', '--out-vcf', action='store', dest='out_vcf', help='Output vcf that is a subset of called vcf meeting criteria')

args = parser.parse_args()

ref_vcf = VariantFile(args.ref_vcf)
called_vcf = VariantFile(args.call_vcf, threads=4)
out_vcf = VariantFile(args.out_vcf, "w", header=called_vcf.header, threads=4)
x = 0
m = 1000
for record in called_vcf.fetch():
    if x % m == 0:
        sys.stderr.write('Processed ' + str(x) + " records\n")
        sys.stderr.flush()
    f = 0
    for comp in ref_vcf.fetch(record.contig, record.start, record.stop):
        if record.pos == comp.pos and record.alleles == comp.alleles:
            f = 1
            break
    if not f:
        out_vcf.write(record)
    x += 1
out_vcf.close()
ref_vcf.close()
called_vcf.close()