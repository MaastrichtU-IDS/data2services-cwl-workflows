#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
label: Convert XML files to a target RDF

inputs:
  - id: input_dir
    label: "Directory with downloaded input files"
    type: Directory
  - id: config_dir
    label: "CWL config directory (config.yml)"
    type: Directory
  - id: cwl_workflow_filename
    label: "CWL workflow definition file (workflow-xml.cwl)"
    type: string
  - id: cwl_dir
    label: "CWL workflow directory (workflow.cwl)"
    type: Directory
  - id: download_username
    label: "Username to download files"
    type: string?
  - id: download_password
    label: "Password to download files"
    type: string?
  # tmp RDF4J server SPARQL endpoint to load generic RDF
  - id: sparql_tmp_triplestore_url
    label: "URL of tmp triplestore"
    type: string
  - id: sparql_tmp_service_url
    label: "Service URL of tmp triplestore"
    type: string
  - id: sparql_tmp_graph_uri
    label: "URI of tmp graph"
    type: string
  - id: sparql_tmp_triplestore_username
    label: "Username for tmp triplestore"
    type: string?
  - id: sparql_tmp_triplestore_password
    label: "Password for tmp triplestore"
    type: string?
  # Final RDF4J server SPARQL endpoint to load the BioLink RDF
  - id: sparql_final_triplestore_url
    label: "URL of final triplestore"
    type: string
  - id: sparql_final_triplestore_username
    label: "Username for final triplestore"
    type: string?
  - id: sparql_final_triplestore_password
    label: "Password for final triplestore"
    type: string?
  - id: sparql_final_graph_uri
    label: "Graph URI of transformed RDF"
    type: string
  - id: sparql_insert_metadata_path
    label: "Path to queries to insert metadata"
    type: string
  - id: sparql_transform_queries_path
    label: "Path to queries to transform generic RDF"
    type: string
  - id: sparql_compute_hcls_path
    label: "Path to queries to compute HCLS stats"
    type: string
    default: https://github.com/MaastrichtU-IDS/d2s-transform-repository/tree/master/sparql/compute-hcls-stats
  - id: hcls_metadata_graph_uri
    label: "URI of the HCLS metadata graph"
    type: string
    default: https://w3id.org/d2s/metadata

outputs:
  # - id: download_dir
  #   outputSource: step1-d2s-download/download_dir
  #   type: Directory
  #   label: "Downloaded files"
  # - id: logs_download_dataset
  #   outputSource: step1-d2s-download/logs_download_dataset
  #   type: File
  #   label: "Download script log file"
  - id: sparql_mapping_templates
    outputSource: step2-xml2rdf/sparql_mapping_templates
    type: Directory
    label: "xml2rdf SPARQL mapping templates files"
  - id: xml2rdf_nquads_file_output
    outputSource: step2-xml2rdf/xml2rdf_nquads_file_output
    type: File
    label: "Nquads file produced by xml2rdf"
  - id: logs_xml2rdf
    outputSource: step2-xml2rdf/logs_xml2rdf
    type: File
    label: "xml2rdf log file"
  - id: logs_create_graphdb_repo
    outputSource: step3-graphdb-create-repo/logs_create_graphdb_repo
    type: File
    label: "Log file for creating GraphDB repo"
  - id: logs_rdf_upload
    outputSource: step4-rdf-upload/logs_rdf_upload
    type: File
    label: "RDF Upload log file"
  - id: cwl_workflow_rdf_description_file
    outputSource: step5-get-cwl-rdf/cwl_workflow_rdf_description_file
    type: File
    label: "CWL workflow RDF description file"
  - id: logs_upload_cwl_rdf
    outputSource: step6-upload-cwl-rdf/logs_rdf_upload
    type: File
    label: "CWL RDF Upload log file"
  - id: sparql_insert_metadata_logs
    outputSource: step5-insert-metadata/logs_execute_sparql_query_
    type: File
    label: "SPARQL insert metadata log file"
  - id: sparql_transform_queries_logs
    outputSource: step6-execute-transform-queries/logs_execute_sparql_query_
    type: File
    label: "SPARQL transform queries log file"
  - id: sparql_hcls_statistics_logs
    outputSource: step7-compute-hcls-stats/logs_execute_sparql_query_
    type: File
    label: "SPARQL HCLS statistics log file"


