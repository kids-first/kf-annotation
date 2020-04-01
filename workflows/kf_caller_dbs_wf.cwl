cwlVersion: v1.0
class: Workflow
id: kf_caller_db_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}
  include_expression: {type: string?, doc: "Select variants meeting criteria, for instance, for all but snps: TYPE!=\"snp\""}
  snpEff_ref_tar_gz: File
  gwas_cat_db_file: {type: File, secondaryFiles: [.tbi], doc: "GWAS catalog file"}
  clinvar_vcf: {type: File, secondaryFiles: [.tbi], doc: "ClinVar VCF reference"}
  SnpSift_vcf_db_name: {type: string, doc: "List of database names corresponding with each vcf_db_files"}
  SnpSift_vcf_fields: {type: string, doc: "csv string of fields to pull"}
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ANNOVAR_dbscsnv_db: { type: 'File?', doc: "dbscSNV database tgz downloaded from Annovar" }
  ANNOVAR_cosmic_db: { type: 'File?', doc: "COSMIC database tgz downloaded from COSMIC" }
  ANNOVAR_kg_db: { type: 'File?', doc: "1000genomes database tgz downloaded from Annovar" }
  ANNOVAR_esp_db: { type: 'File?', doc: "ESP database tgz downloaded from Annovar" }
  ANNOVAR_gnomad_db: { type: 'File?', doc: "gnomAD tgz downloaded from Annovar" }
  ANNOVAR_run_dbs_refGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for refGene protocol? true/false"}
  ANNOVAR_run_dbs_ensGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for ensGene protocol? true/false"}
  ANNOVAR_run_dbs_knownGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for knownGene protocol? true/false"}
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_run_cache_existing: { type: boolean, doc: "Run the check_existing flag for cache" }
  VEP_run_cache_af: { type: boolean, doc: "Run the allele frequency flags for cache" }
  VEP_cadd_indels: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations" }
  VEP_cadd_snvs: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations" }
  VEP_dbnsfp: { type: 'File?', secondaryFiles: [.tbi,^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing dbNSFP annotations" }

outputs:
  snpEff_Sift_results:
    type: File[]
    outputSource: [run_snpEff_Sift_subwf/snpEff_hg38, run_snpEff_Sift_subwf/snpEff_ens, run_snpEff_Sift_subwf/SnpSift_GWAScat, run_snpEff_Sift_subwf/SnpSift_ClinVar]
  ANNOVAR_results: 
    type: File[]
    outputSource: [run_annovar_subwf/ANNOVAR_refGene, run_annovar_subwf/ANNOVAR_ensGene, run_annovar_subwf/ANNOVAR_knownGene]
    linkMerge: merge_flattened
  VEP_results:
    type: File
    outputSource: run_VEP_sub_wf/VEP

steps:
  bcftools_strip_info:
    run: ../tools/bcf_strip_info.cwl
    in:
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
      strip_info: strip_info
    out: [stripped_vcf]
  bcftools_filter_vcf:
    run: ../tools/bcftools_filter_vcf.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      include_expression: include_expression
      output_basename: output_basename
    out: [filtered_vcf]
  run_annovar_subwf:
    run: ../sub_workflows/kf_annovar_explicit_sub_wf.cwl
    in:
      input_vcf: bcftools_filter_vcf/filtered_vcf
      output_basename: output_basename
      tool_name: tool_name
      ANNOVAR_cache: ANNOVAR_cache
      ANNOVAR_dbscsnv_db: ANNOVAR_dbscsnv_db
      ANNOVAR_cosmic_db: ANNOVAR_cosmic_db
      ANNOVAR_kg_db: ANNOVAR_kg_db
      ANNOVAR_esp_db: ANNOVAR_esp_db
      ANNOVAR_gnomad_db: ANNOVAR_gnomad_db
      ANNOVAR_run_dbs_refGene: ANNOVAR_run_dbs_refGene
      ANNOVAR_run_dbs_ensGene: ANNOVAR_run_dbs_ensGene
      ANNOVAR_run_dbs_knownGene: ANNOVAR_run_dbs_knownGene
    out:
      [ANNOVAR_refGene, ANNOVAR_ensGene, ANNOVAR_knownGene]
  run_snpEff_Sift_subwf:
    run: ../sub_workflows/kf_snpEff_Sift_sub_wf.cwl
    in:
      input_vcf: bcftools_filter_vcf/filtered_vcf
      output_basename: output_basename
      tool_name: tool_name
      snpEff_ref_tar_gz: snpEff_ref_tar_gz
      gwas_cat_db_file: gwas_cat_db_file
      clinvar_vcf: clinvar_vcf
      SnpSift_vcf_db_name: SnpSift_vcf_db_name
      SnpSift_vcf_fields: SnpSift_vcf_fields
    out: [snpEff_hg38, snpEff_ens, SnpSift_GWAScat, SnpSift_ClinVar]
  run_VEP_sub_wf:
    run: ../sub_workflows/kf_VEP99_sub_wf.cwl
    in:
      input_vcf: bcftools_filter_vcf/filtered_vcf
      output_basename: output_basename
      tool_name: tool_name
      reference: reference
      VEP_cache: VEP_cache
      VEP_run_cache_existing: VEP_run_cache_existing
      VEP_run_cache_af: VEP_run_cache_af
      VEP_cadd_indels: VEP_cadd_indels
      VEP_cadd_snvs: VEP_cadd_snvs
      VEP_dbnsfp: VEP_dbnsfp
    out: [VEP]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 3
  - class: 'sbg:AWSInstanceType'
    value: c5.4xlarge