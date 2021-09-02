# imdik-zekanowski-sportwgs
WGS of Polish sportsmen

#### *important: please read [important-info.md](preprocessing/important-info.md) before starting to work with this project*

### 1) PREPROCESSING of WGS data

1. All samples were checked with fastqc 0.11.9 with this command:
`docker run --rm -d -v $PWD:/data pegi3s/fastqc /data/{}`
*note: available on io*

2. A report was then generated with multiQC 1.9:
`docker run --rm -v $PWD:/data ewels/multiqc:latest multiqc -m fastqc --sample-names /data/analysis/samples_naming.tsv /data -o /data`
*note: available on io*

3. Each sample was passed through Intelliseq Germline Pipeline (ver 1.8.3) up to the variant calling modules [see wdl here](https://raw.githubusercontent.com/gosborcz/workflows/master/iseq_germline_wgs_1.8.3.wdl).
Inputs were generated with [this script](prepocressing/generate-inputs.sh). To run input first start cromwell server on port 8383 and then run:

`ls inputs/ | xargs -i bash -c 'curl -X POST "http://localhost:8383/api/workflows/v1" -H  "accept: application/json" -H  "Content-Type: multipart/form-data" -F "workflowUrl=https://raw.githubusercontent.com/gosborcz/workflows/master/iseq_germline_wgs_1.7.3.wdl" -F "workflowInputs=@inputs/{};type=application/json" -F "workflowOptions=@options.json;type=application/json"; sleep 60'`

note: To query workflows run on a given day: `curl -X GET "http://localhost:8383/api/workflows/v1/query?submission=2020-10-06T00%3A00%3A00.000Z&status=Running" -H  "accept: application/json"`

### 2) joint genotyping and annotations (two options) 

#### START HERE ####

4. The g.vcf's that were returned from the Intelliseq germline pipeline were thene genotyped according to [this script](https://github.com/ippas/imdik-zekanowski-gts/blob/master/joint_genotyping.md) (update link)


