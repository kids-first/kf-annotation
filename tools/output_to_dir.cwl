cwlVersion: v1.0
class: CommandLineTool
id: merge_annovar_outputs
doc: "Merges outputs from scatter jobs and outputs to subdirs"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
  - class: DockerRequirement
    dockerPull: 'ubuntu:18.04'

baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      ${
          var cmd = "";
          if(inputs.input_scatter){
            var i;
            for (i = 0; i < inputs.protocol_name.length; i++) {
                cmd += "mkdir " + inputs.protocol_name[i] + ";";
                var j = 0;
                for (j=0; j< inputs.input_scatter[i].length; j++){
                    cmd += "cp " + inputs.input_scatter[i][j].path + " " + inputs.protocol_name[i] + "/" + j.toString()
                    + "_" + inputs.input_scatter[i][j].basename + ";";
                }
            } 
          }
          return cmd;
      }
inputs:
  input_scatter:
    type:
      type: array
      items:
        type: array
        items: File?
  input_array: 'File[]?'
  protocol_name: string[]
  tool_name: { type: string, doc: "String of tool name that will be used in the output filenames"}

outputs:
  output_dirs:
    type: 'Directory[]'
    outputBinding:
      glob: $(inputs.protocol_name.join("|"))
