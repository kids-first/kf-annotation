import sys
import argparse
from pysam import VariantFile

parser = argparse.ArgumentParser(description='Extract fields from vcf(s) and convert to table format')
parser.add_argument('-v', '--vcf', action='store', dest='vcf', help='VCF file to subset')
parser.add_argument('-n', '--n-lines', action='store', dest='n', help='num lines to skip')

args = parser.parse_args()

vcf_in = VariantFile(args.vcf)

sys.stdout.write(str(vcf_in.header))
skip = int(args.n)
i = 0
for record in vcf_in.fetch():
    if i % skip == 0:
        sys.stdout.write(str(record))
    i += 1
