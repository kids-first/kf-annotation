cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-annovar
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 24000
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
        for (var i=0; i < inputs.additional_dbs.length; i++){
          cmd += "tar xvf " + inputs.additional_dbs[i].path + " -C humandb && ";
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
      -out $(inputs.output_basename)
      -buildver hg38
      -protocol $(inputs.protocol_name)${if (inputs.run_dbs) { return ",dbnsfp35c,clinvar_20190305,dbscsnv11,cosmic90_coding,1000g2015aug_all,esp6500siv2_all,exac03,gnomad30_genome" } else { return "" }}
      -operation g${if (inputs.run_dbs) { return ",f,f,f,f,f,f,f,f" } else { return "" }}
      -argument '--hgvs --splicing_threshold 10'${if (inputs.run_dbs) { return ",,,,,,,," } else { return ""}}
      -vcfinput
      -thread 16
      -remove
      -nastring . &&
      bgzip $(inputs.output_basename).hg38_multianno.vcf &&
      tabix -p vcf $(inputs.output_basename).hg38_multianno.vcf.gz &&
      bgzip $(inputs.output_basename).hg38_multianno.txt

inputs:
  cache: File
  additional_dbs: File[]
  protocol_name:
    type:
      type: enum
      symbols: [ensGene, knownGene, refGene]
  input_vcf:
    type: File
    secondaryFiles: [.tbi]
  run_dbs: boolean
  output_basename: string

outputs:
  anno_txt:
    type: File
    outputBinding:
      glob: $(inputs.output_basename).hg38_multianno.txt.gz
  anno_vcf:
    type: File
    outputBinding:
      glob: $(inputs.output_basename).hg38_multianno.vcf.gz
  anno_tbi:
    type: File
    outputBinding:
      glob: $(inputs.output_basename).hg38_multianno.vcf.gz.tbi
