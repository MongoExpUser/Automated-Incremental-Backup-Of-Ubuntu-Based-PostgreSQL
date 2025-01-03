## Automated Incremental Backup of Ubuntu-Based PostgreSQL

### Purpose: PostgreSQL Incremental Backup                                                                                        
- The recently released PostgreSQL 17 (Sept-26-2024) has incremental backup feature like Oracle, SQL Server and MySQL. 
- See the realease note here: https://www.postgresql.org/docs/current/release-17.html
- This repo contains scripts that can be used for automating the feature.
##

### Repository Summary
This repository contains the bash scripts and configuration file that can be used to set up automated incremental backup of Ubuntu-Based PostgreSQL as follows:
- Install and configure PostgreSQL 17 server for incremental backup.
- Set up incremental backup on Ubuntu OS at set interval.
- Set up upload of backup to object storage at set interval.

### Implementation Architectural Diagram
![Image description](https://github.com/MongoExpUser/Automated-Incremental-Backup-Of-Ubuntu-Based-PostgreSQL/blob/main/psql-incremental-backup-arch-diagram.png)
Figure 1: Architectural Diagram of PostgreSQL Incremental Backup and Upload to Object Storage.
##

### Sample Upload
![Image description](https://github.com/MongoExpUser/Automated-Incremental-Backup-Of-Ubuntu-Based-PostgreSQL/blob/main/psql-incremental-sample-s3-upload.png)
Figure 2: Sample Object Storage (S3 Bucket) Upload
##


### Tools
The following tools are used:
-  Bash 5.2
- AWS-CLI 2.18.5
- AWS S3 bucket as object storage
- PostgreSQL 17
- Ubuntu 24.04 LTS operating system
##


### Steps to Deploy
The Steps involved in using the bash scripts and the configuration file are as follows:
- Step-1: Install PostgreSQL and Modify Configuration Files
	- Use the script named  <strong> install-config-psql.sh </strong> in the repository for this step, with the following command:
   	  sudo bash install-psql.sh 

- Step-2: Set up Automated Backups
	- Use the script named <strong> auto-incremental-backup.sh </strong> in the repository for this step, with the following commands, on a screen that runs in the background:
	  - if [[ -f tasks.log ]]; then  echo 'Deleting message log file...'; sudo rm tasks.log; fi                                              
	  - sudo echo '#.. ' > tasks.log && sudo chmod 777 tasks.log                                                                             
	  - sudo chmod u+x auto-incremental-backup.sh && sudo bash auto-incremental-backup.sh >> tasks.log 2>&1
   -  Note: The script takes the initial full backup, and takes incremental backup, merging backups and uploading merged backups to object storage at set interval
         
- Step-3: Check Status
  	- Inspect the tasks.log file for status with the tail command as follows:
  	  - sudo tail -n 500 -f tasks.log 
    

##
  


# License

Copyright © 2024. MongoExpUser

Licensed under the Apache License 2.0
