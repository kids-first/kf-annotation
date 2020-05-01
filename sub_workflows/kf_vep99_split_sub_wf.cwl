cwlVersion: v1.0
class: Workflow
id: kf_vep99_split_sub_wf
doc: "Can be run as a regular wf or sub wf. Splits VCF"
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  reference_dict : File
  scatter_bed: File
  VEP_run_stats: { type: boolean, doc: "Create stats file? Disable for speed", default: true }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_buffer_size: {type: int?, default: 5000, doc: "Increase or decrease to balance speed and memory usage"}
  VEP_run_cache_existing: { type: boolean, doc: "Run the check_existing flag for cache" }
  VEP_run_cache_af: { type: boolean, doc: "Run the allele frequency flags for cache" }
  VEP_cadd_indels: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations" }
  VEP_cadd_snvs: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations" }
  VEP_dbnsfp: { type: 'File?', secondaryFiles: [.tbi,^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing dbNSFP annotations" }

outputs:
  VEP: 
    type: File
    outputSource: merge_vep_vcf/merged_vcf
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
  vep_annotate:
    run: ../tools/variant_effect_predictor99.cwl
    in:
      input_vcf: bedtools_split_vcf/intersected_vcf
      reference: reference
      cores: cores
      ram: ram
      buffer_size: VEP_buffer_size
      run_stats: VEP_run_stats
      cache: VEP_cache
      run_cache_existing: VEP_run_cache_existing
      run_cache_af: VEP_run_cache_af
      cadd_indels: VEP_cadd_indels
      cadd_snvs: VEP_cadd_snvs
      dbnsfp: VEP_dbnsfp
      output_basename: output_basename
      tool_name: tool_name
    scatter: input_vcf
    out: [output_vcf, output_html, warn_txt]
  merge_vep_vcf:
    run: ../tools/gatk_mergevcfs.cwl
    in:
      input_vcfs: vep_annotate/output_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name: tool_name
    out: [merged_vcf]
$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 8