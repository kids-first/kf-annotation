cwlVersion: v1.0
class: CommandLineTool
id: bedtools_split_vcf
doc: "Split vcf into smaller, easier to process VCFs"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: DockerRequirement
    dockerPull: 'kfdrc/vcfutils:latest'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      bedtools intersect -a $(inputs.input_vcf.path) -b $(inputs.input_bed_file.path) -header
      | bgzip -c > $(inputs.input_bed_file.nameroot).vcf.gz

      tabix $(inputs.input_bed_file.nameroot).vcf.gz
inputs:
    input_vcf: {type: File?, secondaryFiles: ['.tbi'], doc: "Made optional so that in a pipeline, this can be skipped"}
    input_bed_file: File

outputs:
  intersected_vcf:
    type: File?
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']