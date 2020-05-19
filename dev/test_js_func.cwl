cwlVersion: v1.0
class: CommandLineTool
id: test_js_func
doc: "Dummy tool to test js func capabilities"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
    expressionLib:
    - |-
      var process_str_array = function(str_array){
          var contents_as_str = str_array[0] + " " + str_array[1]
          return contents_as_str
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
          var check = process_str_array(inputs.simple_array);
          return "echo \"" + check + "\" > output.txt"; 
      }

inputs:
  simple_array: string[]

outputs:
  output_txt:
    type: File
    outputBinding:
      glob: '*.txt'
