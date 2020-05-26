cwlVersion: v1.0
class: Workflow
id: kf_caller_only_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  reference_vcf: {type: File, secondaryFiles: [.tbi], doc: "VCF to use as a reference to isolate unknown variants in input_vcf"}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN or INFO/CSQ"}
  include_expression: {type: string?, doc: "Select variants meeting criteria, for instance, for all but snps: TYPE!=\"snp\""}
  run_norm_flag: {type: boolean, doc: "If false, skip this step and pass the input file though", default: true}
  snpEff_ref_tar_gz: File
  snpeff_ref_name:
    type:
      - "null"
      - type: array
        items:
            type: enum
            name: snpeff_ref_name
            symbols: [hg38,hg38kg,GRCh38.86]
  snpEff_cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  snpEff_ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}
  protocol_list:
    type:
      - "null"
      - type: array
        items:
            type: enum
            name: protocol_list
            symbols: [ensGene, knownGene, refGene]
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ANNOVAR_ram: {type: int?, default: 32, doc: "May need to increase this value depending on the size/complexity of input"}
  ANNOVAR_cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  reference: { type: 'File?',  secondaryFiles: [.fai], doc: "Fasta genome assembly with indexes" }
  VEP_cores: {type: int?, default: 16, doc: "Number of cores to use. May need to increase for really large inputs"}
  VEP_ram: {type: int?, default: 32, doc: "In GB. May need to increase this value depending on the size/complexity of input"}
  VEP_run_stats: { type: boolean, doc: "Create stats file? Disable for speed", default: false }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_buffer_size: {type: int?, default: 5000, doc: "Increase or decrease to balance speed and memory usage"}
  VEP_run_cache_existing: { type: boolean?, doc: "Run the check_existing flag for cache", default: false }
  VEP_run_cache_af: { type: boolean?, doc: "Run the allele frequency flags for cache", default: false}

outputs:
  snpEff_results:
    type: File[]
    outputSource: [run_snpeff/output_vcf]
  ANNOVAR_results: 
    type: File[]
    outputSource: [run_annovar/anno_txt]
  VEP_results:
    type: File
    outputSource: run_VEP/output_vcf
  normalized_preprocess_vcf:
    type: File
    outputSource: vt_normalize/vt_normalize_vcf

steps:
  bcftools_strip_info:
    doc: "Remove old annotations that might exist"
    run: ../tools/bcf_strip_info.cwl
    in:
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
      strip_info: strip_info
    out: [stripped_vcf]
  vt_normalize:
    doc: "Norm variants by splitting multi-allelics and \"re\"-align indels"
    run: ../tools/vt_normalize_variants.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      indexed_reference_fasta: reference
      output_basename: output_basename
      tool_name: tool_name
      run_norm_flag: run_norm_flag
    out: [vt_normalize_vcf]
  bcftools_filter_vcf:
    doc: "Optionally filter out snps, etc"
    run: ../tools/bcftools_filter_vcf.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      include_expression: include_expression
      output_basename: output_basename
    out: [filtered_vcf]
  bcftools_isec:
    doc: "Get only unknown variants based on a reference"
    run: ../tools/bcftools_isec_unknown.cwl
    in:
      input_vcf: bcftools_filter_vcf/filtered_vcf
      ref_vcf: reference_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [intersected_vcf]
  run_annovar:
    run: ../tools/annovar-explicit.cwl
    in:
      cache: ANNOVAR_cache
      ram: ANNOVAR_ram
      cores: ANNOVAR_cores
      protocol_name: protocol_list
      input_vcf: bcftools_isec/intersected_vcf
      tool_name: tool_name
      run_dbs: {default: false}
      output_basename: output_basename
    scatter: [protocol_name]
    out: [anno_txt, anno_vcf]
  run_snpeff: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: snpeff_ref_name
      cores: snpEff_cores
      ram: snpEff_ram
      input_vcf: bcftools_isec/intersected_vcf
      output_basename: output_basename
      tool_name: tool_name
    scatter: [reference_name]
    out: [output_vcf]
  run_VEP:
    run: ../tools/variant_effect_predictor99.cwl
    in:
      input_vcf: bcftools_isec/intersected_vcf
      reference: reference
      cores: VEP_cores
      ram: VEP_ram
      buffer_size: VEP_buffer_size
      run_stats: VEP_run_stats
      cache: VEP_cache
      run_cache_existing: VEP_run_cache_existing
      run_cache_af: VEP_run_cache_af
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf, output_html, warn_txt]
$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 3
