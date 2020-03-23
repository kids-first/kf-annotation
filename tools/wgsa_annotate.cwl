cwlVersion: v1.0
class: CommandLineTool
id: kfdrc-wgsa-annotate
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'migbro/wgsa:0.8'
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      mkdir resources && cd resources

      ${
        var cmd = "";
        for (var i=0; i < inputs.resources.length; i++){
            cmd += "tar --use-compress-program=pigz -xf " + inputs.resources[i].path + ";";
        }
        return cmd;
      }

      ln -s /WGSA/resources/javaclass ./ && cd ../ && mkdir annovar20180416 snpeff vep .vep TMP INTERMEDIATE

      cd annovar20180416 && mkdir annovar && ln -s /WGSA/annovar20180416/annovar/* annovar && rm -rf annovar/humandb && cd annovar && tar --use-compress-program=pigz -xf $(inputs.annovar_ref.path)

      cd ../../snpeff && mkdir snpEff && ln -s /WGSA/snpeff/clinEff ./ && cp -r /WGSA/snpeff/snpEff/* snpEff && cd snpEff && tar --use-compress-program=pigz -xf $(inputs.snpeff_ref.path)

      cd ../../.vep && ln -s /WGSA/.vep/Plugins ./ && tar --use-compress-program=pigz -xf $(inputs.vep_ref.path)
      && mkdir -p homo_sapiens/94_GRCh38 && ln -s $(inputs.vep_fasta.path) homo_sapiens/94_GRCh38/
      && ln -s $(inputs.vep_fasta.secondaryFiles[0].path) homo_sapiens/94_GRCh38/ && ln -s $(inputs.vep_fasta.secondaryFiles[1].path) homo_sapiens/94_GRCh38/

      cd ../vep && ln -s /WGSA/vep/ensembl-vep . && cd ../

      echo "input file name: $(inputs.input_vcf.path)" > $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo "output file name: $(inputs.output_basename).$(inputs.tool_name).wgsa_annotated.txt" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo "resources dir: $PWD/resources/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo "annovar dir: $PWD/annovar20180416/annovar/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo "snpeff dir: $PWD/snpeff/snpEff/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt
      
      echo "vep dir: $PWD/vep/ensembl-vep/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo ".vep dir: $PWD/.vep/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt
      
      echo "tmp dir: $PWD/TMP/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo "work dir: $PWD/INTERMEDIATE/" >> $(inputs.output_basename).$(inputs.tool_name).settings.txt
      
      cat $(inputs.settings.path) >> $(inputs.output_basename).$(inputs.tool_name).settings.txt

      echo Understand | java -cp /WGSA/:$PWD WGSA08 $(inputs.output_basename).$(inputs.tool_name).settings.txt -m 30 -t 16 -v hg38 -i $(inputs.input_vcf.path)

      sed -i.old '1s;^;set -eo pipefail\n;' $(inputs.output_basename).$(inputs.tool_name).settings.txt.sh

      bash $(inputs.output_basename).$(inputs.tool_name).settings.txt.sh | tee > $(inputs.output_basename).$(inputs.tool_name).stdout

inputs:
  resources: {type: 'File[]', doc: "Reference tar balls needed for WGSA. Min needed precomputed_hg38.tgz, wgsa_hg38_resource.tgz "}
  annovar_ref: {type: File, doc: "Basic annovar wgsa refs tar ball"}
  snpeff_ref: {type: File, doc: "data tar ball for snpEff contaning HG38 nad GRCh38 refs"}
  vep_ref: {type: File, doc: "standard vep cache file"}
  vep_fasta: {type: File, secondaryFiles: ['.fai', '.gzi'], doc: "top level fasta file vep copies when installing"}
  input_vcf:
    type: File
    secondaryFiles: [.tbi]
  settings: {type: File, doc: "Settings file with tool/annotation: (s,i,b,n)"}
  output_basename: string
  tool_name: {type: string, doc: "Meant to helpful to indicate what tools the calls came from"}

outputs:
  output_annot:
    type: File
    outputBinding:
      glob: '*.wgsa_annotated.txt.*.gz'
  output_desc:
    type: 'File[]'
    outputBinding:
      glob: '*.description.txt'
  job_stdout:
    type: File
    outputBinding:
      glob: '*.stdout'
  runtime_settings:
    type: File
    outputBinding:
      glob: '*.settings.txt'
  runtime_shell_script:
    type: File
    outputBinding:
      glob: '*.settings.txt.sh'

$namespaces:
  sbg: https://sevenbridges.com
hints:
    - class: 'sbg:AWSInstanceType'
      value: c5.4xlarge;ebs-gp2;2048
