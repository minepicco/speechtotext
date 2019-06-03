#!/bin/sh
if [$1 == "" ] then 
    echo "Please specify your bucket name"
    exit
else 
    bucket=$1
fi
if [ $2 == "" ] then
   interval=30
fi

export GOOGLE_APPLICATION_CREDENTIALS="sa.json"
joblist=`date +%s`_jobs.txt

# list objects
curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) "https://www.googleapis.com/storage/v1/b/$bucket/o" | jq  '.items[] | select(has("metadata") | not ) ' | jq -r ".name" > objects.out

# create jobs
while read line
do
    name=$line
    curl -s -H "Content-Type: application/json" -H "Authorization: Bearer "$(gcloud auth application-default print-access-token)  https://speech.googleapis.com/v1/speech:longrunningrecognize -d '{"config": {"encoding":"ENCODING_UNSPECIFIED","languageCode": "ja-JP",},"audio": {"uri":"gs://'$bucket'/'$name'"}}' | jq -r ".name" >> $joblist
done < objects.out

# messages and wait for jobs to complete
echo 'joblist "'$joblist'"is generated'
echo 'sleep '$interval' sec until next step'
sleep $interval
declare -i r=1

# get results based on joblist
while read line
do
    obj=`sed -n $r"P" objects.out`
    curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://speech.googleapis.com/v1/operations/"$line | jq -r ".response.results[] | .alternatives[] | .transcript" > text.txt
    cat text.txt > $obj"_.txt"
    curl -X PATCH -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json" "https://www.googleapis.com/storage/v1/b/"$bucket"/o/"$obj -d '{"metadata": {"text": "`cat text.txt`"}}'
    #declare -i i=1
    #while read line
    #do
    #    curl -X PATCH -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json" "https://www.googleapis.com/storage/v1/b/"$bucket"/o/"$obj -d '{"metadata": {"'$i'": "'$line'"}}'
    #    i=$((i+1))
    #done < text.txt
    r=$((r+1))
done < $joblist
