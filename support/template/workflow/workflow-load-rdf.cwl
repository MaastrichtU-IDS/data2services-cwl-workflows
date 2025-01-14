#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
label: Load CWL descriptions as RDF

inputs:
  - id: cwl_workflow_filename
    label: "CWL workflow definition file"
    type: string
  - id: cwl_dir
    label: "CWL config directory"
    type: Directory
  - id: download_username
    label: "Username to download files"
    type: string?
  - id: download_password
    label: "Password to download files"
    type: string?
  # Final RDF4J server SPARQL endpoint to load generic RDF
  - id: sparql_final_triplestore_url
    label: "URL of final triplestore"
    type: string
  - id: sparql_final_triplestore_username
    label: "Username for final triplestore"
    type: string?
  - id: sparql_final_triplestore_password
    label: "Password for final triplestore"
    type: string?
  # - id: sparql_tmp_service_url
  #   label: "Service URL of tmp triplestore"
  #   type: string


outputs:
  - id: cwl_workflow_rdf_description_file
    outputSource: step1-get-cwl-rdf/cwl_workflow_rdf_description_file
    type: File
    label: "CWL workflow RDF description file"
  - id: logs_rdf_upload
    outputSource: step4-rdf-upload/logs_rdf_upload
    type: File
    label: "CWL RDF Upload log file"
  # - id: r2rml_nquads_file_output
  #   outputSource: step3-r2rml/r2rml_nquads_file_output
  #   type: File
  #   label: "Nquads file produced by R2RML"
  # - id: sparql_insert_metadata_logs
  #   outputSource: step5-insert-metadata/logs_execute_sparql_query_
  #   type: File
  #   label: "SPARQL insert metadata log file"
  # - id: sparql_transform_queries_logs
  #   outputSource: step6-execute-transform-queries/logs_execute_sparql_query_
  #   type: File
  #   label: "SPARQL transform queries log file"


steps:
# run cwl-tool
# run rdfupload
# run replace on file before load or SPARQL queries?
  step1-get-cwl-rdf:
    run: ../steps/cwl-print-rdf.cwl
    in:
      cwl_workflow_filename: cwl_workflow_filename
      cwl_dir: cwl_dir
    out: [cwl_workflow_rdf_description_file]

  step4-rdf-upload:
    run: ../steps/rdf-upload.cwl
    # run: ../steps/virtuoso-bulk-load.cwl
    in:
      file_to_load: step1-get-cwl-rdf/cwl_workflow_rdf_description_file
      sparql_triplestore_url: sparql_final_triplestore_url
      sparql_username: sparql_final_triplestore_username
      sparql_password: sparql_final_triplestore_password
      # TODO: Add Graph URI?
    out: [logs_rdf_upload]

  # step2-autor2rml:
  #   run: ../steps/run-autor2rml.cwl
  #   in:
  #     download_dir: step1-get-cwl-rdf/download_dir
  #     input_data_jdbc: input_data_jdbc
  #   out: [r2rml_trig_file_output, sparql_mapping_templates, logs_autor2rml]

  # step3-r2rml:
  #   run: ../steps/run-r2rml.cwl
  #   in:
  #     r2rml_trig_file: step2-autor2rml/r2rml_trig_file_output
  #     input_data_jdbc: input_data_jdbc
  #   out: [r2rml_nquads_file_output, logs_r2rml]

  # step5-insert-metadata:
  #   run: ../steps/execute-sparql-queries.cwl
  #   in:
  #     sparql_queries_path: sparql_insert_metadata_path
  #     sparql_triplestore_url: sparql_final_triplestore_url
  #     sparql_username: sparql_final_triplestore_username
  #     sparql_password: sparql_final_triplestore_password
  #     sparql_output_graph_uri: sparql_final_graph_uri
  #     previous_step_output: step4-rdf-upload/logs_rdf_upload
  #   out: [logs_execute_sparql_query_]

  # step6-execute-transform-queries:
  #   run: ../steps/execute-sparql-queries.cwl
  #   in:
  #     sparql_queries_path: sparql_transform_queries_path
  #     sparql_triplestore_url: sparql_final_triplestore_url
  #     sparql_username: sparql_final_triplestore_username
  #     sparql_password: sparql_final_triplestore_password
  #     # sparql_input_graph_uri: sparql_tmp_graph_uri
  #     sparql_output_graph_uri: sparql_final_graph_uri
  #     sparql_service_url: sparql_tmp_service_url
  #     previous_step_output: step4-rdf-upload/logs_rdf_upload
  #   out: [logs_execute_sparql_query_]

  # step7-compute-hcls-stats:
  #   run: ../steps/execute-sparql-queries.cwl
  #   in: # No sparql_queries_path, HCLS stats is the default
  #     sparql_queries_path: sparql_compute_hcls_path
  #     sparql_triplestore_url: sparql_final_triplestore_url
  #     sparql_username: sparql_final_triplestore_username
  #     sparql_password: sparql_final_triplestore_password
  #     sparql_input_graph_uri: sparql_final_graph_uri
  #     previous_step_output: step6-execute-transform-queries/logs_execute_sparql_query_
  #   out: [logs_execute_sparql_query_]


$namespaces:
  s: "http://schema.org/"
  dct: "http://purl.org/dc/terms/"
  foaf: "http://xmlns.com/foaf/0.1/"
  edam: "http://edamontology.org/"
$schemas:
  - https://schema.org/version/latest/schemaorg-current-http.rdf
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
s:codeRepository: https://github.com/MaastrichtU-IDS/d2s-core

edam:has_function:
  - edam:operation_1812   # Parsing
  - edam:operation_2429   # Mapping

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