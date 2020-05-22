cwlVersion: v1.0
class: CommandLineTool
id: bcftools_isec_unknown
doc: "Uses bcftools isec to output alleles specific to one vcf and not the other"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/vcfutils:latest'

baseCommand: [bcftools, isec]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      $(inputs.ref_vcf.path)
      $(inputs.input_vcf.path)
      -p INTERSECTED_RESULTS
      -O z
      --threads 4
      && mv INTERSECTED_RESULTS/0001.vcf.gz ./$(inputs.output_basename).$(inputs.tool_name).unk.vcf.gz
      && tabix $(inputs.output_basename).$(inputs.tool_name).unk.vcf.gz
inputs:
    input_vcf: {type: File, secondaryFiles: ['.tbi'], doc: "VCF to search for novel variants compared to a reference vcf"}
    ref_vcf: {type: File, secondaryFiles: ['.tbi'], doc: "Reference vcf with common/expected variants"}
    output_basename: string
    tool_name: string

outputs:
  intersected_vcf:
    type: File
    outputBinding:
      glob: '*.unk.vcf.gz'
    secondaryFiles: ['.tbi']
