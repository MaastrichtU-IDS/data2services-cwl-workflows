# CWL workflows for Data2Services

The [Common Workflow Language](https://www.commonwl.org/) is used to describe workflows to transform heterogeneous structured data (CSV, TSV, RDB, XML, JSON) to a target RDF data model. A generic RDF is generated depending on the input data structure (AutoR2RML, xml2rdf), then [SPARQL queries](https://github.com/MaastrichtU-IDS/data2services-transform-biolink/blob/master/mapping/pharmgkb/insert-pharmgkb.rq), defined by the user, are executed to transform the generic RDF to the target data model.

---

## Running examples

The [data2services-transform-biolink](https://github.com/MaastrichtU-IDS/data2services-transform-biolink) project will be used as example to transform XML, TSV, CSV, RDB, JSON to the [BioLink](https://biolink.github.io/biolink-model/docs/) RDF data model.

* Clone the repository with its submodules

```shell
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-transform-biolink.git
```

* Install [Docker](https://docs.docker.com/install/) to run the modules.
* Install [cwltool](https://github.com/common-workflow-language/cwltool#install) to get cwl-runner to run workflows of Docker modules.

```shell
apt-get install cwltool
```

* Those workflows use Data2Services modules, see the [data2services-pipeline](https://github.com/MaastrichtU-IDS/data2services-pipeline) project.
* It is recommended to build the Docker images before running workflows, as the `docker pull` might crash when done through `cwl-runner`.

---

### Types of workflows

See the [data2services-transform-biolink](https://github.com/MaastrichtU-IDS/data2services-transform-biolink) project for examples of 3 types of workflows that can be run depending on the input data:

- [Convert XML to RDF](https://github.com/MaastrichtU-IDS/data2services-transform-biolink#convert-xml-with-xml2rdf)
- [Convert CSV to RDF](https://github.com/MaastrichtU-IDS/data2services-transform-biolink#convert-csvtsv-with-autor2rml)
- [Convert CSV to RDF and split a property](https://github.com/MaastrichtU-IDS/data2services-transform-biolink#convert-csvtsv-with-autor2rml-and-split-a-property)

---

### Start services

[Apache Drill](https://github.com/amalic/apache-drill) and [GraphDB](https://github.com/MaastrichtU-IDS/graphdb/) services must be running before executing CWL workflows.

GraphDB needs to be built locally, for this:

* Download GraphDB as a stand-alone server free version (zip): https://ontotext.com/products/graphdb/.
* Put the downloaded `.zip` file in the GraphDB repository (cloned from [GitHub](https://github.com/MaastrichtU-IDS/graphdb/)).
* Run `docker build -t graphdb --build-arg version=CHANGE_ME .` in the GraphDB repository.

```shell
# Start Apache Drill sharing volume with this repository.
# Here shared locally at /data/data2services-transform-biolink
docker run -dit --rm -v /data/data2services-transform-biolink:/data:ro -p 8047:8047 -p 31010:31010 --name drill vemonet/apache-drill

# GraphDB needs to be downloaded manually and built. 
# Here shared locally at /data/graphdb and /data/graphdb-import
docker build -t graphdb --build-arg version=8.11.0 .
docker run -d --rm --name graphdb -p 7200:7200 -v /data/graphdb:/opt/graphdb/home -v /data/graphdb-import:/root/graphdb-import graphdb
```

---

### Run with [CWL](https://www.commonwl.org/)

* Go to the `data2services-transform-biolink` root folder (the root of the cloned repository)
  - e.g. `/data/data2services-transform-biolink` to run the CWL workflows.
* You will need to put the SPARQL mapping queries in `/mappings/$dataset_name` and provide 3 parameters:
  - `--outdir`: the [output directory](https://github.com/MaastrichtU-IDS/data2services-transform-biolink/tree/master/output/stitch) for files outputted by the workflow (except for the downloaded source files that goes automatically to `/input`). 
    - e.g. `output/$dataset_name`.
  - The `.cwl` [workflow file](https://github.com/MaastrichtU-IDS/data2services-transform-biolink/blob/master/support/cwl/workflow-xml.cwl)
    - e.g. `data2services-cwl-workflows/workflows/workflow-xml.cwl`
  - The `.yml` [configuration file](https://github.com/MaastrichtU-IDS/data2services-transform-biolink/blob/master/support/cwl/config/config-transform-xml-drugbank.yml) with all parameters required to run the workflow
    - e.g. `support/config/config-transform-xml-drugbank.yml`

### Run in the background

Will write all terminal output to `nohup.out`.

```shell
nohup cwl-runner --outdir output/drugbank data2services-cwl-workflows/workflows/workflow-xml.cwl support/config/config-transform-xml-drugbank.yml &
```



---

# Argo workflows

See [Argo README](https://github.com/MaastrichtU-IDS/data2services-argo-workflows) to run workflows with Argo.