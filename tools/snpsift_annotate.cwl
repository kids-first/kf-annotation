cwlVersion: v1.0
class: CommandLineTool
id: snpsift_annotate
label: SnpSift
doc: |
  Simplified descrition of what this tool does:
    1. Run SnpEff on input VCF
    2. BGZIP output VCF
    3. TABIX ouptut VCF

  SnpSift Parameters:
    1. v: Verbose logging
    2. a: In cases where variants do not have annotations in the database the tool will report an empty value (FIELD=.) rather than no annotation
    3. info: Comma separated list of INFO fields from the reference database the tool will use to annotate matching listings
    4. f: Same as "info" but specficially used when the tool is used running in dbnsfp mode
    5. db: The reference database file used for annotating the input

  An example run of this tool will use a command like this:
    /bin/bash -c
    set -eo pipefail 
    java -jar /snpEff/SnpSift.jar 
      annotate 
      -v 
      -a 
      -info fields-string-value 
      -db /path/to/db_file.ext 
      /path/to/input_vcf.ext | 
    bgzip -c > output_basename-string-value.SnpSift.db_name-string-value.snpEff.vcf.gz && 
    tabix output_basename-string-value.SnpSift.db_name-string-value.snpEff.vcf.gz

requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/snpeff:4_3t'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      java -jar /snpEff/SnpSift.jar $(inputs.mode)
      -v
      ${ if (inputs.mode == 'gwasCat') {return ''} else {return '-a'}}
      ${ if (inputs.fields && inputs.mode == 'annotate') {
        return '-info ' + inputs.fields
      } else if (inputs.fields && inputs.mode == 'dbnsfp') {
        return '-f ' + inputs.fields
      } else {
        return ''
      }}
      -db $(inputs.db_file.path)
      $(inputs.input_vcf.path)
      | bgzip -c > $(inputs.output_basename).SnpSift.$(inputs.db_name).snpEff.vcf.gz
      && tabix $(inputs.output_basename).SnpSift.$(inputs.db_name).snpEff.vcf.gz

inputs:
  mode: { type: { type: enum, symbols: [annotate, dbnsfp, gwasCat] }, doc: Mode of SnpSift to run. }
  db_file: { type: File, secondaryFiles: [.tbi], doc: Reference database for annotating the input. }
  db_name: { type: string, doc: Name of the database being used. }
  fields: { type: string?, doc: Comma-separated list of fields from the database that will be used as annotations. }
  input_vcf: { type: File, secondaryFiles: [.tbi], doc: VCF file (witt TBI) to be annotated. }
  output_basename: { type: string, doc: String that will be used in the output filenames. } 

outputs:
  output_vcf: { type: File, outputBinding: { glob: '*.vcf.gz' }, secondaryFiles: [.tbi] }
