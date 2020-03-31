# kf-annotation
Variant caller annotation repository. Outputs from variant germline and somatic callers need annotation to add context to calls

### Tools
1) [Annovar](http://annovar.openbioinformatics.org/en/latest/) 2019Oct24
2) [SnpEff](http://snpeff.sourceforge.net/) v4.3t
3) [Variant Effect Predictor](https://useast.ensembl.org/info/docs/tools/vep/index.html) v99
4) [WGS Annotator (WGSA)](https://sites.google.com/site/jpopgen/wgsa) v0.8

### Database Setup
Our implementation focuses on the following databases and what was found to be their ability to be used in the three tools:

| Annotation Database | Annovar          | SnpEff/SnpSift | VEP    |
|---------------------|------------------|----------------|--------|
| CADD                | NA               | NA             | Plugin |
| Clinvar             | clinvar_20190305 | annotate       | Cache  |
| COSMIC              | cosmic90_coding  | annotate       | Cache  |
| dbNSFP              | dbnsfp35c        | dbnsfp         | Plugin |
| dbscSNV             | dbscsnv11        | NA             | Plugin |
| dbSNP               | NA               | annotate       | Cache  |
| ESP65000            | esp6500siv2_all  | annotate       | Cache  |
| ExAC                | exac03           | annotate       | NA     |
| Gnomad              | gnomad30_genome  | annotate       | Cache  |
| GWAS Catalog        | NA               | gwasCat        | Cache? |
| PhyloP              | dbnsfp35c        | NA             | Custom |
| UK10K               | NA               | annotate       | Plugin |
| 1000Genomes         | 1000g2015aug     | annotate       | Cache  |

Ultimately we selected the following tools to use for each annotation:

| Annotation Database | Chosen Tool    |
|---------------------|----------------|
| CADD                | VEP            |
| Clinvar             | SnpEff/SnpSift |
| COSMIC              | Annovar        |
| dbNSFP              | VEP            |
| dbscSNV             | Annovar        |
| dbSNP               | VEP            |
| ESP65000            | Annovar        |
| ExAC                | Not Run        |
| Gnomad              | Annovar        |
| GWAS Catalog        | SnpEff/SnpSift |
| PhyloP              | VEP            |
| UK10K               | VEP            |
| 1000Genomes         | Annovar        |

#### Downloading Annovar Databases
All of the databases detailed above are available to download directly from Annovar. In general, users can use `-downdb -webfrom annovar` in Annovar directly to download these databases.

#### Downloading VEP Databases
The annotations for VEP come from three sources:
1. VEP Cache
2. Plugins with associated databases
3. Custom Annotations

The cache can be downloaded directly from Ensembl. For details on downloading their cache, [visit their documentation](https://useast.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache).
Plugins are another source of annotation for VEP. The plugins are separate perl modules used to process external databases. Each plugin has its own documentation for use, including how what to download and how to include the plugin in the VEP command line. To see how to download the plugins detailed above [visit the VEP plugin page](https://useast.ensembl.org/info/docs/tools/vep/script/vep_plugins.html) and follow the directions in each plugin.
Custom annotations in the form of BigWig files can also be used. As of yet, only one of the databases uses this type of annotation, PhyloP. The BigWig file can be downloaded from [UCSC](ftp://hgdownload.soe.ucsc.edu/goldenPath/hg38/phyloP100way/)

#### Downloading SnpEff/SnpSift
SnpSift provides two dedicated annotation methods in the form of dbnsfp and gwasCat; the rest of the databases are processed using `annotate` on a VCF. The following are links to the databases or places down download them:
- [Clinvar](https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/clinvar.vcf.gz)
- [COSMIC](https://cancer.sanger.ac.uk/cosmic)
- dbNSFP: ftp://dbnsfp:dbnsfp@dbnsfp.softgenetics.com/dbNSFP4.0a.zip
- [dbSNP](https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-All.vcf.gz)
- [ESP6500](http://evs.gs.washington.edu/evs_bulk_data/ESP6500SI-V2-SSA137.GRCh38-liftover.snps_indels.vcf.tar.gz)
- [ExAC](https://storage.googleapis.com/gnomad-public/legacy/exac_browser/ExAC.r1.sites.vep.vcf.gz)
- [Gnomad](https://storage.googleapis.com/gnomad-public/release/3.0/vcf/genomes/gnomad.genomes.r3.0.sites.vcf.bgz)
- [GWASCat](https://www.ebi.ac.uk/gwas/api/search/downloads/alternative)
- UK10K: ftp://ngs.sanger.ac.uk/production/uk10k/UK10K_COHORT/REL-2012-06-02/UK10K_COHORT.20160215.sites.vcf.gz
- [1000G](http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/integrated_sv_map/ALL.wgs.mergedSV.v8.20130502.svs.genotypes.vcf.gz)

Note that some of these are very large and cumbersome. In particular we found that the gnomad and dbSNP databases were either untenably large or took too long to process. As a result, those two were excluded from our SnpEff runs.

### Running [Annovar](https://github.com/kids-first/kf-annotation/blob/master/tools/annovar.cwl)
#### Without DBs
The Annovar tool will run without DBs if provided with a `false` value for `run_dbs`.
#### With DBs
The Annovar tool will run the additional databases if provided with a `true` value for `run_dbs`.
The databases that will be run are the following:
- `dbscsnv11`
- `cosmic90_coding`
- `1000g2015aug_all`
- `esp6500siv2_all`
- `gnomad30_genome`

Each of these databases must be provided in the `additional_dbs` file list input.

### Running SnpEff
#### [Without DBs](https://github.com/kids-first/kf-annotation/blob/master/tools/snpeff_annotate.cwl)
The SnpEff tool itself does not run with any databases. Simply provide the tool with a `ref_tar_gz` and choose the `reference_name`, either `hg38` or `GRCh38.86`.
#### [With DBs](https://github.com/kids-first/kf-annotation/blob/master/workflows/snpeff_snpsift.cwl)
To run SnpEff with additional databases, use the workflow that post processes the output of SnpEff with SnpSift.
Running this tool requires the same `ref_tar_gz` that you would normally hand to SnpEff along with a desired `reference_name`.
Moreover, you need to provide the additional databases as three sets of inputs:
1) `gwas_cat_db_file` This tab separated text file will be run in using a `SnpSift gwasCat` command.
2) `dbnsfp_db_file` This text file and associated tabix will be run using a `SnpSift dbnsfp` command.
3) `vcf_db_files`, `vcf_db_names`, and `vcf_fields`: This file list and two string lists will be dotproduct scattered and run using a `SnpSift annotate` command. The `vcf_db_files` is a list of VCF or otherwise `SnpSift annotate`-compatible files; the `vcf_db_name` is the corresponding simplified name for the files, and `vcf_fields` defines which info fields from the VCF file you wish to use to annotate your input. Here's what an example group of lists would look like:

| vcf_db_files                                                   | vcf_db_names | vcf_fields                  |
|----------------------------------------------------------------|--------------|-----------------------------|
| 1kg-ALL.wgs.mergedSV.v8.20130502.svs.genotypes.vcf.gz          | 1000genomes  | AF_fin,AN_asj,AF_oth_female |
| COSMICv90-CosmicCodingMuts.vcf.gz                              | cosmic       | CDA,dbSNPBuildID,NSF        |
| ESP6500SI-V2-SSA137.GRCh38-liftover.all_chr.snps_indels.vcf.gz | esp          | AC_MALE,ESP_AC              |
| ExAC.r1.sites.vep.vcf.gz                                       | exac         | AF_AMR,AF_ALSPAC            |
| UK10K_COHORT.20160215.sites.vcf.gz                             | uk10k        | SNP,GENE,CDS                |
| clinvar-2020-03-17.vcf.gz                                      | clinvar      | CDS_SIZES,GRCh38_POSITION   |

### Running [Variant Effect Predictor](https://github.com/kids-first/kf-annotation/blob/master/tools/variant_effect_predictor99.cwl)
#### Without DBs
To run VEP without additional DBs, simply set `run_cache_existing` to `false`, `run_cache_af` to `false`, and do not provide the following inputs:
- `cadd_indels`
- `cadd_snvs`
- `dbnsfp`
- `dbscsnv`
- `phylop`
#### With DBs
As many or as few extra databases you provide will be used in annotation; additionally, make sure to set `run_cache_dbs` to `true` as this will add the additional annotations from databases that come with the cache.. All extra databases but phylop are used as plugins. The creation of these files is detailed in the documentation for the plugins on the VEP github.

### Running [WGSA](https://github.com/kids-first/kf-annotation/blob/master/tools/wgsa_annotate.cwl)
This is a comprehensive annotation package that has a precomputed reference for all gene models from ANNOVAR, snpEff, and VEP for all possible snps in hg38 and hg19.  For indels, it will run all three tools (if called for in the config file), as well as many additional databases, most of which come from [here](http://web.corral.tacc.utexas.edu/WGSAdownload/).

#### Inputs:

```yaml
inputs:
  resources: {type: 'File[]', doc: "Reference tar balls needed for WGSA. Min needed wgsa_hg38_resource.tgz, crossover.tgz"}
  annovar_ref: {type: File, doc: "Basic annovar wgsa refs tar ball"}
  snpeff_ref: {type: File, doc: "data tar ball for snpEff containing HG38 nad GRCh38 refs"}
  vep_ref: {type: File, doc: "standard vep cache file"}
  vep_fasta: {type: File, secondaryFiles: ['.fai', '.gzi'], doc: "top level fasta file vep copies when installing"}
  input_vcf:
    type: File
    secondaryFiles: [.tbi]
  settings: {type: File, doc: "Settings file with tool/annotation: (s,i,b,n)"}
  output_basename: string
  tool_name: {type: string, doc: "Meant to helpful to indicate what tools the calls came from"}
```

Resource files recommended for a full snp, indel, and D3b recommnded database run for hg38:
 - precomputed_hg38.tgz # drop if doing indel only
 - dbSNP.tgz
 - GWAS_catalog.tgz
 - wgsa_hg38_resource.tgz
 - 1000Gp3.tgz
 - UK10K.tgz
 - ESP6500.tgz
 - ExACr0.3.tgz
 - dbNSFP.tgz
 - CADDv1.4.tgz
 - clinvar.tgz
 - wgsa_hg19_resource.tgz
 - COSMIC_hg38.tgz
 - PhyloP_hg38.tgz
 - gnomAD.tgz
 - crossmap.tgz

In general, if you disbale a database in the settings file, you can omit loading the file in the resources array.

 Recommended settings file for running recommended databases can be found in the `references/wgsa_all_recommended_db_settings.txt` file.

 #### Outputs:

 ```yaml
 outputs:
  output_annot:
    type: File
    outputBinding:
      glob: '*.wgsa_annotated.txt.*.gz'
    doc: "Merge annotated table"
  output_desc:
    type: 'File[]'
    outputBinding:
      glob: '*.description.txt'
    doc: "Description of databases run"
  job_stdout:
    type: File
    outputBinding:
      glob: '*.stdout'
    doc: "Stdout output for debugging"
  runtime_settings:
    type: File
    outputBinding:
      glob: '*.settings.txt'
    doc: "Run time settings file for debugging"
  runtime_shell_script:
    type: File
    outputBinding:
      glob: '*.settings.txt.sh'
    doc: "WGSA-generated shell script"
```
