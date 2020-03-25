cwlVersion: v1.0
class: Workflow
id: snpeff_snpsift 
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  ref_tar_gz: File
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
  gwas_cat_db_file: File
  dbnsfp_db_file: {type: File, secondaryFiles: [.tbi]}
  dbnsfp_fields: string
  vcf_db_files: File[]
  vcf_db_names: string[]
  vcf_fields: string[]
  
outputs:
  base_vcf:
    type: File
    outputSource: snpeff/output_vcf
  base_tbi:
    type: File
    outputSource: snpeff/output_tbi
  dbnsfp_vcf:
    type: File
    outputSource: snpsift_dbnsfp/output_vcf
  dbnsfp_tbi:  
    type: File
    outputSource: snpsift_dbnsfp/output_tbi
  gwas_vcf:
    type: File
    outputSource: snpsift_gwascat/output_vcf
  gwas_tbi:
    type: File
    outputSource: snpsift_gwascat/output_tbi
  vcf_vcfs:
    type: File[]
    outputSource: snpsift_vcfdbs/output_vcf 
  vcf_tbis:
    type: File[]
    outputSource: snpsift_vcfdbs/output_tbi

steps:
  snpeff: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: ref_tar_gz
      reference_name: reference_name
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf, output_tbi]

  snpsift_dbnsfp:
    run: ../tools/snpsift_annotate.cwl
    in:
      mode: {default: "dbnsfp"}
      db_file: dbnsfp_db_file
      db_name: {default: "dbnsfp"}
      fields: dbnsfp_fields
      input_vcf: snpeff/output_vcf
      input_tbi: snpeff/output_tbi
      output_basename: output_basename
    out: [output_vcf, output_tbi]      

  snpsift_gwascat:
    run: ../tools/snpsift_annotate.cwl
    in:
      mode: {default: "gwasCat"}
      db_file: gwas_cat_db_file
      db_name: {default: "gwas_catalog"}
      input_vcf: snpeff/output_vcf
      input_tbi: snpeff/output_tbi
      output_basename: output_basename
    out: [output_vcf, output_tbi]

  snpsift_vcfdbs:
    run: ../tools/snpsift_annotate.cwl
    scatter: [db_file,db_name,fields]
    scatterMethod: dotproduct
    in:
      mode: {default: "annotate"}
      db_file: vcf_db_files
      db_name: vcf_db_names 
      fields: vcf_fields 
      input_vcf: snpeff/output_vcf
      input_tbi: snpeff/output_tbi
      output_basename: output_basename
    out: [output_vcf, output_tbi]
