cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-annovar-av
label: Annovar AV Input
doc: |
  ANNOVAR annotate av input converted from vcf input
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: ${return inputs.ram * 1000}
    coresMin: $(inputs.cores)
  - class: DockerRequirement
    dockerPull: 'kfdrc/annovar:latest'
baseCommand: [set,-eo]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      pipefail

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

      zcat $(inputs.input_av.path) > $(inputs.input_av.nameroot)

      perl /home/TOOLS/tools/annovar/current/bin/table_annovar.pl
      $(inputs.input_av.nameroot)
      humandb
      -out $(inputs.input_av.nameroot).$(inputs.tool_name).$(inputs.protocol_name)
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
      -thread $(inputs.cores)
      -maxgenethread $(inputs.cores)
      -remove
      -otherinfo
      -nastring .
      && bgzip $(inputs.input_av.nameroot).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.txt

inputs:
  cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ram: {type: int?, default: 32, doc: "In GB, may need to increase this value depending on the size/complexity of input"}
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  dbscsnv_db: { type: 'File?', doc: "dbscSNV database tgz downloaded from Annovar" }
  cosmic_db: { type: 'File?', doc: "COSMIC database tgz downloaded from COSMIC" }
  kg_db: { type: 'File?', doc: "1000genomes database tgz downloaded from Annovar" }
  esp_db: { type: 'File?', doc: "ESP database tgz downloaded from Annovar" }
  gnomad_db: { type: 'File?', doc: "gnomAD tgz downloaded from Annovar" }
  protocol_name: { type: { type: enum, symbols: [ensGene, knownGene, refGene] }, doc: "Gene-based annotation to be used in this run of the tool" }
  input_av: { type: File, doc: "gzipped annovar input file converted from vcf" }
  run_dbs: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool? true/false" }
  tool_name: { type: string, doc: "String of tool name that will be used in the output filenames" }

outputs:
  anno_txt: { type: File, outputBinding: { glob: '*.txt.gz' } }
