# Google Speech to text API test script

## Pre requirement

gcloud must be installed on the machine to execute this script

## script procedure

1. get object list (without meta data) from storage, and output to a local file
https://cloud.google.com/storage/docs/listing-objects?hl=ja
2. iteration
  a. read local file from 1st raw, and substitute into following json
  {
      "config": {
          "encoding":"ENCODING_UNSPECIFIED",
          "languageCode": "ja-JP",
      },
      "audio": {
          "uri":"gs://<$path>/<$object_name>”
      } 
  }
  b. Call speech to text api using created json
  $ curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) https://speech.googleapis.com/v1/speech:longrunningrecognize  -d @<$json>
  c. Wait for 30 sec
  d. get jobID from b. and call the result
  $ curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://speech.googleapis.com/v1/operations/“&<$jobID> | python -m json.tool
  e. Post the values of Transcript to the metadata of the object
  https://cloud.google.com/storage/docs/viewing-editing-metadata?hl=ja

  
 
