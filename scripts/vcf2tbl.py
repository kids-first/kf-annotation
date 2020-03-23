import sys
import argparse
import json
import gzip
import concurrent.futures
from pysam import VariantFile
import os
import pdb


def mt_process_file(vcf_list, tool_list, v, head_out, temp_out):
    try:
        temp_out.append('temp_table_' + str(v) + '.txt')
        temp_write = open(temp_out[v], encoding="utf-8", mode="wt")
        if not tool_list[v].startswith('ANNOVAR'):
            data_in = VariantFile(vcf_list[v])
        else:
            data_in = gzip.open(vcf_list[v], mode="rt", encoding="utf-8")
        key = config_data[tool_list[v]]['key']
        f_pos_list = []
        desc_list = parse_desc_field(tool_list[v], key, data_in)
        if desc_list == 1:
            return 1
        ann_size = len(desc_list)
        header = []
        for i in range(0, ann_size, 1):
            if desc_list[i] in config_data[tool_list[v]]['field']:
                f_pos_list.append(i)
                config_data[tool_list[v]]['field'][desc_list[i]] = i
                header.append(tool_list[v] + "_" + desc_list[i])
        if v == 0:
            temp_write.write(head_out + "\t" + "\t".join(header) + '\n')
        else:
            temp_write.write("\t".join(header) + '\n')
        x = 1
        m = 100000
        w_ct = 0
        if not tool_list[v].startswith('ANNOVAR'):
            for record in data_in.fetch():
                (table_entry, w_ct, err) = vcf_parse(record, header, v, key, f_pos_list, tool_list[v], w_ct)
                if err == 1:
                    return 1
                temp_write.write(table_entry)
                if x % m == 0:
                    sys.stderr.write('Processed ' + str(x) + ' lines from ' + vcf_list[v] + '\n')
                    sys.stderr.flush()
                x += 1
        else:
            for record in data_in:
                (table_entry, err) = txt_parse(record, f_pos_list, v)
                if err == 1:
                    return 1
                temp_write.write(table_entry)
                if x % m == 0:
                    sys.stderr.write('Processed ' + str(x) + ' lines from ' + vcf_list[v] + '\n')
                    sys.stderr.flush()
                x += 1

        temp_write.close()
        if w_ct > 1:
            sys.stderr.write('Missing annotation warning caught ' + str(w_ct) + " times\n")
        sys.stderr.write('Completed processing ' + vcf_list[v] + '\n')
        return 0
    except Exception as e:
        sys.stderr.write(str(e) + ' error processing file ' + vcf_list[v] + '\n')
        sys.stderr.flush()
        return 1


def vcf_parse(record, header, v, key, f_pos_list, tool, w_ct):
    basic = "\t".join((record.contig, str(record.pos), record.ref, ','.join(record.alts)))
    (table_fmt, w_ct, err) = parse_split_pipe(record, header, key, f_pos_list, tool, w_ct)
    if err == 1:
        return 1, 1, 1
    if v == 0:
        return (basic + "\t" + table_fmt + "\n", w_ct, err)
    else:
        return (table_fmt + "\n", w_ct, err)


def txt_parse(record, f_pos_list, v):
    try:
        info = record.rstrip('\n').split('\t')
        basic = "\t".join((info[0], info[1], info[3], info[4]))
        table_fmt = parse_table(record, f_pos_list)
        if v == 0:
            return basic + "\t" + table_fmt + "\n", 0
        else:
            return table_fmt + "\n", 0
    except Exception as e:
        sys.stderr.write(str(e) + "\nError parsing annovar table\n")
        return 1, 1


def parse_desc_field(tool, key, vcf_obj):
    if tool == 'VEP':
        try:
            desc_string = vcf_obj.header.info[key].record['Description']
            desc_string = desc_string.lstrip('"')
            desc_string = desc_string.rstrip('"')
            desc_string = desc_string.replace('Consequence annotations from Ensembl VEP. Format: ', '')
            return desc_string.split('|')
        except Exception as e:
            sys.stderr.write(str(e) + "\nERROR: Cannot process header for VEP file\n")
            return 1
    elif tool == 'snpEff':
        try:
            desc_string = vcf_obj.header.info[key].record['Description']
            desc_string = desc_string.lstrip('"')
            desc_string = desc_string.rstrip('"')
            desc_string = desc_string.replace("Functional annotations: ","")
            desc_string = desc_string.lstrip('\'')
            desc_string = desc_string.rstrip('\'')
            return desc_string.split(" | ")
        except Exception as e:
            sys.stderr.write(str(e) + "\nERROR: Cannot process header for snpEff file\n")
            return 1
    elif tool.startswith('ANNOVAR'):
        try:
            tbl_head = next(vcf_obj)
            return tbl_head.rstrip('\n').split('\t')
        except Exception as e:
            sys.stderr.write(str(e) + "\nERROR: Cannot process header for ANNOVAR file\n")
            return 1
    else:
        sys.stderr.write('Tool does not match any patterns in parse_desc_field. Check vcf config and tool_csv param and try again.\n')
        return 1


