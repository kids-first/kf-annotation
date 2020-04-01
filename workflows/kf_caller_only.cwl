cwlVersion: v1.0
class: Workflow
id: kf_caller_olny_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}
  snpEff_ref_tar_gz: File
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ANNOVAR_run_dbs_refGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for refGene protocol? true/false"}
  ANNOVAR_run_dbs_ensGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for ensGene protocol? true/false"}
  ANNOVAR_run_dbs_knownGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for knownGene protocol? true/false"}
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_run_cache_existing: { type: boolean, doc: "Run the check_existing flag for cache" }
  VEP_run_cache_af: { type: boolean, doc: "Run the allele frequency flags for cache" }

outputs:
  snpEff_Sift_results:
    type: File[]
    outputSource: [run_snpEff_only_subwf/snpEff_hg38, run_snpEff_only_subwf/snpEff_ens]
  ANNOVAR_results: 
    type:
        type: array
        items:
            type: array
            items: File
    outputSource: [run_annovar_subwf/ANNOVAR_refGene, run_annovar_subwf/ANNOVAR_ensGene, run_annovar_subwf/ANNOVAR_knownGene]
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
  run_annovar_subwf:
    run: ../sub_workflows/kf_annovar_explicit_sub_wf.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
      tool_name: tool_name
      ANNOVAR_cache: ANNOVAR_cache
      ANNOVAR_run_dbs_refGene: ANNOVAR_run_dbs_refGene
      ANNOVAR_run_dbs_ensGene: ANNOVAR_run_dbs_ensGene
      ANNOVAR_run_dbs_knownGene: ANNOVAR_run_dbs_knownGene
    out:
      [ANNOVAR_refGene, ANNOVAR_ensGene, ANNOVAR_knownGene]
  run_snpEff_only_subwf:
    run: ../sub_workflows/kf_snpEff_only_sub_wf.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
      tool_name: tool_name
      snpEff_ref_tar_gz: snpEff_ref_tar_gz
    out: [snpEff_hg38, snpEff_ens]
  run_VEP_sub_wf:
    run: ../sub_workflows/kf_VEP99_sub_wf.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
      tool_name: tool_name
      reference: reference
      VEP_cache: VEP_cache
      VEP_run_cache_existing: VEP_run_cache_existing
      VEP_run_cache_af: VEP_run_cache_af
    out: [VEP]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 3
  - class: 'sbg:AWSInstanceType'
    value: c5.4xlarge