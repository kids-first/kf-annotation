cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-vep99-wgsa
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 24000
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'ensemblorg/ensembl-vep:release_99.0'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      ${
        var plugins = ["LoF","ExAC","gnomADc"];
        if (inputs.cadd_indels) {
          plugins.push("CADD")
        }
        if (inputs.dbnsfp) {
          plugins.push("dbNSFP")
        }
        if (inputs.dbscsnv) {
          plugins.push("dbscSNV")
        }
        return "perl /opt/vep/src/ensembl-vep/INSTALL.pl --NO_TEST --NO_UPDATE --AUTO p --PLUGINS "+plugins.join(',')+" &&"
      }
      ${if(inputs.cache) {return "tar -xzf "+inputs.cache.path} else {return "echo 'No cache'"}} &&
      /opt/vep/src/ensembl-vep/vep
      --input_file $(inputs.input_vcf.path)
      --output_file STDOUT 
      --stats_file $(inputs.output_basename)_stats.$(inputs.tool_name).html
      --warning_file $(inputs.output_basename)_warnings.$(inputs.tool_name).txt
      --vcf
      --offline
      --fork 16
      --ccds
      --uniprot
      --symbol
      --numbers
      --canonical
      --protein
      --assembly GRCh38
      ${if(inputs.cache) {return "--dir_cache $PWD --cache --merged"} else {return ""}}
      ${if(inputs.run_cache_dbs) {return "--check_existing --af_1kg --af_esp --af_gnomad"} else { return ""}}
      ${if(inputs.reference) { return "--hgvs --fasta "+inputs.reference.path} else {return ""}}
      ${if(inputs.cadd_indels && inputs.cadd_snvs) {return "--plugin CADD,"+inputs.cadd_snvs.path+","+inputs.cadd_indels.path} else {return ""}}
      ${if(inputs.dbnsfp) {return "--plugin dbNSFP,"+inputs.dbnsfp.path+",ALL"} else {return ""}}
      ${if(inputs.dbscsnv) {return "--plugin dbscSNV,"+inputs.dbscsnv.path} else {return ""}}
      ${if(inputs.phylop) {return "--custom "+inputs.phylop.path+",PhyloP,bigwig"} else {return ""}} |
      bgzip -c > $(inputs.output_basename).$(inputs.tool_name).vep.vcf.gz &&
      tabix $(inputs.output_basename).$(inputs.tool_name).vep.vcf.gz

inputs:
  input_vcf:
    type: File
    secondaryFiles: [.tbi]
  output_basename: string
  reference: { type: File?,  secondaryFiles: [.fai,.gzi], label: Fasta genome assembly with indexes }
  cache: { type: File?, label: tar gzipped cache from ensembl/local converted cache }
  run_cache_dbs: { type: boolean, label: run the additional dbs in cache }
  cadd_indels: { type: File?, secondaryFiles: [.tbi] }
  cadd_snvs: { type: File?, secondaryFiles: [.tbi] }
  dbnsfp: { type: File?, secondaryFiles: [.tbi,^.readme.txt] }
  dbscsnv: { type: File?, secondaryFiles: [.tbi] }
  phylop: { type: File? }
  tool_name: string

outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
  output_tbi:
    type: File
    outputBinding:
      glob: '*.vcf.gz.tbi'

  output_html:
    type: File
    outputBinding:
      glob: '*.html'
  warn_txt:
    type: ["null", File]
    outputBinding:
      glob: '*.txt'
