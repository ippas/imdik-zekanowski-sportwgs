#!/bin/bash

# name log file
# log="/net/archive/groups/plggneuromol/matzieb/resurrection-log/log-file-part1-supplement.txt"
log=$1
echo "#########################################################" > $log
echo "File log for resurrection-plink.sh" >> $log
echo "Information about the tasks to which the signal were sent" >> $log
echo "" >> $log

path_storage_folder=preprocessing/prs-preprocessing/prepare-models
path_log=/net/archive/groups/plggneuromol/matzieb/slurm-log/prepare-models/
end_line_template="Results written to plink.clumped ."
number_loop=1
number_all_singnal=0
interval_sleep=3600
interval_ckeck=20

# wait for running tasks with creating models
sleep $interval_sleep

state_work=$(pro-jobs | grep RUNNING | grep "prepare\-models" | awk '{print $4}')
# tmp state_work
#state_work=$(pro-jobs | grep -v "long" | grep plgrid | awk '{print $2}' | uniq )


while [[ $state_work == "RUNNING" ]]
do 
  number_resurrection_plink=0
  # loop for repating code
  # get list running jobs and save to tmp-pro-jobs.txt
  pro-jobs -N | grep RUNNING | grep -v "prepare\-models" > $path_storage_folder/tmp-pro-jobs.txt

  # while loop for each line
  echo "##########################################" >> $log

  while read line
  do 
    job_id=$(echo $line | awk '{print $1}')
    name_node=$(echo $line | awk '{print $12}')
    end_line=$(cat $path_log/$job_id.out | tail -1)
    
    # first check last line in out file
    echo "First check end out file"
    if [[ $end_line == $end_line_template ]]; then
      sleep $interval_ckeck
      end_line=$(cat $path_log/$job_id.out | tail -1)

      # second check last line in out file
      # redundant check
      echo "Second check end out file"
      if [[ $end_line == $end_line_template ]]; then 
        sleep $interval_ckeck
        end_line=$(cat $path_log/$job_id.out | tail -1)

        # third check last line in out file
        # redundant check
        echo "Third check end out file"
        if [[ $end_line == $end_line_template ]]; then
          # get info about code and coding from out file
          code=$(cat $path_log/$job_id.out | head -4 | grep phenocode | awk '{print $2}')
          coding=$(cat $path_log/$job_id.out | head -4 | grep coding | awk '{print $2}')

          # create scritp to get result from top and save to file
          echo '#!/bin/bash' > $path_storage_folder/tmp-ps-aux.sh
          echo "ps -aux > preprocessing/prs-preprocessing/prepare-models/tmp-ps-aux.txt" >> $path_storage_folder/tmp-ps-aux.sh
          chmod +x $path_storage_folder/tmp-ps-aux.sh
          
          # get info about task inside node
          srun -N1 -n1 --jobid=$job_id -w $name_node $path_storage_folder/tmp-ps-aux.sh < /dev/null
          pid=$(cat $path_storage_folder/tmp-ps-aux.txt | grep "code "$code | grep "coding "$coding | awk '{print $2}')
          
          # save information about task to log file
          echo "Send signal SIGINT to:" >> $log
          echo "job id: "$job_id >> $log
          echo "node name: "$name_node >> $log
          echo "code: "$code >> $log
          echo "coding: "$coding >> $log
          echo "pid: "$pid >> $log

          # sending a signal to the job that hung
          srun -N1 -n1 --jobid=$job_id -w $name_node kill -s SIGINT $pid < /dev/null
          sleep $interval_ckeck

          # check that task resurrection
          end_line=$(cat $path_log/$job_id.out | tail -1)
          if [[ $end_line == $end_line_template ]]; then
            echo "status: plink is not risen" >> $log
            # sleep $interval_ckeck
          else
            echo "status: resurrection plink" >> $log
            # sleep $interval_ckeck
          fi
          echo "" >> $log
           
          # remove tmp file creating during loop
          rm $path_storage_folder/tmp-ps-aux.sh
          rm $path_storage_folder/tmp-ps-aux.txt
          
          number_resurrection_plink=$(( ++number_resurrection_plink ))
          

        else 
          echo "After third check, plink work well."
        fi
      
      else 
        echo "After second check, plink work well."
      fi
    
    else 
      echo "After first check, plink work well."
    fi
    
  done < $path_storage_folder/tmp-pro-jobs.txt

  echo "During "$number_loop" loop send "$number_resurrection_plink "signal SIGINT." >> $log
  echo "##########################################" >> $log
  echo "" >> $log
  
  rm $path_storage_folder/tmp-pro-jobs.txt
  state_work=$(pro-jobs | grep RUNNING | grep "prepare\-models" | awk '{print $4}') 
  # tmp state_work
  # state_work=$(pro-jobs | grep plgrid | awk '{print $2}' | uniq )


  number_loop=$(( ++number_loop))

  number_all_singnal=$(( ++number_resurrection_plink ))
  sleep $interval_sleep
done

echo "" >> $log
echo "##########################################" >> $log
echo "Summary:" >> $log
echo "During work script execute:" >> $log
echo "number loop:     "$number_loop >> $log
echo "interval sleep:  "$interval_sleep >> $log
echo "all sent signal: "$number_all_singnal >> $log
echo "##########################################" >> $log

