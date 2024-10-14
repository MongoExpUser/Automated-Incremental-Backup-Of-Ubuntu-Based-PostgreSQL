
#!/bin/sh

# ***************************************************************************************************************************************
#  * auto-incremental-backup.sh                                                                                                         *
#  **************************************************************************************************************************************
#  *                                                                                                                                    *
#  * @License Starts                                                                                                                    *
#  *                                                                                                                                    *
#  * Copyright © 2024. MongoExpUser.  All Rights Reserved.                                                                              *
#  *                                                                                                                                    *
#  * License: Apache 2.0 - https://github.com/MongoExpUser/Automated-Incremental-Backup-Of-Ubuntu-Based-PostgreSQL/blob/main/LICENSE    *
#  *                                                                                                                                    *
#  * @License Ends                                                                                                                      *
#  **************************************************************************************************************************************
# *                                                                                                                                     *
# *  Project: Automated Incremental Backup On Ubuntu-Based PostgreSQL (Require PostgreSQL 17+)                                          *
# *                                                                                                                                     *
# *  This script:                                                                                                                       *
# *                                                                                                                                     *
# *     1)  Automates Incremental Database Backup On Ubuntu-Based PostgreSQL and Uplaodd to Object Storage                              *
# *                                                                                                                                     *
# **************************************************************************************************************************************/

# ***************************************************************************************************************************************
#  Run the script with following commands                                                                                               *
#  -------------------------------------------------------------------------------------------------------------------------------------*
#  if [[ -f tasks.log ]]; then  echo 'Deleting message log file...'; sudo rm tasks.log; fi                                              *
#  sudo echo '#.. ' > tasks.log && sudo chmod 777 tasks.log                                                                             *
#  sudo chmod u+x auto-incremental-backup.sh && sudo bash auto-incremental-backup.sh >> tasks.log 2>&1                                  *
# ***************************************************************************************************************************************




# define common variables
nth=5                                                                           # only 5 times - use this for testing
testTnterval=600                                                                # every 600 seconds - use this for testing
interval=86400                                                                  # every one-day (86400) or every 6 hours (21600)
specified='true'                                                                # set this to true for testing
forever='false'                                                                 # set this to true for production deployment: run for ever untill script is interrupted
set PWD=%cd%
base=$PWD
bucketpath='bucketname/psql-full' 
initial_full='true'
host='localhost'
port=5432
user='user'
pasd='pasd'
full="$base/datafull"
increment="$base/dataincr"
merge='/var/lib/postgresql/17/main/data'
aws_credential_profile_name='default' # ensure that profile is configured on the Ubuntu OS => See: https://docs.aws.amazon.com/cli/latest/reference/configure/


# configure some S3 options programatically
sudo aws configure set default.s3.max_concurrent_requests 20 --profile $aws_credential_profile_name
sudo aws configure set default.s3.max_bandwidth 100MB/s --profile $aws_credential_profile_name
sudo aws configure set default.s3.multipart_threshold 10MB --profile $aws_credential_profile_name
sudo aws configure set default.s3.multipart_chunksize 10MB --profile $aws_credential_profile_name


initial_full_backup()
{
    # take the initial full backup with pg_basebackup (once)
    if [[ -d $full ]]; then echo "Deleting $full ..." && sudo rm -rf $full; fi
    sudo mkdir -p $full
    sudo chmod 700 $full
    sudo chown postgres $full
    sudo chown -R postgres:postgres $full
    echo '==================================================='
    echo "Initial (once) full backup in progress ...."
    echo '==================================================='
    sudo PGPASSWORD=$pasd pg_basebackup -h $host -U $user -p $port -D $full -c fast -v
    sudo ls -lhs $full 
    sudo du -sh $full
}

