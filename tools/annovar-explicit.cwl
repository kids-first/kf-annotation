cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-annovar
label: Annovar
doc: |
  Simplified descrition of what this tool does:
    1. Untar the cache
    2. If you are running additional databases, untar those as well
    3. Run Annovar
    4. bgzip output VCF
    5. tavix output VCF.GZ
    6. bgzip output TXT

  Annovar parameters:
    1. out: the relative path of the output file
    2. buildver: the genome reference build
    3. protocol: list of the names of the protocols to be used in annotation of the input
    4. operation: list of annotation types to be used corresponding to each of the protocols
    5. argument: list of additional arguments to be used corresponding to each of the protocols
    6. vcfinput: the input is a properly formatted VCF and the program should return a properly formatted VCF as output
    7. thread: the number of threads this program may use
    8. remove: Remove intermediate files
    9. nastring: Replace NA with given value

  An example run of this tool will use a command like this:
    /bin/bash -c
    set -eo pipefail
    tar xvf /path/to/cache.ext &&
    tar xvf /path/to/additional_dbs-1.ext -C humandb &&
    tar xvf /path/to/additional_dbs-2.ext -C humandb &&
    perl /home/TOOLS/tools/annovar/current/bin/table_annovar.pl
      /path/to/input_vcf.ext
      humandb
      -out output_basename-string-value
      -buildver hg38
      -protocol ensGene,dbscsnv11,cosmic90_coding,1000g2015aug_all,esp6500siv2_all,gnomad30_genome
      -operation g,f,f,f,f,f
      -argument '--hgvs --splicing_threshold 10',,,,,
      -vcfinput
      -thread 16
      -remove
      -nastring . &&
    bgzip output_basename-string-value.hg38_multianno.vcf &&
    tabix -p vcf output_basename-string-value.hg38_multianno.vcf.gz &&
    bgzip output_basename-string-value.hg38_multianno.txt
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: $(inputs.ram)
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'kfdrc/annovar:latest'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      tar xvf $(inputs.cache.path) &&
      ${
        var cmd = "";
        if (inputs.dbscsnv_db) { 
          cmd += "tar xvf " + inputs.dbscsnv_db.path + " -C humandb && ";
        }
        if (inputs.cosmic_db) {
          cmd += "tar xvf " + inputs.cosmic_db.path + " -C humandb && ";
        }
        if (inputs.kg_db) {
          cmd += "tar xvf " + inputs.kg_db.path + " -C humandb && ";
        }
        if (inputs.esp_db) {
          cmd += "tar xvf " + inputs.esp_db.path + " -C humandb && ";
        }
        if (inputs.gnomad_db) {
          cmd += "tar xvf " + inputs.gnomad_db.path + " -C humandb && ";
        }
        if (inputs.run_dbs) {
          return cmd;
        } else {
          return "";
        }
      }
      perl /home/TOOLS/tools/annovar/current/bin/table_annovar.pl
      $(inputs.input_vcf.path)
      humandb
      -out $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name)
      -buildver hg38
      ${
        var prot = "-protocol " + inputs.protocol_name
        var oper = "-operation g"
        var argu = "-argument '--hgvs --splicing_threshold 10'"
        if (inputs.run_dbs) {
          if (inputs.dbscsnv_db) {
            prot = prot + ",dbscsnv11"
            oper = oper + ",f"
            argu = argu + ","
          }
          if (inputs.cosmic_db) {
            prot = prot + ",cosmic90_coding"
            oper = oper + ",f"
            argu = argu + ","
          }
          if (inputs.kg_db) {
            prot = prot + ",1000g2015aug_all"
            oper = oper + ",f"
            argu = argu + ","
          }
          if (inputs.esp_db) {
            prot = prot + ",esp6500siv2_all"
            oper = oper + ",f"
            argu = argu + ","
          }
          if (inputs.gnomad_db) {
            prot = prot + ",gnomad30_genome"
            oper = oper + ",f"
            argu = argu + ","
          }
          return prot + " " + oper + " " + argu
        }
        else {
          return prot + " " + oper + " " + argu
        }
      }
      -vcfinput
      -thread 16
      -maxgenethread 16
      -remove
      -nastring . &&
      bgzip $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.vcf &&
      tabix -p vcf $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.vcf.gz &&
      bgzip $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.txt

inputs:
  cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ram: {type: int?, default: 32000, doc: "May need to increase this value depending on the size/complexity of input"}
  dbscsnv_db: { type: 'File?', doc: "dbscSNV database tgz downloaded from Annovar" }
  cosmic_db: { type: 'File?', doc: "COSMIC database tgz downloaded from COSMIC" }
  kg_db: { type: 'File?', doc: "1000genomes database tgz downloaded from Annovar" }
  esp_db: { type: 'File?', doc: "ESP database tgz downloaded from Annovar" }
  gnomad_db: { type: 'File?', doc: "gnomAD tgz downloaded from Annovar" }
  protocol_name: { type: { type: enum, symbols: [ensGene, knownGene, refGene] }, doc: "Gene-based annotation to be used in this run of the tool" }
  input_vcf: { type: File, secondaryFiles: [.tbi], doc: "VCF file (with associated index) to be annotated" }
  run_dbs: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool? true/false" }
  output_basename: { type: string, doc: "String that will be used in the output filenames" }
  tool_name: { type: string, doc: "String of tool name that will be used in the output filenames" }

outputs:
  anno_txt: { type: File, outputBinding: { glob: '*.txt.gz' } }
  anno_vcf: { type: File, outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: ['.tbi'] }
