cwlVersion: v1.0
class: Workflow
id: kf_annovar_w_preprocess_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  wf_tool_name: string
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}
  reference_dict : File
  scatter_bed: File
  scatter_ct: {type: int?, default: 50, doc: "Number of files to split scatter bed into"}
  bands: {type: int?, default: 80000000, doc: "Max bases to put in an interval. Set high for WGS, can set lower if snps only"}
  ANNOVAR_run_dbs_refGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for refGene protocol? true/false"}
  ANNOVAR_run_dbs_ensGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for ensGene protocol? true/false"}
  ANNOVAR_run_dbs_knownGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for knownGene protocol? true/false"}

outputs:
  ANNOVAR_refGene: 
    type: File
    outputSource: merge_refgene_results/merged_annovar_txt
  ANNOVAR_ensGene: 
    type: File
    outputSource: merge_ensgene_results/merged_annovar_txt
  ANNOVAR_knownGene:
    type: File
    outputSource: merge_knowngene_results/merged_annovar_txt

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
  annovar_preprocess:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/annovar_preprocess.cwl
    in:
      input_vcf: bedtools_split_vcf/intersected_vcf
    scatter: [input_vcf]
    out: [vcf_to_gz_annovar]
  annovar_refgene:
    run: ../tools/annovar_av_input.cwl
    in:
      cache: ANNOVAR_cache
      ram: ram
      cores: cores
      protocol_name: {default: "refGene"}
      input_av: annovar_preprocess/vcf_to_gz_annovar
      tool_name: wf_tool_name
      run_dbs: ANNOVAR_run_dbs_refGene
    scatter: [input_av]
    out: [anno_txt]
  annovar_ensgene:
    run: ../tools/annovar_av_input.cwl
    in:
      cache: ANNOVAR_cache
      ram: ram
      cores: cores
      protocol_name: {default: "ensGene"}
      input_av: annovar_preprocess/vcf_to_gz_annovar
      tool_name: wf_tool_name
      run_dbs: ANNOVAR_run_dbs_ensGene
    scatter: [input_av]
    out: [anno_txt]
  annovar_knowngene:
    run: ../tools/annovar_av_input.cwl
    in:
      cache: ANNOVAR_cache
      ram: ram
      cores: cores
      protocol_name: {default: "knownGene"}
      input_av: annovar_preprocess/vcf_to_gz_annovar
      tool_name: wf_tool_name
      run_dbs: ANNOVAR_run_dbs_knownGene
    scatter: [input_av]
    out: [anno_txt]
  merge_refgene_results:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.2xlarge;ebs-gp2;2048
    run: ../tools/merge_annovar_txt.cwl
    in:
      input_anno: annovar_refgene/anno_txt
      protocol_name: {default: "refGene"}
      output_basename: output_basename
      tool_name: wf_tool_name
    out: [merged_annovar_txt]
  merge_ensgene_results:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.2xlarge;ebs-gp2;2048
    run: ../tools/merge_annovar_txt.cwl
    in:
      input_anno: annovar_ensgene/anno_txt
      protocol_name: {default: "ensGene"}
      output_basename: output_basename
      tool_name: wf_tool_name
    out: [merged_annovar_txt]
  merge_knowngene_results:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.2xlarge;ebs-gp2;2048
    run: ../tools/merge_annovar_txt.cwl
    in:
      input_anno: annovar_knowngene/anno_txt
      protocol_name: {default: "knownGene"}
      output_basename: output_basename
      tool_name: wf_tool_name
    out: [merged_annovar_txt]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 8
