cwlVersion: v1.0
class: CommandLineTool
id: zcat_vcf_outputs
doc: "Merges outputs from a vcf scatter job"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
  - class: DockerRequirement
    dockerPull: 'kfdrc/samtools:1.9'

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      cat $(inputs.header_file.path) | bgzip -c > $(inputs.output_basename).$(inputs.tool_name).vcf.gz

      find $(inputs.input_vcfs[0].dirname.replace(/_\d+_s$/, ""))* -name "*$(inputs.input_vcfs[0].nameext)"
      | sort -V
      | xargs -IFN zcat FN
      | grep -vE "^#"
      | bgzip -c -@ 8 >> $(inputs.output_basename).$(inputs.tool_name).vcf.gz

      bgzip -r -@ 8 -I $(inputs.output_basename).$(inputs.tool_name).vcf.gz.tbi $(inputs.output_basename).$(inputs.tool_name).vcf.gz

inputs:
    input_vcfs: {type: 'File[]', doc: "List of files from vcf scatter job"}
    header_file: {type: File, doc: "File with header of VCFs. Basically a hack to avoid guessing/parsing the file"}
    tool_name: { type: string, doc: "String of tool name that will be used in the output filenames"}
    output_basename: { type: string, doc: "String that will be used in the output filenames" }

outputs:
  zcat_merged_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']
