#!/bin/sh
if [ "$1" == "" ]; then 
    echo "Please specify your bucket name"
    exit
else 
    bucket=$1
fi
if [ "$2" == "" ]; then
   interval=60
else
   interval=$2
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
    declare -i n=0
    until [ "$n" -gt 1 ]
    do
        curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://speech.googleapis.com/v1/operations/"$line | jq -r ".response.results[] | .alternatives[] | .transcript" > $obj"_.txt"
        cnt=`cat $obj"_.txt" | grep -c ""`
        if [ "$cnt" -gt 1 ]; then
            curl -X PATCH -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) -H "Content-Type: application/json" "https://www.googleapis.com/storage/v1/b/"$bucket"/o/"$obj -d '{"metadata": {"text": "Text was exported to '$obj'_.txt"}}'
            n=1$((n+1))
        elif [ $line = "null" ]; then
            echo "The file "$obj" is not supported file format. skipping..."
            #echo $obj" : "`date` >> SKIPPED_FILES
            n=1$((n+1))
        else
            echo 'The job is not completed sleep another  '$interval' sec...'
            sleep $interval
        fi
    done
    r=$((r+1))
done < $joblist
