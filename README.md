[![Build docker agent image](https://github.com/rlevchenko/clickhouse-backup-agent/actions/workflows/docker-image.yml/badge.svg)](https://github.com/rlevchenko/clickhouse-backup-agent/actions/workflows/docker-image.yml)
[![Check My Blog](https://img.shields.io/badge/check-blog-post)](https://rlevchenko.com/2023/09/12/simple-clickhouse-backup-agent/)
[![LinkedIn](https://img.shields.io/twitter/follow/rlevchenko)](https://twitter.com/rlevchenko)

# Simple Clickhouse backup agent

## Description

Dockerized cron job to backup ClickHouse databases on single host or cluster with shards and replicas. Based on Alpine docker image, [clickhouse-backup tool](https://github.com/Altinity/clickhouse-backup) along with it's ability to work as a REST API service. Logrotate has been added to manage the log files produced by the backup agent. If any issues/suggestions, use the issues tab or create a new PR.
FYI: If you're seeking to PostgreSQL backup agent, it can be accessed [here](https://github.com/rlevchenko/psql-backup-agent).

The agent does the following:

- creates scheduled FULL or DIFF backups (POST  to _/backup/create_)
- checks "create backup" action status before every upload (GET to _/backup/status_)
- uploads each backup to a remote storage  (POST to _/backup/upload/_)
- checks and waits until upload operation finishes (GET to _/backup/actions_)
- manages log file with API responses and errors
- generates customized output to standard container logs
- if a backup is not uploaded to remote storage, it's marked as failed
  and will not be used as the last backup for subsequent DIFF backups

***Important:*** according to the [clickhouse-backup official FAQ](https://github.com/Altinity/clickhouse-backup/blob/master/Examples.md#how-do-incremental-backups-work-to-remote-storage), "incremental backup calculate increment only during execute upload or create_remote command or similar REST API request". In other words, DIFF and FULL local backups are actually the same (_clickhouse-backup list local_) Clickhouse-backup creates local backups first before uploading them to remote storage.

If you list remote backups using the command (_clickhouse-backup list remote_), you will notice the distinction between these two backup types. This is why the agent only issues a warning when you attempt to create a DIFF backup for the first time without having any prior FULL backups.

Default settings:

- *DIFF backups*: every hour from Monday through Friday and Sunday,
  plus every hour from 0 through 20 on Saturday
- *FULL backups*: every Saturday at 8.30 PM
- *Rotate and compess* logs weekly, rotated 14 times before being removed
- Clickhouse-backup *API basic authentication* is enabled (rlAPIuser)
- Clickhouse server authentication is enabled (rlbackup)
- *Remote storage* is ftp with authentication enabled
- Backups to *keep local*: 6
- Backups to *keep remote*: 336

## Content

- _docker-compose.yml_ - describes environment to test the agent locally
   There are the following services:
  - clickhouse server (clickhouse-server:23.8-alpine)
  - clickhouse-backup (altinity/clickhouse-backup:2.4.0)
  - our clickhouse-backup-agent (ch-backup-agent)
  - ftpd_server (stilliard/pure-ftpd)
- _./clickhouse/clickhouse-backup-config.yml_ - clickhouse-backup config file
- _./agent/Dockerfile_ - backup agent's docker image
- _./agent/ch-backup-logrotate.conf_ - logrotate config file
- _./agent/clickhouse-backup.sh_ - script to define backup and upload steps
- _./agent/cronfile_ - cron job backup and logrotate tasks
- _./github/workflows/docker-image.yml_ - simple GitHub action to build agent's docker image on every Dockerfile change

## Possible use cases

- as a resource for learning docker, docker compose, bash, cron and logrotate
- as a source of the script, cron job task or docker files. just grab them and you're set
- as a sample of pairing clickhouse-backup and clickhouse server

## How to use

- check out _logrotate_ and _cron_ settings in the _agent_ folder
- verify the _Dockerfile_ in the _agent_ folder (if docker is being used)
- adjust clickhouse backup settings if necessary (_./clickhouse/clickhouse-backup-config.yml_)
  Change credentials, clickhouse host and remote storage at least
- clickhouse-backup API container or standalone service shoud have access to _/var/clickhouse/_ folders to create backup successfully. In case of a container, see _docker-compose.yml_. If your clickhouse-backup API is a Linux service, run the service on the first replica for each shard, and then update cronfile accordingly
- copy cron and script files to a remote host, and then make a test run
- in the case of using Docker, please check the 'docker-compose.yml' file and remove any unnecessary services (such as clickhouse and ftp). Afterward, run _docker-compose up -d --build_ to get containers started
- use _docker logs <container id>_ or _docker compose <service name>_ to check service logs
  Log files are also located under the _/var/log/clickhouse-backup/_ folder

More info and tricks at the [blog post](https://rlevchenko.com/2023/09/12/simple-clickhouse-backup-agent/)

## Result

Output with error, warning and info messages:

![Agent Output](https://rlevchenko.files.wordpress.com/2023/09/first-run-w-error.jpg)

Log file:

![Log file](https://rlevchenko.files.wordpress.com/2023/09/log-file.jpg)