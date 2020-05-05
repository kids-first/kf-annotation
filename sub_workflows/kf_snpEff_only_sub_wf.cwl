cwlVersion: v1.0
class: Workflow
id: kf_snpEff_only_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  snpEff_ref_tar_gz: File
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}

outputs:
  snpEff_hg38: 
    type: File
    outputSource: snpeff_hg38/output_vcf
  snpEff_ens: 
    type: File
    outputSource: snpeff_ens/output_vcf

steps:
  snpeff_hg38: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "hg38"}
      cores: cores
      ram: ram
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]
  snpeff_ens: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "GRCh38.86"}
      cores: cores
      ram: ram
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]
$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 2