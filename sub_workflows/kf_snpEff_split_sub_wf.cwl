cwlVersion: v1.0
class: Workflow
id: kf_snpEff_split_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  reference_dict : File
  scatter_bed: File
  output_basename: string
  tool_name: string
  snpEff_ref_tar_gz: File
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}

outputs:
  snpEff_hg38: 
    type: File
    outputSource: merge_snpeff_hg38_vcf/merged_vcf
  snpEff_ens: 
    type: File
    outputSource: merge_snpeff_ens_vcf/merged_vcf

steps:
  gatk_intervallisttools:
    run: ../tools/gatk_intervallisttool.cwl
    in:
      interval_list: scatter_bed
      reference_dict: reference_dict
      scatter_ct: {default: 50}
      bands: {default: 80000000}
    out: [output]
  bedtools_split_vcf:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/bedtools_split_vcf.cwl
    in:
      input_vcf: input_vcf
      input_bed_file: gatk_intervallisttools/output
    scatter: [input_bed_file]
    out: [intersected_vcf]
  snpeff_hg38: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "hg38"}
      cores: cores
      ram: ram
      input_vcf: bedtools_split_vcf/intersected_vcf
      output_basename: output_basename
      tool_name: tool_name
    scatter: [input_vcf]
    out: [output_vcf]
  snpeff_ens: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "GRCh38.86"}
      cores: cores
      ram: ram
      input_vcf: bedtools_split_vcf/intersected_vcf
      output_basename: output_basename
      tool_name: tool_name
    scatter: [input_vcf]
    out: [output_vcf]
  merge_snpeff_hg38_vcf:
    run: ../tools/gatk_mergevcfs.cwl
    in:
      input_vcfs: snpeff_hg38/output_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name: tool_name
    out: [merged_vcf]
  merge_snpeff_ens_vcf:
    run: ../tools/gatk_mergevcfs.cwl
    in:
      input_vcfs: snpeff_ens/output_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name: tool_name
    out: [merged_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 8