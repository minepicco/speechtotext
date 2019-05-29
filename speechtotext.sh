#!/bin/sh

curl -s -H "Content-Type: application/json"     -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) "https://www.googleapis.com/storage/v1/b/$bucket/o"

curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token)  https://speech.googleapis.com/v1/speech:longrunningrecognize -d @request.json
