cwlVersion: v1.0
class: Workflow
id: kf_annovar_w_preprocess_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  run_vt_norm: {type: boolean?, doc: "Run vt decompose and normalize before annotation", default: true}
  wf_tool_name: string
  protocol_list:
    type:
      - "null"
      - type: array
        items:
            type: enum
            name: protocol_list
            symbols: [ensGene, knownGene, refGene]
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}
  reference: { type: 'File?',  secondaryFiles: [.fai], doc: "Fasta genome assembly with indexes" }
  reference_dict : File
  scatter_bed: File
  scatter_ct: {type: int?, default: 50, doc: "Number of files to split scatter bed into"}
  bands: {type: int?, default: 80000000, doc: "Max bases to put in an interval. Set high for WGS, can set lower if snps only"}
  run_dbs: { type: 'boolean[]', doc: "Should the additional dbs be processed in this run of the tool for each protocol in protocol list? true/false"}

outputs:
  ANNOVAR_results: {type: Directory, outputSource: output_to_dir/output_dirs}

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
  vt_norm_vcf:
    run: ../tools/vt_normalize_variants.cwl
    in:
      input_vcf: bedtools_split_vcf/intersected_vcf
      indexed_reference_fasta: reference
      output_basename: output_basename
      tool_name: wf_tool_name
      run_norm_flag: run_vt_norm
    scatter: input_vcf
    out: [vt_normalize_vcf]
  annovar_preprocess:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/annovar_preprocess.cwl
    in:
      input_vcf: vt_norm_vcf/vt_normalize_vcf
    scatter: [input_vcf]
    out: [vcf_to_gz_annovar]
  run_annovar:
    run: ../tools/annovar_av_input.cwl
    in:
      cache: ANNOVAR_cache
      ram: ram
      cores: cores
      protocol_name: protocol_list
      input_av: annovar_preprocess/vcf_to_gz_annovar
      tool_name: wf_tool_name
      run_dbs: run_dbs
    scatter: [input_av, protocol_name, run_dbs]
    scatterMethod: nested_crossproduct
    out: [anno_txt]
  output_to_dir:
    run: ../tools/output_to_dir.cwl
    in:
      three_d_in: run_annovar/anno_txt
      protocol_name: protocol_list
      tool_name: wf_tool_name
      output_basename: output_basename
    out: [output_dirs]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 6
