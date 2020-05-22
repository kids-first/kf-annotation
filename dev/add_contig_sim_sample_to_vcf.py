import sys
import argparse
import os
import gzip
import pdb

parser = argparse.ArgumentParser(description='Add contigs to vcf header and faux FORMAT and SAMPLE fields')
parser.add_argument('-v', '--vcf-file', action='store', dest='vcf', help='Input vcf to add formatting to')
parser.add_argument('-i', '--fasta-index', action='store', dest='fai', help='Optional, if needed, use reference fasta index file to populate contig headers')
parser.add_argument('-s', '--sample-name', action='store', dest='sample', help='Optional, create a custom sample name')
parser.add_argument('-d', '--description', action='store', dest='desc', help='Optional, add description field. ## will be prepended, must be valid xml foramt')

args = parser.parse_args()

in_vcf = gzip.open(args.vcf)

sample_name = "SAMPLE"
if args.sample:
    sample_name = args.sample
for line in in_vcf:
    decoded = line.decode().rstrip('\n')
    if decoded[0:6] == "#CHROM":
        sys.stdout.write("##FORMAT=<ID=GT,Number=1,Type=String,Description=\"GT\">\n")
        if args.fai:
            # output contig headers: ##contig=<ID=chr1,length=248956422>
            for chrom in open(args.fai):
                c_info = chrom.split('\t')
                sys.stdout.write("##contig=<ID=" + c_info[0] + ",length=" + c_info[1] + ">\n")
        if args.desc:
            sys.stdout.write("##" + args.desc + "\n")
        sys.stdout.write(decoded + "\tFORMAT\t" + sample_name +  "\n")
        break
    else:
        print (decoded)

for line in in_vcf:
    decoded = line.decode().rstrip('\n')
    sys.stdout.write(decoded + "\tGT\t0/0\n")