incremental_backup_and_merge()
{
    #  take incremental backup with pg_basebackup (daily or at specified interval, say hrs)
    if [[ -d $increment ]]; then echo "Deleting $increment ..." && sudo rm -rf $increment; fi
    sudo mkdir -p $increment
    sudo chmod 700 $increment
    sudo chown postgres $increment
    sudo chown -R postgres:postgres $increment
    echo '==================================================='
    echo "Incremental backup in progress ...."
    echo '==================================================='
    sudo PGPASSWORD=$pasd pg_basebackup -h $host -U $user -p $port -D $increment -i $full/backup_manifest -c fast -v
    sudo ls -lhs $increment
    sudo du -sh $increment
}

upload_merged_backup()
{
    # a. merge full and increment into a "merge folder" (i.e. new full) with pg_combinebackup
    if [[ -d $merge ]]; then echo "Deleting $merge ..." && sudo rm -rf $merge; fi
    sudo mkdir -p $merge
    echo '======================================================='
    echo "Merge of incremental and full backups in progress ...."
    echo '======================================================='
    sudo -u root /usr/lib/postgresql/17/bin/pg_combinebackup -o $merge $full $increment # --debug --dry-run
    sudo chmod 700 -R $merge 
    sudo chown postgres $merge
    sudo chown -R postgres:postgres $merge
    sudo ls -lhs $merge && sudo du -sh $merge

    # b. check sizes of full, incremental and merge folders
    sudo du -sh $full
    sudo du -sh $increment
    sudo du -sh $merge

    # c. delete previous uploaded  files in the object storage
    echo "Deleting previous uploaded files in the object storage ...."
    sudo aws s3 rm s3://$bucketpath --recursive --profile $aws_credential_profile_name

    # c. upload the latest merge folder files into object storage
    echo "Uploading new merge files into the object storage ...."
    sudo aws s3 cp $merge s3://$bucketpath --recursive --storage-class INTELLIGENT_TIERING --profile $aws_credential_profile_name 

    # e. then delete full folder and mv/rename "merge" folder to "full" folder (as the "new full" for next incremental merge
    if [[ -d $full ]]; then echo "Deleting $full ..." && sudo rm -rf $full; fi
    sudo mv $merge $full
    echo '================================================================================'
    echo "Successfully moved/rename '$merge' to '$full' for for next incremental merge ...."
    echo '==============================================================================='
}

run()
{
    if [[ $initial_full == "true" ]]; then
        initial_full_backup
    fi

    if [[ $initial_full == "false" ]]; then
        echo '-----------------------------------------'
        echo 'Started backup and upload into object storage'
        startdate=`date '+%a %b %e %H:%M:%S %Z %Y'`
        echo "Time is:" "$startdate"
        echo '========================================='
        echo 'Backup in progress.. '
        incremental_backup_and_merge
        echo 'Upload in progress.. '
        upload_merged_backup
        echo '========================================='
        echo 'Finished backup and upload into object storage'
        enddate=`date '+%a %b %e %H:%M:%S %Z %Y'`
        echo "Time is:" "$enddate"
        echo '========================================='
        echo '-----------------------------------------'
    fi

    # set initial full backup to "false" before next incremental backup, to avoid taking initial full backup again
    initial_full="false"
}

every_interval_forever()
{
    while true
        do
            run
            sleep $interval
        done
}

every_interval_at_specified_time()
{
    i=0
    while [ $i -lt $nth ]
        do
            run
            sleep $testTnterval
            i=$(( i + 1 ))
        done
}

main()
{
    if [[ "$forever" == "true" ]]; then
        specified="false"
        day=$((interval/86400))
        echo '==================================================='
        echo "Running job forever every "$interval" seconds (or $day day) "
        echo '==================================================='
        every_interval_forever
    fi

    if [[ "$specified" == "true" ]]; then
        forever="false"
        totaltime=$((nth * $testTnterval))
        echo '==========================================='
        echo "Running Job for "$totaltime" seconds every "$testTnterval" seconds"
        echo '==========================================='
        every_interval_at_specified_time
    fi
}


main
