cwlVersion: v1.0
class: Workflow
id: kf_caller_only_wf.cwl
requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  snpEff_ref_tar_gz: File
  input_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  tool_name: string
  strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}
  ANNOVAR_cache: { type: File, doc: "TAR GZ file with RefGene, KnownGene, and EnsGene reference annotations" }
  # protocol_name: { type: { type: enum, symbols: [ensGene, knownGene, refGene] }, doc: "Gene-based annotation to be used in this run of the tool" }
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  VEP_cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }

outputs:
  snpEff_results:
    type: File[]
    outputSource: [snpeff_hg38/output_vcf, snpeff_ens/output_vcf]
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

  annovar_refgene:
    run: ../tools/annovar.cwl
    in:
      cache: ANNOVAR_cache
      protocol_name:
        valueFrom: ${return "refGene"}
      input_vcf: bcftools_strip_info/stripped_vcf
      run_dbs:
        valueFrom: ${return false}
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
      run_cache_existing:
        valueFrom: ${return false}
      run_cache_af:
        valueFrom: ${return false}
      output_basename: output_basename
      tool_name: tool_name
    out: [output_vcf, output_tbi, output_html, warn_txt]

