cwlVersion: v1.0
class: CommandLineTool
id: merge_annovar_outputs
doc: "Merges outputs from annovar scatter job"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
  - class: DockerRequirement
    dockerPull: 'kfdrc/vcfutils:latest'

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      echo "$(inputs.header_str)" | bgzip -c > $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.txt.gz

      find $(inputs.input_anno[0].dirname.replace(/_\d+_s$/, ""))* -name "*$(inputs.input_anno[0].nameext)"
      | sort -V
      | xargs -IFN zcat FN
      | grep -vE "^Chr"
      | bgzip -c >> $(inputs.output_basename).$(inputs.tool_name).$(inputs.protocol_name).hg38_multianno.txt.gz

inputs:
    input_anno: {type: 'File[]', doc: "List of files from annovar scatter job"}
    header_str: {type: string?, default: "Chr\tStart\tEnd\tRef\tAlt\tFunc.refGene\tGene.refGene\tGeneDetail.refGene\tExonicFunc.refGene\tAAChange.refGene\tOtherinfo", doc: "anticipated header of annovar table. basically a hack to avoid guessing/parsing the file"}
    protocol_name: { type: { type: enum, symbols: [ensGene, knownGene, refGene] }, doc: "Gene-based annotation to be used in this run of the tool" }
    tool_name: { type: string, doc: "String of tool name that will be used in the output filenames"}
    output_basename: { type: string, doc: "String that will be used in the output filenames" }

outputs:
  merged_annovar_txt:
    type: File
    outputBinding:
      glob: '*.hg38_multianno.txt.gz'
