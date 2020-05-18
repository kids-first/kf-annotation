cwlVersion: v1.0
class: CommandLineTool
id: vt_normalize_vcf
doc: "Normalizes a vcf using vt decompose and normalize. If part of a pipe, can skip this run when needed"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'migbro/vcfutils:latest'

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >
      set -eo pipefail

      ${
        var cmd = "";
        if (inputs.run_norm_flag){
          cmd = "/vt/vt decompose " + inputs.input_vcf.path + " > " +  inputs.output_basename + "." + inputs.tool_name + ".vt.decomp.vcf || exit 1;";
          cmd += "/vt/vt normalize -r " + inputs.indexed_reference_fasta.path + " " + inputs.output_basename + "." + inputs.tool_name
          + ".vt.decomp.vcf -m > " + inputs.output_basename + "." + inputs.tool_name + ".vt.decomp.norm.vcf || exit 1;";
          cmd += "bgzip " + inputs.output_basename + "." + inputs.tool_name + ".vt.decomp.norm.vcf || exit 1;";
          cmd += "tabix " + inputs.output_basename + "." + inputs.tool_name + ".vt.decomp.norm.vcf.gz || exit 1;";
        }
        else{
            cmd = "echo 'Run set to false, skipping!';";
        }
        return cmd;
      }
inputs:
    input_vcf: {type: File, secondaryFiles: ['.tbi']}
    indexed_reference_fasta: {type: File?, secondaryFiles: ['.fai'], doc: "Needed if run_norm_flag true"}
    output_basename: {type: string?, doc: "Needed if run_norm_flag true"}
    tool_name: {type: string?, doc: "Needed if run_norm_flag true"}
    run_norm_flag: {type: boolean, doc: "If false, skip this step and pass the input file though", default: true}

outputs:
  vt_normalize_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
      outputEval: >-
        ${
          if (inputs.run_norm_flag){
              return self;
          }
          else{
              return inputs.input_vcf
          }
        }
    secondaryFiles: ['.tbi']
