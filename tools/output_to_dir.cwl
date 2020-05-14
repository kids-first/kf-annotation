cwlVersion: v1.0
class: CommandLineTool
id: merge_outputs_to_dir
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
        // Result dir will hold overall outputs
        var result_dir = inputs.output_basename + "_" + inputs.tool_name;
        var i;
        cmd += "mkdir " + result_dir + ";";
        var out_dirs = []
        // If input scatter, input file names might not be unique,
        //map will track each time a file of protocol type is seen for file naming purposes
        var protocol_dict = new Object();
        // If getting inputs jobs scstter on protocol AND file input, create protocol subdirs
        if(inputs.input_scatter != null){
          for (i = 0; i < inputs.protocol_name.length; i++) {
            out_dirs.push(result_dir + "/" + inputs.protocol_name[i]);
            cmd += "mkdir " + out_dirs[i] + ";";
            protocol_dict[inputs.protocol_name[i]] = 0;
          }
          // iterate through 2D array
          i = 0;
          for (i=0; i< inputs.input_scatter.length; i++){
            var j = 0;
            for (j = 0; j < inputs.input_scatter[i].length; j++){
              var k = 0;
              // Look for protocol name in basename to assign output location
              for (k = 0; k < out_dirs.length; k++){
                if (inputs.input_scatter[i][j].basename.includes(inputs.protocol_name[k])){
                  cmd += "echo \"cp " + inputs.input_scatter[i][j].path + " " + out_dirs[k] + "/" + protocol_dict[inputs.protocol_name[k]].toString()
                  + "_" + inputs.input_scatter[i][j].basename + "\" >> cmd_list.txt;";
                  // Also copy associated secondaryFiles - assumes only one!
                  if (inputs.input_scatter[i][j].secondaryFiles){
                    cmd += "echo \"cp " + inputs.input_scatter[i][j].secondaryFiles[0].path + " " + out_dirs[k] + "/" + protocol_dict[inputs.protocol_name[k]].toString()
                  + "_" + inputs.input_scatter[i][j].secondaryFiles[0].basename + "\" >> cmd_list.txt;";
                  }
                  protocol_dict[inputs.protocol_name[i]] += 1;
                  break;
                }
              }
            }
          }
        }
        // else if just input file array, just output to result_dir
        else{
          for (i=0; i< inputs.input_array.length; i++){
            cmd += "echo \"cp " + inputs.input_array[i].path + " " + result_dir + "/" + i.toString()
            + "_" + inputs.input_array[i].basename + "\" >> cmd_list.txt;";
            if (inputs.input_array[i].secondaryFiles){
              cmd += "echo \"cp " + inputs.input_array[i].secondaryFiles[0].path + " " + result_dir + "/" + i.toString()
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
      - 'null'
      - type: array
        items:
          type: array
          items: File
    doc: "Usually from a pipeline step, protocol x input vcf scatter creating 2D array input"
  input_array: {type: 'File[]?', doc: "If not 2D scatter, single vcf scatter input tpyical, and this array should be populated instead"}
  protocol_name: {type: 'string[]?', doc: "If input_scatter, protocol_name array used in scatter"}
  output_basename: string
  tool_name: { type: string, doc: "String of tool name that will be used in the output dirnames"}

outputs:
  output_dirs:
    type: Directory
    outputBinding:
      glob: $(inputs.output_basename + "_" + inputs.tool_name)
