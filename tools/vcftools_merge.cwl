cwlVersion: v1.0
class: CommandLineTool
id: vcftools_merge_vcf
doc: "Quick tool merge annotations from multiple annotation callers into a single vcf"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/vcfutils:latest'

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      vcf-merge

  - position: 2
    shellQuote: false
    valueFrom: >-
      | bgzip -@ 4 -c > $(inputs.output_basename).$(inputs.tool_name).merged_anno.vcf.gz

      tabix $(inputs.output_basename).$(inputs.tool_name).merged_anno.vcf.gz

inputs:
    input_vcfs:
      type:
        type: array
        items: File
      secondaryFiles: [.tbi]
      inputBinding:
        position: 1

    output_basename: string
    tool_name: string

outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: '*.merged_anno.vcf.gz'
    secondaryFiles: ['.tbi']
