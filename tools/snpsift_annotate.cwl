cwlVersion: v1.0
class: CommandLineTool
id: snpsift_annotate
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
  mode:
    type:
      type: enum
      symbols:
        - annotate
        - dbnsfp
        - gwasCat
  db_file: { type: File, secondaryFiles: [.tbi] }
  db_name: string
  fields:
    type: string?
    doc: Comma separated list of fields to include.
  input_vcf: File
  input_tbi: File
  output_basename: string
outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
  output_tbi:
    type: File
    outputBinding:
      glob: '*.vcf.gz.tbi'
