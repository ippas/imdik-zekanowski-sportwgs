#!/bin/bash

for var in `ls -d fastq/B*`
do
        file_number=`ls $var/*fq.gz | wc -l`
        if [ $file_number -eq 2 ]
        then
                echo `ls $var/*fq.gz` | xargs -n2 bash -c 'file1=$(echo ${0} | cut -d "/" -f 2,3,4 );
                file2=$(echo ${1} | cut -d "/" -f 2,3,4 );
                sample=$(echo $file1 | cut -d "/" -f 1);
                echo $file1 $file2 $sample' | xargs -n3 bash -c 'echo "{\"germline.genome_or_exome\": \"genome\",\"germline.sample_id\": \"$2\",\"germline.fastqs\": [\"gs://sportsmen-wgs/${0}\", \"gs://sportsmen-wgs/${1}\"]}">inputs/${2}-input.json'
        elif [ $file_number -eq 4 ]
        then
	        echo `ls $var/*fq.gz` | xargs -n4 bash -c 'file1=$(echo ${0} | cut -d "/" -f 2,3,4 );
                file2=$(echo ${1} | cut -d "/" -f 2,3,4 );
                file3=$(echo ${2} | cut -d "/" -f 2,3,4 );
                file4=$(echo ${3} | cut -d "/" -f 2,3,4 );
                sample=$(echo $file1 | cut -d "/" -f 1);
                echo $file1 $file2 $file3 $file4 $sample' | xargs -n5 bash -c 'echo "{\"germline.genome_or_exome\": \"genome\",\"germline.sample_id\": \"$4\",\"germline.fastqs\": [\"gs://sportsmen-wgs/${0}\", \"gs://sportsmen-wgs/${1}\", \"gs://sportsmen-wgs/${2}\", \"gs://sportsmen-wgs/${3}\"]}">inputs/${4}-input.json'
        elif [ $file_number -eq 6 ]
        then  echo `ls $var/*fq.gz` | xargs -n6 bash -c 'file1=$(echo ${0} | cut -d "/" -f 2,3,4 );
              file2=$(echo ${1} | cut -d "/" -f 2,3,4 );
              file3=$(echo ${2} | cut -d "/" -f 2,3,4 );
              file4=$(echo ${3} | cut -d "/" -f 2,3,4 );
              file5=$(echo ${4} | cut -d "/" -f 2,3,4 );
              file6=$(echo ${5} | cut -d "/" -f 2,3,4 );
              sample=$(echo $file1 | cut -d "/" -f 1);
              echo $file1 $file2 $file3 $file4 $file5 $file6 $sample' | xargs -n7 bash -c 'echo "{\"germline.genome_or_exome\": \"genome\",\"germline.sample_id\": \"$6\",\"germline.fastqs\": [\"gs://sportsmen-wgs/${0}\", \"gs://sportsmen-wgs/${1}\", \"gs://sportsmen-wgs/${2}\", \"gs://sportsmen-wgs/${3}\", \"gs://sportsmen-wgs/${4}\", \"gs://sportsmen-wgs/${5}\"]}">inputs/${6}-input.json'
        else echo "there is a wrong number of files in $var"
        fi
done
