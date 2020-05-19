cwlVersion: v1.0
class: CommandLineTool
id: merge_outputs_to_dir
doc: "Merges outputs from scatter jobs and outputs to subdirs"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
    - |-
      var place_file = function(f_obj, out_dirs, protocol_array, protocol_dict){
          var p = 0;
          var cp_cmd = "echo \"echo Processing file " + f_obj.path + "\" >> cmd_list.txt;";
          // Look for protocol name in basename to assign output location
          for (p = 0; p < out_dirs.length; p++){
            if (f_obj.basename.includes(inputs.protocol_name[p])){
              cp_cmd += "echo \"cp " + f_obj.path + " " + out_dirs[p] + "/" + protocol_dict[inputs.protocol_name[p]].toString()
              + "_" + f_obj.basename + "\" >> cmd_list.txt;";
              // Also copy associated secondaryFiles - assumes only one!
              if (f_obj.secondaryFiles){
                cp_cmd += "echo \"cp " + f_obj.secondaryFiles[0].path + " " + out_dirs[p] + "/" + protocol_dict[inputs.protocol_name[p]].toString()
              + "_" + f_obj.secondaryFiles[0].basename + "\" >> cmd_list.txt;";
              }
              protocol_dict[inputs.protocol_name[p]] += 1;
              return cp_cmd;
            }
          }
        };

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
        if(inputs.one_d_in == null){
          for (i = 0; i < inputs.protocol_name.length; i++) {
            out_dirs.push(result_dir + "/" + inputs.protocol_name[i]);
            cmd += "mkdir " + out_dirs[i] + ";";
            protocol_dict[inputs.protocol_name[i]] = 0;
          }
          // iterate through multi-D array
          i = 0;
          // point to correct var
          if (inputs.two_d_in){
            var in_array = inputs.two_d_in;
          }
          else{
            var in_array = inputs.three_d_in;
          }
          for (i=0; i< in_array.length; i++){
            var j = 0;
            for (j = 0; j < in_array[i].length; j++){
              // confusingly, cavatica might flatten a 3D array to 2D
              if (in_array[i][j].path){
                cmd += place_file(in_array[i][j], out_dirs, inputs.protocol_name, protocol_dict);
              }
              else{
                // should be a 3D array if you got to here
                var k = 0;
                for (k = 0; k < in_array[i][j].length; k++){
                  cmd += place_file(in_array[i][j][k], out_dirs, inputs.protocol_name, protocol_dict);
                }
              }
            }
          }
        }
        // else if 1D file array, just output to result_dir
        else{
          for (i=0; i< inputs.one_d_in.length; i++){
            cmd += "echo \"cp " + inputs.one_d_in[i].path + " " + result_dir + "/" + i.toString()
            + "_" + inputs.one_d_in[i].basename + "\" >> cmd_list.txt;";
            if (inputs.one_d_in[i].secondaryFiles){
              cmd += "echo \"cp " + inputs.one_d_in[i].secondaryFiles[0].path + " " + result_dir + "/" + i.toString()
            + "_" + inputs.one_d_in[i].secondaryFiles[0].basename + "\" >> cmd_list.txt;";
            }
          }
        }
        return cmd;
      }

      cat cmd_list.txt | xargs -ICMD -P 8 /bin/bash -c "CMD"
inputs:
  three_d_in:
    type:
      - 'null'
      - type: array
        items:
          type: array
          items:
            type: array
            items: File
    doc: "Usually from a pipeline step, protocol x input vcf scatter creating 3D array input like annovar"
  two_d_in:
    type:
      - 'null'
      - type: array
        items:
          type: array
          items: File
    doc: "Usually from a pipeline step, protocol x input vcf scatter creating 2D array input like snpEff"
  one_d_in: {type: 'File[]?', doc: "If coming from a scatter, like VEP, use this"}
  protocol_name: {type: 'string[]?', doc: "If two_d_in, protocol_name array used in scatter"}
  output_basename: string
  tool_name: { type: string, doc: "String of tool name that will be used in the output dirnames"}

outputs:
  output_dirs:
    type: Directory
    outputBinding:
      glob: $(inputs.output_basename + "_" + inputs.tool_name)
