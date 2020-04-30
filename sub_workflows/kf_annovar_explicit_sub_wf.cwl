cwlVersion: v1.0
class: Workflow
id: kf_annovar_explicit_sub_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  ANNOVAR_ram: {type: int?, default: 32000, doc: "May need to increase this value depending on the size/complexity of input"}
  ANNOVAR_dbscsnv_db: { type: 'File?', doc: "dbscSNV database tgz downloaded from Annovar" }
  ANNOVAR_cosmic_db: { type: 'File?', doc: "COSMIC database tgz downloaded from COSMIC" }
  ANNOVAR_kg_db: { type: 'File?', doc: "1000genomes database tgz downloaded from Annovar" }
  ANNOVAR_esp_db: { type: 'File?', doc: "ESP database tgz downloaded from Annovar" }
  ANNOVAR_gnomad_db: { type: 'File?', doc: "gnomAD tgz downloaded from Annovar" }
  ANNOVAR_run_dbs_refGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for refGene protocol? true/false"}
  ANNOVAR_run_dbs_ensGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for ensGene protocol? true/false"}
  ANNOVAR_run_dbs_knownGene: { type: boolean, doc: "Should the additional dbs be processed in this run of the tool for knownGene protocol? true/false"}

outputs:
  ANNOVAR_refGene: 
    type: File[]
    outputSource: [annovar_refgene/anno_vcf, annovar_refgene/anno_txt]
  ANNOVAR_ensGene: 
    type: File[]
    outputSource: [annovar_ensgene/anno_vcf, annovar_ensgene/anno_txt]
  ANNOVAR_knownGene:
    type: File[]
    outputSource: [annovar_knowngene/anno_vcf, annovar_knowngene/anno_txt]

steps:
  annovar_refgene:
    run: ../tools/annovar-explicit.cwl
    in:
      cache: ANNOVAR_cache
      ram: ANNOVAR_ram
      dbscsnv_db: ANNOVAR_dbscsnv_db
      cosmic_db: ANNOVAR_cosmic_db
      kg_db: ANNOVAR_kg_db
      esp_db: ANNOVAR_esp_db
      gnomad_db: ANNOVAR_gnomad_db
      protocol_name: {default: "refGene"}
      input_vcf: input_vcf
      tool_name: tool_name
      run_dbs: ANNOVAR_run_dbs_refGene
      output_basename: output_basename
    out: [anno_txt, anno_vcf]
  annovar_ensgene:
    run: ../tools/annovar-explicit.cwl
    in:
      cache: ANNOVAR_cache
      ram: ANNOVAR_ram
      protocol_name: {default: "ensGene"}
      input_vcf: input_vcf
      tool_name: tool_name
      run_dbs: ANNOVAR_run_dbs_ensGene
      output_basename: output_basename
    out: [anno_txt, anno_vcf]
  annovar_knowngene:
    run: ../tools/annovar-explicit.cwl
    in:
      cache: ANNOVAR_cache
      ram: ANNOVAR_ram
      protocol_name: {default: "knownGene"}
      input_vcf: input_vcf
      tool_name: tool_name
      run_dbs: ANNOVAR_run_dbs_knownGene
      output_basename: output_basename
    out: [anno_txt, anno_vcf]