steps:
  # step1-d2s-download:
  #   run: ../steps/d2s-bash-download.cwl
  #   in:
  #     config_dir: config_dir
  #     download_username: download_username
  #     download_password: download_password
  #   out: [download_dir, logs_download_dataset]

  step2-xml2rdf:
    run: ../steps/run-xml2rdf.cwl
    in:
      download_dir: input_dir
    out: [xml2rdf_nquads_file_output, logs_xml2rdf, sparql_mapping_templates]
    # out: [xml2rdf_nquads_file_output, logs_xml2rdf, sparql_mapping_templates]

  step3-graphdb-create-repo:
    run: ../steps/graphdb-create-repo.cwl
    in:
      cwl_dir: cwl_dir
      previous_step_output: step2-xml2rdf/logs_xml2rdf
    out: [logs_create_graphdb_repo]

  step4-rdf-upload:
    run: ../steps/rdf-upload.cwl
    # run: ../steps/virtuoso-bulk-load.cwl
    in:
      file_to_load: step2-xml2rdf/xml2rdf_nquads_file_output
      sparql_triplestore_url: sparql_tmp_triplestore_url
      sparql_username: sparql_tmp_triplestore_username
      sparql_password: sparql_tmp_triplestore_password
      previous_step_output: step3-graphdb-create-repo/logs_create_graphdb_repo
    out: [logs_rdf_upload]

  step5-insert-metadata:
    run: ../steps/execute-sparql-queries.cwl
    in:
      config_dir: config_dir
      sparql_queries_path: sparql_insert_metadata_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_input_graph_uri: sparql_final_graph_uri
      sparql_output_graph_uri: hcls_metadata_graph_uri
      previous_step_output: step4-rdf-upload/logs_rdf_upload
    out: [logs_execute_sparql_query_]

  # TODO: do it before the RdfUpload to tmp repo?
  # Generate RDF describing CWL workflows and upload it to final triplestore
  step5-get-cwl-rdf:
    run: ../steps/cwl-print-rdf.cwl
    in:
      cwl_workflow_filename: cwl_workflow_filename
      cwl_dir: cwl_dir
      previous_step_output: step4-rdf-upload/logs_rdf_upload
    out: [cwl_workflow_rdf_description_file]

  step6-upload-cwl-rdf:
    run: ../steps/rdf-upload.cwl
    in:
      file_to_load: step5-get-cwl-rdf/cwl_workflow_rdf_description_file
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      output_graph_uri: hcls_metadata_graph_uri
    out: [logs_rdf_upload]

  step6-execute-transform-queries:
    run: ../steps/execute-sparql-queries.cwl
    in:
      config_dir: config_dir
      sparql_queries_path: sparql_transform_queries_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_input_graph_uri: sparql_tmp_graph_uri
      sparql_output_graph_uri: sparql_final_graph_uri
      sparql_service_url: sparql_tmp_service_url
      previous_step_output: step4-rdf-upload/logs_rdf_upload
    out: [logs_execute_sparql_query_]

  step7-compute-hcls-stats:
    run: ../steps/execute-sparql-queries-url.cwl
    in: # No sparql_queries_path, HCLS stats is the default
      sparql_queries_path: sparql_compute_hcls_path
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      sparql_input_graph_uri: sparql_final_graph_uri
      sparql_output_graph_uri: hcls_metadata_graph_uri
      previous_step_output: step6-execute-transform-queries/logs_execute_sparql_query_
    out: [logs_execute_sparql_query_]


$namespaces:
  s: "http://schema.org/"
  dct: "http://purl.org/dc/terms/"
  foaf: "http://xmlns.com/foaf/0.1/"
  edam: "http://edamontology.org/"
$schemas:
  - http://schema.org/version/latest/schema.rdf
  - https://lov.linkeddata.es/dataset/lov/vocabs/dcterms/versions/2012-06-14.n3
  - http://xmlns.com/foaf/spec/index.rdf
  - http://edamontology.org/EDAM_1.18.owl

dct:creator:
  class: foaf:Person
  "@id": "https://orcid.org/0000-0002-1501-1082"
  foaf:name: "Vincent Emonet"
  foaf:mbox: "mailto:vincent.emonet@gmail.com"

dct:contributor:
  class: foaf:Person
  "@id": "https://orcid.org/0000-0000-ammar-ammar"
  foaf:name: "Ammar Ammar"
  foaf:mbox: "mailto:a.ammar@student.maastrichtuniversity.nl"

dct:license: "https://opensource.org/licenses/MIT"
s:citation: "https://swat4hcls.figshare.com/articles/Data2Services_enabling_automated_conversion_of_data_to_services/7345868/files/13573628.pdf"
s:codeRepository: https://github.com/MaastrichtU-IDS/d2s-cwl-workflows

edam:has_function:
  - edam:operation_2429   # Mapping
  - edam:operation_1812   # Parsing

edam:has_input: 
  - edam:data_3786      # Query script
  - edam:format_3857    # CWL
  - edam:format_3790    # SPARQL

edam:has_output:
  - edam:format_2376    # RDF format
  - edam:data_3509      # Ontology mapping

edam:has_topic:
  - edam:topic_0769   # Workflows
  - edam:topic_0219   # Data submission, annotation and curation
  - edam:topic_0102   # Mapping
  - edam:topic_3345   # Data identity and mapping