cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-annovar-convert
label: Convert to ANNOVAR FMT
doc: |
  "Convert vcf to annovar input format. Useful for repeat runs of annovar on the same file, especially if it is massive."
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: DockerRequirement
    dockerPull: 'kfdrc/annovar:latest'
baseCommand: [set,-eo]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      pipefail

      perl /home/TOOLS/tools/annovar/current/bin/convert2annovar.pl
      -includeinfo
      -allsample
      -withfreq
      -format vcf4
      $(inputs.input_vcf.path)
      | gzip -c > $(inputs.input_vcf.nameroot).avinput.gz

inputs:
  input_vcf: { type: File, secondaryFiles: [.tbi], doc: "VCF file (with associated index) to be annotated" }

outputs:
  vcf_to_gz_annovar: { type: File, outputBinding: { glob: '*.avinput.gz'} }
