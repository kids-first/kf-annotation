cwlVersion: v1.0
class: CommandLineTool
id: vcf2tbl
doc: "Parse annotation calls from VEP and snpEff vcfs, ANNOVAR tables, grab desired fields, convert to a multi-caller merged table"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'migbro/python:3.6.9'

baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      VCF_CSV=${
          var paths = [];
          for (var i=0; i < inputs.input_vcfs.length; i++){
              paths.push(inputs.input_vcfs[i].path);
          }
          return paths.join(",");
      }

      python3 /opt/vcf2tbl.py -v $VCF_CSV -t $(inputs.tool_csv) -c $(inputs.config_json.path)

      mv merged_tbl.txt $(inputs.output_basename).merged_calls.txt

      pigz $(inputs.output_basename).merged_calls.txt


inputs:
    input_vcfs: {type: 'File[]', doc: "Annotated vcfs from VEP and snpEff, annotation tables from ANNOVAR. All gzipped"}
    tool_csv: {type: string, doc: "csv string in order of vcf array load, matching each file with the key in the config file"}
    config_json: {type: File, doc: "Config file with tool desc as main key, \"field\" and \"key\" as subkeys"}
    output_basename: string

outputs:
  output_txt_gz:
    type: File
    outputBinding:
      glob: '*.txt.gz'
    doc: "Merged gzipped table with annotations from all callers"
