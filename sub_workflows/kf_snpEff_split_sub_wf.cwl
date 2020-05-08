cwlVersion: v1.0
class: Workflow
id: kf_snpEff_split_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  reference_dict: File
  snpeff_ref_name:
    type:
      - "null"
      - type: array
        items:
            type: enum
            name: snpeff_ref_name
            symbols: [hg38,hg38kg,GRCh38.86]
  scatter_bed: File
  scatter_ct: {type: int?, default: 50, doc: "Number of files to split scatter bed into"}
  bands: {type: int?, default: 80000000, doc: "Max bases to put in an interval. Set high for WGS, can set lower if snps only"}
  output_basename: string
  wf_tool_name: string
  snpEff_ref_tar_gz: {type: File, doc: "Pre-built snpeff cache with all refs that are to be run in wf"}
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}

outputs:
  snpEff_results: {type: Directory, outputSource: output_to_dir/output_dirs}
steps:
  gatk_intervallisttools:
    run: ../tools/gatk_intervallisttool.cwl
    in:
      interval_list: scatter_bed
      reference_dict: reference_dict
      scatter_ct: scatter_ct
      bands: bands
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
  run_snpeff: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: snpeff_ref_name
      cores: cores
      ram: ram
      input_vcf: bedtools_split_vcf/intersected_vcf
      output_basename: output_basename
      tool_name: wf_tool_name
    scatter: [reference_name, input_vcf]
    scatterMethod: nested_crossproduct
    out: [output_vcf]
  output_to_dir:
    run: ../tools/output_to_dir.cwl
    in:
      input_scatter: run_snpeff/output_vcf
      protocol_name: snpeff_ref_name
      tool_name: wf_tool_name
      output_basename: output_basename
    out: [output_dirs]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 3
