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
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]
  snpeff_ens: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "GRCh38.86"}
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]
