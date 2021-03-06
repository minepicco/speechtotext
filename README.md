# Google Speech to text API test script

## Pre requirements

1. gcloud must be installed on the machine to execute this script.

2. "jq" is installed

3. create service account and update sa.json with the credential. 

## Usage
1. clone script to your machine.
<pre>$ git clone https://github.com/minepicco/speechtotext.git </pre>
2. cd to the directory and add execute permission to speechtotext.sh
<pre>$ chmod +x speechtotext.sh</pre>
3. execute with parameter(s)
<pre>$ ./speechtotext.sh [YOUR BUCKET NAME] [[Optional] Interval from job request until results request] </pre>
  e.g.
  <pre>$ ./speechtotext.sh my_bucket 10</pre>

## script description

1. get object list (without meta data) from storage, and output to a local file
https://cloud.google.com/storage/docs/listing-objects?hl=ja

2. iteration

  a. read local file from 1st raw, and substitute into following json
  <pre>{
      "config": {
          "encoding":"ENCODING_UNSPECIFIED",
          "languageCode": "ja-JP",
      },
      "audio": {
          "uri":"gs://<$path>/<$object_name>”
      } 
  }</pre>
  b. Call speech to text api using created json
  <pre>$ curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) https://speech.googleapis.com/v1/speech:longrunningrecognize  -d @$json</pre>
  
  c. Wait for N sec (default is 60)
  
  d. get jobID from b. and call the result
  <pre>$ curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://speech.googleapis.com/v1/operations/“$jobID </pre>
  
  e. Write the values of Transcript to text and update metadata of the object

  
 
