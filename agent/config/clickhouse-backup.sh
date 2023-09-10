#!/bin/bash

#-----------------------------------------------------------
# Bash Script | Clickhouse Backup Agent | rlevchenko.com
# PROVIDED WITHOUT WARRANTY OF ANY KIND
#-----------------------------------------------------------

# if you need debug, enable this:
# set -x
# trap read debug

FUNCTION_NAME=$1
SERVER_ADDRESS=$2
API_USERNAME=$3
API_PASSWORD=$4
FULL_BACKUP_NAME=FULL_CH_BK_$(date +%Y-%m-%d_%H-%M-%S)
DIFF_BACKUP_NAME=DIFF_CH_BK_$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_LOG="/var/log/clickhouse-backup/${SERVER_ADDRESS}_backup_ch.log"
LAST_BACKUP_NAME="/var/log/clickhouse-backup/.${SERVER_ADDRESS}_last_backup"

# Let's beautify
function setcolors {
                OFF="\e[0m"
        BOLD="\033[1m"
        GREEN="${BOLD}\e[92m"
        YELLOW="${BOLD}\e[33m"
        RED="${BOLD}\e[91m"
}
function check_backup_req {
    # Create Backup FULL/DIFF request
    if [ "$FUNCTION_NAME" == "create_full_backup" ]; then
        backup_req=$(curl -s -u "$API_USERNAME:$API_PASSWORD" http://"${SERVER_ADDRESS}":7171/backup/status | \
                   jq ". | select( .command == \"create ${FULL_BACKUP_NAME}\" )")
        printf '%s\n' "$backup_req"
    elif [ "$FUNCTION_NAME" == "create_diff_backup" ]; then
        backup_req=$(curl -s -u "$API_USERNAME:$API_PASSWORD" http://"${SERVER_ADDRESS}":7171/backup/status | \
                   jq ". | select( .command == \"create ${DIFF_BACKUP_NAME}\" )")
        printf '%s\n' "$backup_req"
    else
       echo -e "${RED}::::[ERROR]${OFF} ${BOLD} Check out the FUNCTION NAME and retry! ${OFF}"
    fi
}
function check_backup_status {

    # Catch In Progress status
    while [ "$(check_backup_req | jq -r .status )" == "in progress" ]; do
        echo -e "\n${GREEN}[INFO]${OFF} ${BOLD} Backup of the ${BACKUP_NAME} is still in progress...${OFF}"
        sleep 10
    done

    # Catch Error status
    if [ "$(check_backup_req | jq -r .status )" == "error" ]; then
        echo -e "${RED}::::[ERROR]${OFF} ${BOLD} Couldn't create the backup ${BACKUP_NAME}:${OFF}"
        {
        printf '\n%s\n' "CREATE BACKUP ERROR:"
        check_backup_req | jq -r .error
        printf '%s\n' "-------------"
        } | tee -a "$BACKUP_LOG"

    # Catch Success status
    elif [ "$(check_backup_req | jq -r .status)" == "success" ]; then
        echo -e "\n${GREEN}[INFO]${OFF} ${BOLD} The ${BACKUP_NAME} has just been created ${OFF}"
        if [ "$BACKUP_NAME" == "$FULL_BACKUP_NAME" ]; then
            curl -u "$API_USERNAME:$API_PASSWORD" -s -X POST \
            http://"${SERVER_ADDRESS}":7171/backup/upload/"${BACKUP_NAME}" | jq . >> "$BACKUP_LOG"
        else
            curl -u "$API_USERNAME:$API_PASSWORD" -s -X POST \
            http://"${SERVER_ADDRESS}":7171/backup/upload/"${DIFF_BACKUP_NAME}"?diff-from="${OLD_BACKUP_NAME}" | jq .  >> "$BACKUP_LOG"
        fi # child if
    fi # parent if
}

