cwlVersion: v1.0
class: CommandLineTool
id: bcftools_strip_info
doc: "Quick tool to strip info from vcf file before re-annotation"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/vcfutils:latest'

baseCommand: []
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      ${
        if (inputs.strip_info == null){
          var cmd = "echo \"No strip value given, returning input\";";
          cmd += "cp " + inputs.input_vcf.path + " .;";
          cmd += "cp " + inputs.input_vcf.secondaryFiles[0].path + " .;";
          return cmd;
        }
        else{
          var cmd = "bcftools annotate -x " + inputs.strip_info + " " + inputs.input_vcf.path
          + " -O z -o " + inputs.output_basename + "." + inputs.tool_name + ".INFO_stripped.vcf.gz;";
          cmd += "tabix " + inputs.output_basename + "." + inputs.tool_name + ".INFO_stripped.vcf.gz;";
          return cmd;
        }
      }

inputs:
    input_vcf: {type: File, secondaryFiles: ['.tbi']}
    output_basename: string
    tool_name: string
    strip_info: {type: ['null', string], doc: "If given, remove previous annotation information based on INFO file, i.e. to strip VEP info, use INFO/ANN"}

outputs:
  stripped_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: ['.tbi']
