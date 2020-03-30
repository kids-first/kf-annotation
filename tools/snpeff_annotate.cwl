cwlVersion: v1.0
class: CommandLineTool
id: snpeff_annotate
label: SnpEff
doc: |
  Simplified description of what this tool does:
    1. Untar the cache
    2. Run SnpEff on input VCF
    3. bgzip output VCF
    4. tabix output VCF.GZ

  SnpEff parameters:
    1. nodownload: prevents SnpEff from downloading missing files from the web
    2. t: runs in multithread mode (uses maximum available cores)
    3. reference name: the reference genome used in the generation of the vcf; corresponds with cache files
    4. v: verbose logging
    5. datadir: path to folder containing cache data

  An example run of this tool will use a command like this:
    /bin/bash -c
    set -eo pipefail
    tar -xzvf /path/to/ref_tar_gz.ext &&
    java -jar /snpEff/snpEff.jar
      -dataDir data/
      -nodownload
      -t
      -v
      hg38
      /path/to/input_vcf.ext |
    bgzip -c > output_basename-string-value.tool_name-string-value.snpEff.vcf.gz &&
    tabix output_basename-string-value.tool_name-string-value.snpEff.vcf.gz

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'kfdrc/snpeff:4_3t'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      tar -xzvf $(inputs.ref_tar_gz.path)
      && java -Xmx30g -jar /snpEff/snpEff.jar
      -dataDir $PWD/data
      -nodownload
      -t
      -v
      $(inputs.reference_name)
      $(inputs.input_vcf.path)
      | bgzip -c > $(inputs.output_basename).$(inputs.tool_name).vcf.gz
      && tabix $(inputs.output_basename).$(inputs.tool_name).vcf.gz

inputs:
  ref_tar_gz: { type: File, doc: "TAR gzipped snpEff reference" }
  input_vcf: { type: File,  secondaryFiles: [.tbi] , doc: "VCF file (with associated index) to be annotated" }
  reference_name: { type: { type: enum, symbols: [hg38,GRCh38.86] }, doc: "Reference genome used to generate input VCF" }
  output_basename: { type: string, doc: "String that will be used in the output filenames" }
  tool_name: { type: string, doc: "Tool name to be used in output filenames" }

outputs:
  output_vcf: { type: File, outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: [.tbi] }