function check_upload_req {

    # FULL
    if [ "$FUNCTION_NAME" == "create_full_backup" ]; then
        upload_req=$(curl -s -u "$API_USERNAME:$API_PASSWORD" http://"${SERVER_ADDRESS}":7171/backup/actions | \
                   jq ". | select( .command == \"upload ${FULL_BACKUP_NAME}\" )")
        printf '%s\n' "$upload_req"

    # DIFF
    elif [ "$FUNCTION_NAME" == "create_diff_backup" ]; then
        upload_req=$(curl -s -u "$API_USERNAME:$API_PASSWORD" http://"${SERVER_ADDRESS}":7171/backup/actions | \
                   jq --arg DIFF "$DIFF_BACKUP_NAME" --arg OLD "$OLD_BACKUP_NAME" \
                   '. | select( .command | startswith("upload") and endswith($DIFF) and contains($OLD) )')
        printf '%s\n' "$upload_req"
    else
       echo -e "${RED}::::[ERROR]${OFF} ${BOLD} Check out the FUNCTION NAME and retry! ${OFF}" y
    fi

}

function check_upload_status {

        # Catch In Progress status
        while [ "$(check_upload_req | jq -r .status )" == "in progress" ]; do
            echo -e "\n${GREEN}[INFO]${OFF} ${BOLD} Upload of the ${BACKUP_NAME} is still in progress...${OFF}"
            sleep 1m
        done

        # Catch Error status
        if [ "$(check_upload_req | jq -r .status )" == "error" ]; then
            echo -e "${RED}::::[ERROR]${OFF} ${BOLD} Couldn't upload the backup ${BACKUP_NAME}:${OFF}"
            {
            printf '\n%s\n' "UPLOAD ERROR:"
            check_upload_req | jq -r .error
            printf '%s\n' "-------------"
            } | tee -a "$BACKUP_LOG"
            return 1

        # Catch Success status
        elif [ "$(check_upload_req | jq -r .status)" == "success" ]; then
            echo -e "\n${GREEN}[INFO]${OFF} ${BOLD} The ${BACKUP_NAME} is now the last since it's just been uploaded successfully${OFF}"
            touch "${LAST_BACKUP_NAME}"
            echo -n "${BACKUP_NAME}" > "${LAST_BACKUP_NAME}"
        fi
}

function create_full_backup {

    # CREATE
    curl -u "$API_USERNAME:$API_PASSWORD" -s -X POST \
          http://"${SERVER_ADDRESS}":7171/backup/create?name="${FULL_BACKUP_NAME}" | jq . >> "$BACKUP_LOG"
    BACKUP_NAME="${FULL_BACKUP_NAME}"
    check_backup_status

    # UPLOAD
    check_upload_status
}

function create_diff_backup {

    # If no OLD BACKUP, let's do this check
    if [ -f "$LAST_BACKUP_NAME" ]; then
       OLD_BACKUP_NAME=$(cat "${LAST_BACKUP_NAME}")
    else
       echo -e "\n${YELLOW}[WARNING]${OFF} ${BOLD} No OLD backups? It's recommended to create FULL backup first ${OFF}"
    fi

    # CREATE DIFF
    OLD_BACKUP_NAME=$(cat "${LAST_BACKUP_NAME}" 2> /dev/null) # suspress the 1st error if no OLD backup available
    BACKUP_NAME="${DIFF_BACKUP_NAME}"
    curl -u "$API_USERNAME:$API_PASSWORD" -s -X POST \
          http://"${SERVER_ADDRESS}":7171/backup/create?name="${DIFF_BACKUP_NAME}" | jq . >> "$BACKUP_LOG"
    check_backup_status

    # UPLOAD
    check_upload_status
}
printf '\n%s\n' "##### started at $(date +%Y-%m-%d_%H-%M-%S) #####"  | tee -a "${BACKUP_LOG}"
setcolors
${FUNCTION_NAME}
printf '\n%s\n' "##### finished at $(date +%Y-%m-%d_%H-%M-%S) #####" | tee -a "${BACKUP_LOG}"