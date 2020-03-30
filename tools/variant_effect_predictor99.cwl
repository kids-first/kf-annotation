cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-vep99-wgsa
label: VEP
doc: |
  Simplified descrition of what this tool does:
    1. Install needed plugins
    2. Untar cache if it is provided
    3. Run VEP on input VCF
    4. BGZIP output VCF
    5. TABIX output VCF

  VEP Parameters:
    1. input_file: Path to input file
    2. output_file: Path for output VCF or STDOUT
    3. stats_file: Path for output stats file
    4. warning_file: Path for output warnings file
    5. vcf: Writes output in VCF format
    6. offline: No database connections will be made, and a cache file or GFF/GTF file is required for annotation
    7. fork: Number of threads to run on
    8. ccds: Adds the CCDS transcript identifier
    9. uniprot: Adds best match accessions for translated protein products from three UniProt-related databases (SWISSPROT, TREMBL and UniParc)
    10. symbol: Adds the gene symbol (e.g. HGNC)
    11. numbers: Adds affected exon and intron numbering to to output. Format is Number/Total
    12. canonical: Adds a flag indicating if the transcript is the canonical transcript for the gene
    13. protein: Add the Ensembl protein identifier to the output where appropriate
    14. assembly: Select the assembly version to use if more than one available. If using the cache, you must have the appropriate assembly's cache file installed
    15. dir_cache: Cache directory to use
    16. cache: Enables use of the cache
    17. merged: Use the merged Ensembl and RefSeq cache
    18. hgvs: Add HGVS nomenclature based on Ensembl stable identifiers to the output
    19. fasta: Specify a FASTA file or a directory containing FASTA files to use to look up reference sequence
    20. check_existing: Checks for the existence of known variants that are co-located with your input
    21. af_1kg: Add allele frequency from continental populations (AFR,AMR,EAS,EUR,SAS) of 1000 Genomes Phase 3 to the output
    22. af_esp: Include allele frequency from NHLBI-ESP populations
    23. af_gnomad: Include allele frequency from Genome Aggregation Database (gnomAD) exome populations
    24. plugin: Use named plugin
    25. custom: Add custom annotation to the output

  An example run of this tool will use a command like this:
    /bin/bash -c
    set -eo pipefail
    perl /opt/vep/src/ensembl-vep/INSTALL.pl
      --NO_TEST
      --NO_UPDATE
      --AUTO p
      --PLUGINS LoF,ExAC,gnomADc,CADD,dbNSFP,dbscSNV &&
    tar -xzf /path/to/cache.ext &&
    /opt/vep/src/ensembl-vep/vep
      --input_file /path/to/input_vcf.ext
      --output_file STDOUT
      --stats_file output_basename-string-value_stats.tool_name-string-value.html
      --warning_file output_basename-string-value_warnings.tool_name-string-value.txt
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
      --dir_cache $PWD
      --cache
      --merged
      --check_existing
      --af_1kg
      --af_esp
      --af_gnomad
      --hgvs
      --fasta /path/to/reference.ext
      --plugin CADD,/path/to/cadd_snvs.ext,/path/to/cadd_indels.ext
      --plugin dbNSFP,/path/to/dbnsfp.ext,ALL
      --plugin dbscSNV,/path/to/dbscsnv.ext
      --custom /path/to/phylop.ext,PhyloP,bigwig |
    bgzip -c > output_basename-string-value.tool_name-string-value.vep.vcf.gz &&
    tabix output_basename-string-value.tool_name-string-value.vep.vcf.gz

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
  input_vcf: { type: File, secondaryFiles: [.tbi], doc: "VCF file (with associated index) to be annotated" }
  reference: { type: 'File?',  secondaryFiles: [.fai,.gzi], doc: "Fasta genome assembly with indexes" }
  cache: { type: 'File?', doc: "tar gzipped cache from ensembl/local converted cache" }
  run_cache_dbs: { type: boolean, doc: "Run the additional dbs in cache" }
  cadd_indels: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations" }
  cadd_snvs: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations" }
  dbnsfp: { type: 'File?', secondaryFiles: [.tbi,^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing dbNSFP annotations" }
  dbscsnv: { type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing dbscSNV annotations" }
  phylop: { type: 'File?', doc: "BigWig file containing PhyloP annotation information" }
  output_basename: { type: string, doc: "String that will be used in the output filenames" }
  tool_name: { type: string, doc: "Tool name to be used in output filenames" }

outputs:
  output_vcf: { type: File, outputBinding: { glob: '*.vcf.gz' } }
  output_tbi: { type: File, outputBinding: { glob: '*.vcf.gz.tbi' } }
  output_html: { type: File, outputBinding: { glob: '*.html' } }
  warn_txt: { type: 'File?', outputBinding: { glob: '*.txt' } }
