cwlVersion: v1.0
class: Workflow
id: kf_snpEff_Sift_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  snpEff_ref_tar_gz: File
  gwas_cat_db_file: {type: File, secondaryFiles: [.tbi], doc: "GWAS catalog file"}
  clinvar_vcf: {type: File, secondaryFiles: [.tbi], doc: "ClinVar VCF reference"}
  SnpSift_vcf_db_name: {type: string, doc: "List of database names corresponding with each vcf_db_files"}
  SnpSift_vcf_fields: {type: string, doc: "csv string of fields to pull"}

outputs:
  snpEff_hg38: 
    type: File
    outputSource: snpeff_hg38/output_vcf
  snpEff_ens: 
    type: File
    outputSource: snpeff_ens/output_vcf
  SnpSift_GWAScat:
    type: File
    outputSource: snpsift_gwascat/output_vcf
  SnpSift_ClinVar:
    type: File
    outputSource: snpsift_clinvar/output_vcf

steps:
  snpeff_hg38: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "hg38"}
      input_vcf: input_vcf
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf]
  snpeff_ens: 
    run: ../tools/snpeff_annotate.cwl
    in:
      ref_tar_gz: snpEff_ref_tar_gz
      reference_name: {default: "GRCh38.86"}
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
      input_vcf: input_vcf
      output_basename: output_basename
    out: [output_vcf]
  snpsift_clinvar:
    run: ../tools/snpsift_annotate.cwl
    in:
      mode: {default: "annotate"}
      db_file: clinvar_vcf
      db_name: SnpSift_vcf_db_name 
      fields: SnpSift_vcf_fields 
      input_vcf: input_vcf
      output_basename: output_basename
    out: [output_vcf]
