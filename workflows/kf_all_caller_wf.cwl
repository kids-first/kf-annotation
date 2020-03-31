cwlVersion: v1.0
class: Workflow
id: kf_all_caller_wf.cwl
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  snpEff_ref_tar_gz: File
  reference_name:
    type:
      type: enum
      name: reference_name
      symbols:
        - hg38
        - GRCh38.86
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}
  gwas_cat_db_file: File
  dbnsfp_db_file: {type: File, secondaryFiles: [.tbi]}
  dbnsfp_fields: string
  vcf_db_files: File[]
  vcf_db_names: string[]
  vcf_fields: string[]
  
outputs:
  snpEff_Sift_vcfs:
    type: File[]
    outputSource: snpeff/output_vcf

steps:

  bcftools_strip_info
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

  snpsift_dbnsfp:
    run: ../tools/snpsift_annotate.cwl
    in:
      mode: {default: "dbnsfp"}
      db_file: dbnsfp_db_file
      db_name: {default: "dbnsfp"}
      fields: dbnsfp_fields
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
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
    scatter: [db_file,db_name,fields]
    scatterMethod: dotproduct
    in:
      mode: {default: "annotate"}
      db_file: vcf_db_files
      db_name: vcf_db_names 
      fields: vcf_fields 
      input_vcf: bcftools_strip_info/stripped_vcf
      output_basename: output_basename
    out: [output_vcf]
