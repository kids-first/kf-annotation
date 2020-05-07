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
          var result_dir = inputs.output_basename + "_" + inputs.tool_name;
          var i;
          if(inputs.input_scatter){
            cmd += "mkdir " + result_dir + ";";
            for (i = 0; i < inputs.protocol_name.length; i++) {
                var out_dir = result_dir + "/" + inputs.protocol_name[i];
                cmd += "mkdir " + out_dir + ";";
                var j = 0;
                for (j=0; j< inputs.input_scatter[i].length; j++){
                    cmd += "echo \"cp " + inputs.input_scatter[i][j].path + " " + out_dir + "/" + j.toString()
                    + "_" + inputs.input_scatter[i][j].basename + "\" >> cmd_list.txt;";
                    if (inputs.input_scatter[i][j].secondaryFiles){
                      cmd += "echo \"cp " + inputs.input_scatter[i][j].secondaryFiles[0].path + " " + out_dir + "/" + j.toString()
                    + "_" + inputs.input_scatter[i][j].secondaryFiles[0].basename + "\" >> cmd_list.txt;";
                    }
                }
            }
          }
            else{
                for (i=0; j< inputs.input_array.length; i++){
                    cmd += "echo \"cp " + inputs.input_array[i].path + " " + result_dir + "/" + j.toString()
                    + "_" + inputs.input_array[i].basename + "\" >> cmd_list.txt;";
                    if (inputs.input_array[i].secondaryFiles){
                      cmd += "echo \"cp " + inputs.input_array[i].secondaryFiles[0].path + " " + result_dir + "/" + j.toString()
                    + "_" + inputs.input_array[i].secondaryFiles[0].basename + "\" >> cmd_list.txt;";
                    }
            }
          }
          return cmd;
      }

      cat cmd_list.txt | xargs -ICMD -P 8 /bin/bash -c "CMD"
inputs:
  input_scatter:
    type:
      type: array
      items:
        type: array
        items: File?
  input_array: 'File[]?'
  protocol_name: 'string[]?'
  output_basename: string
  tool_name: { type: string, doc: "String of tool name that will be used in the output filenames"}

outputs:
  output_dirs:
    type: Directory
    outputBinding:
      glob: $(inputs.output_basename + "_" + inputs.tool_name)
