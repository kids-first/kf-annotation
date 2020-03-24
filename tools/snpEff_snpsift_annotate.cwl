cwlVersion: v1.0
class: CommandLineTool
id: snpEff_snpsift_annotate
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 24000
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'kfdrc/snpeff:4_3t'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      tar -xzvf $(inputs.ref_tar_gz.path) -C /snpEff/
      && java -Xms16g -Xmx24g -jar /snpEff/snpEff.jar
      -nodownload
      -t
      $(inputs.reference_name)
      $(inputs.input_vcf.path)
      ${ if (inputs.dbnsfp_txt) {return '| java -jar /snpEff/SnpSift.jar dbnsfp -db '+inputs.dbnsfp_txt.path+' - '} else {return ''}}
      ${ if (inputs.gwas_catalog_txt) {return '| java -jar /snpEff/SnpSift.jar gwasCat -db '+inputs.gwas_catalog_txt.path+' - '} else {return ''}}
      ${ if (inputs.db_vcfs) {
          var cmd = ''
          for (var i=0; i < inputs.db_vcfs.length; i++){
            cmd += ' | java -jar /snpEff/SnpSift.jar annotate -noDownload -db ' + inputs.db_vcfs[i].path + ' - '
          }
          return cmd
        } else { return ''}
      }
      | bgzip -c > $(inputs.output_basename).$(inputs.tool_name).snpEff.vcf.gz
      && tabix $(inputs.output_basename).$(inputs.tool_name).snpEff.vcf.gz
inputs:
  ref_tar_gz: { type: File, label: tar gzipped snpEff reference}
  dbnsfp_txt: { type: File?,  secondaryFiles: [.tbi] }
  gwas_catalog_txt: { type: File? }
  db_vcfs: { type: ['null', 'File[]'], secondaryFiles: [.tbi] } 
  input_vcf: { type: File,  secondaryFiles: [.tbi] }
  reference_name:
    type:
      - type: enum
        symbols:
          - hg38
          - GRCh38.86
  output_basename: string
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
