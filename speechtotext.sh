#!/bin/sh
bucket="<YOUR BUCKET NAME>"

export GOOGLE_APPLICATION_CREDENTIALS="sa.json"

curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) "https://www.googleapis.com/storage/v1/b/$bucket/o" | jq -r ".items[] | .name" > objects.out

while read line
do
    oname=$line
    jobid=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token)  https://speech.googleapis.com/v1/speech:longrunningrecognize -d '{"config": {"encoding":"ENCODING_UNSPECIFIED","languageCode": "ja-JP",},"audio": {"uri":"gs://'$bucket'/'$oname'"}}' | jq -r .name)
    sleep 30
    curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://speech.googleapis.com/v1/operations/"$jobid | jq -r ".response.results[] | .alternatives[] | .transcript" > text.txt
    while read line
    do
        curl -X PATCH -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json" "https://www.googleapis.com/storage/v1/b/"$bucket"/o/"$oname -d '{"metadata": {"transcript": '$line'}}'
    done < text.txt
done < objects.out
