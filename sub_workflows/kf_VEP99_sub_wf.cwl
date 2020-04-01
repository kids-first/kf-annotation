cwlVersion: v1.0
class: Workflow
id: kf_VEP99_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_run_cache_existing: { type: boolean, doc: "Run the check_existing flag for cache" }
  VEP_run_cache_af: { type: boolean, doc: "Run the allele frequency flags for cache" }
  VEP_cadd_indels: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations" }
  VEP_cadd_snvs: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations" }
  VEP_dbnsfp: { type: 'File?', secondaryFiles: [.tbi,^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing dbNSFP annotations" }

outputs:
  VEP: 
    type: File
    outputSource: vep_annotate/output_vcf
steps:
  vep_annotate:
    run: ../tools/variant_effect_predictor99.cwl
    in:
      input_vcf: input_vcf
      reference: reference
      cache: VEP_cache
      run_cache_existing: VEP_run_cache_existing
      run_cache_af: VEP_run_cache_af
      cadd_indels: VEP_cadd_indels
      cadd_snvs: VEP_cadd_snvs
      dbnsfp: VEP_dbnsfp
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf, output_html, warn_txt]