def parse_split_pipe(record, header, key, f_pos_list, tool, w_ct):
    # pysam already creates an array for info on each isoform, need to split so that related info can be in the same field
    if key in record.info:
        ann_list =  [_.split('|') for _ in record.info[key]]
        temp = []
        # init temp
        for head in header:
            temp.append([])
        for ann in ann_list:
            for i in range(0, len(f_pos_list), 1):
                temp[i].append(ann[f_pos_list[i]])
        for a in range(len(temp)):
            # if empty, or all entries empty, just put a dot. formula from stack overflow
            if all(s == '' or s.isspace() for s in temp[a]):
                    temp[a] = '.'
            else:
                temp[a] = '|'.join(temp[a])
        rstring = "\t".join(temp)
        return (rstring, w_ct, 0)
    else:
        w_ct += 1
        if w_ct == 1:
            sys.stderr.write("WARNING: Caught error while processing " + tool + " VCF. Known issue on missing annotation, will output as blanks\n")
        temp = []
        # init temp
        for head in header:
            temp.append('.')
        rstring = "\t".join(temp)
        return (rstring, w_ct, 0)


def parse_table(record, f_pos_list):
    info = record.rstrip('\n').split('\t')
    temp = []
    for f in f_pos_list:
        temp.append(info[f].replace(';', '|'))
    del info
    rstring = "\t".join(temp)
    del temp
    return rstring


parser = argparse.ArgumentParser(description='Extract fields from vcf(s) and conver to table format')
parser.add_argument('-v', '--vcf-csv', action='store', dest='vcf_csv', help='List of vcf files, (or annovar txt) as csv str, to process')
parser.add_argument('-t', '--tool-csv', action='store', dest='tool_csv', help='List of tool keys, as csv str from config file, in same order as vcf_csv list')
parser.add_argument('-c', '--config', action='store', dest='config_file', help='json config file with data types and '
                                                                               'data locations')
args = parser.parse_args()

# list vcf in order of tool that produced it
vcf_csv = args.vcf_csv
config_file = open(args.config_file)
tool_csv = args.tool_csv
# first key is tool name, all subkeys annotations to grab from vcf
config_data = json.load(config_file)
config_file.close()
vcf_list = vcf_csv.split(',')
tool_list = tool_csv.split(',')
head_out = "CHROM\tPOS\tREF\tALT"
if tool_list[0].startswith('ANNOVAR'):
    sys.stderr.write('WARNING: ANNOVAR alters the start position and variant values for indels. Consider using a vcf first to init those values\n')
temp_out = []

with concurrent.futures.ThreadPoolExecutor(16) as executor:
    results = {executor.submit(mt_process_file, vcf_list, tool_list, v, head_out, temp_out): v for v in range(0, len(vcf_list), 1)}
    for result in concurrent.futures.as_completed(results):
        if result.result() == 1:
            sys.stderr.write('Ran into an error that would lead to incomplete output. Exiting\n')
            os.system('kill %d' % os.getpid())

# for v in range(0, len(vcf_list), 1):
#     mt_process_file(vcf_list, tool_list, v, head_out, temp_out)

final_output = open('merged_tbl.txt', encoding="utf-8", mode="wt")
file_io = []
sys.stderr.write("Completed temp tables.  Outputting final merged table\n")
x = 1
m = 100000

for fname in temp_out:
    file_io.append(open(fname, mode="rt", encoding="utf-8"))
for line in file_io[0]:
    if x % m == 0:
        sys.stderr.write('Processed ' + str(x) + ' records\n')
        sys.stderr.flush()

    final_output.write(line.rstrip('\n'))
    for i in range(1, len(file_io) - 1, 1):
        concat = next(file_io[i])
        final_output.write("\t" + concat.rstrip('\n'))
    if len(file_io) > 2:
        concat = next(file_io[-1])
        final_output.write("\t" + concat)
    else:
        final_output.write("\n")
    x += 1

for io in file_io:
    io.close()
final_output.close()
