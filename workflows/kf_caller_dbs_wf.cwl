cwlVersion: v1.0
class: Workflow
id: kf_all_caller_wf.cwl
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  snpEff_ref_tar_gz: File
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}
  gwas_cat_db_file: {type: File, secondaryFiles: [.tbi], doc: "GWAS catalog file"}
  SnpSift_vcf_db_file: File
  SnpSift_vcf_db_name: {type: string, doc: "List of database names corresponding with each vcf_db_files"}
  SnpSift_vcf_fields: {type: string, doc: "csv string of dbs to run"}
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ANNOVAR_additional_dbs: { type: 'File[]?', doc: "List of TAR GZ files containing the custom Annovar databases files for dbscsnv11, cosmic90_coding, 1000g2015aug_all, esp6500siv2_all, and gnomad30_genome" } 
  # protocol_name: { type: { type: enum, symbols: [ensGene, knownGene, refGene] }, doc: "Gene-based annotation to be used in this run of the tool" }
  # ANNOVAR_run_dbs: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool? true/false" }
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  VEP_run_cache_existing: { type: boolean, doc: "Run the check_existing flag for cache" }
  VEP_run_cache_af: { type: boolean, doc: "Run the allele frequency flags for cache" }
  VEP_cadd_indels: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations" }
  VEP_cadd_snvs: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations" }
  VEP_dbnsfp: { type: 'File?', secondaryFiles: [.tbi,^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing dbNSFP annotations" }
  VEP_phylop: { type: 'File?', doc: "BigWig file containing PhyloP annotation information" }

outputs:
  snpEff_Sift_results:
    type: File[]
    outputSource: [snpeff_hg38/output_vcf, snpeff_ens/output_vcf, snpsift_gwascat/output_vcf, snpsift_vcfdbs/output_vcf]
  ANNOVAR_results: 
    type: File[]
    outputSource: [annovar_refgene/anno_vcf, annovar_refgene/anno_tbi, annovar_refgene/anno_txt, annovar_ensgene/anno_vcf, annovar_ensgene/anno_tbi, annovar_ensgene/anno_txt, annovar_knowngene/anno_vcf, annovar_knowngene/anno_tbi, annovar_knowngene/anno_txt]
  VEP_results:
    type: File[]
    outputSource:  [vep_annotate/output_vcf, vep_annotate/output_tbi]

steps:
  bcftools_strip_info:
    run: ../tools/bcf_strip_info.cwl
    in:
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
      strip_info: strip_info
    out: [stripped_vcf]

      
  snpeff_hg38: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name:
        valueFrom: ${return "hg38"}
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]

  snpeff_ens: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name:
        valueFrom: ${return "GRCh38.86"}
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]

  snpsift_gwascat:
    run: ../tools/snpsift_annotate.cwl
    in:
      mode: {default: "gwasCat"}
      db_file: gwas_cat_db_file
      db_name: {default: "gwas_catalog"}
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
    out: [output_vcf]

  snpsift_vcfdbs:
    run: ../tools/snpsift_annotate.cwl
    #scatter: [db_file,db_name,fields]
    # scatterMethod: dotproduct
    in:
      mode: {default: "annotate"}
      db_file: SnpSift_vcf_db_file
      db_name: SnpSift_vcf_db_name 
      fields: SnpSift_vcf_fields 
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
    out: [output_vcf]
  annovar_refgene:
    run: ../tools/annovar.cwl
    in:
      cache: ANNOVAR_cache
      additional_dbs: ANNOVAR_additional_dbs
      protocol_name:
        valueFrom: ${return "refGene"}
      input_vcf: bcftools_strip_info/stripped_vcf
      run_dbs:
        valueFrom: ${return true}
      output_basename: output_basename
    out: [anno_txt, anno_vcf, anno_tbi]
  annovar_ensgene:
    run: ../tools/annovar.cwl
    in:
      cache: ANNOVAR_cache
      protocol_name:
        valueFrom: ${return "ensGene"}
      input_vcf: bcftools_strip_info/stripped_vcf
      run_dbs:
        valueFrom: ${return false}
      output_basename: output_basename
    out: [anno_txt, anno_vcf, anno_tbi]
  annovar_knowngene:
    run: ../tools/annovar.cwl
    in:
      cache: ANNOVAR_cache
      protocol_name:
        valueFrom: ${return "knownGene"}
      input_vcf: bcftools_strip_info/stripped_vcf
      run_dbs:
        valueFrom: ${return false}
      output_basename: output_basename
    out: [anno_txt, anno_vcf, anno_tbi]
  vep_annotate:
    run: ../tools/variant_effect_predictor99.cwl
    in:
      input_vcf: bcftools_strip_info/stripped_vcf
      reference: reference
      cache: VEP_cache
      run_cache_existing: VEP_run_cache_existing
      run_cache_af: VEP_run_cache_af
      cadd_indels: VEP_cadd_indels
      cadd_snvs: VEP_cadd_snvs
      dbnsfp: VEP_dbnsfp
      phylop: VEP_phylop
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf, output_tbi, output_html, warn_txt]

