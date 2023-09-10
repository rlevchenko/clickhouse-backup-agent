#-----------------------------------------------------------
# Dockerfile | Clickhouse Backup Agent | rlevchenko.com
# PROVIDED WITHOUT WARRANTY OF ANY KIND
#-----------------------------------------------------------

FROM alpine:3.18.3
LABEL AUTHOR="Roman Levchenko"
LABEL WEBSITE="rlevchenko.com"
LABEL APPLICATION="Clickhouse Backup Scheduled Task"
ARG CLICKHOUSE_BACKUP_VERSION
ENV CLICKHOUSE_BACKUP_VERSION ${CLICKHOUSE_BACKUP_VERSION:-v2.4.0}
COPY ["./config/clickhouse-backup.sh","./config/ch-backup-logrotate.conf","/backup/config/"]
RUN applist=' \
               logrotate \
               bash=5.2.15-r5 \
               curl \
               jq \
    ' \
    set -x \
    && mkdir -p /backup/config /etc/periodic/custom /var/log/clickhouse-backup \ 
    && touch /var/log/cron.log \
    && apk --no-cache add $applist \
    && wget -q -P /backup/config/ \
    "https://github.com/Altinity/clickhouse-backup/releases/download/$CLICKHOUSE_BACKUP_VERSION/clickhouse-backup-linux-amd64.tar.gz" \
    && tar -C /backup/config -xvf /backup/config/clickhouse-backup-linux-amd64.tar.gz \
    && mv /backup/config/build/linux/amd64/clickhouse-backup /usr/bin/ \
    && chmod +x /usr/bin/clickhouse-backup \
    && rm -rf /backup/config/clickhouse-backup-linux-amd64.tar.gz /backup/config/build/ \
    && mkdir /backup/config/logrotate ; \
    mv /backup/config/ch-backup-logrotate.conf /backup/config/logrotate \
    && chmod 0600 /backup/config/logrotate/ch-backup-logrotate.conf \
    && chmod 0700 /backup/config/clickhouse-backup.sh
COPY ./config/cronfile /etc/crontabs/root
CMD ["-f","-l","8", "-L", "/dev/stdout"]
ENTRYPOINT ["crond"]