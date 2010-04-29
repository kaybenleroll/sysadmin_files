#!/bin/sh

APAMA41_WORK_DIR=/apama/apama-work
APAMA42_WORK_DIR=/apama/apama-work-42

PBZIP_DIR=/usr/local/bin
UTILS_DIR=/apama/sysadmin/utilities
FILE_STORE=/apama/filestorage
ES_DATA_DIR=${FILE_STORE}/eventstore_dumps
LOG_STORE_DIR=${FILE_STORE}/logfiles


### Create a daily timestamp
TSTAMP=`date +%Y%m%d`


### Export the EventStore data
${UTILS_DIR}/export_es_data.pl

### Archive the EventStore data
cd ${ES_DATA_DIR}

tar cvfp dump_${TSTAMP}.tar.bz2 --use-compress-program ${PBZIP_DIR}/pbzip2 *.sim
rm -fv *.sim


### Archive the logfiles
cd ${APAMA41_WORK_DIR}/logs

tar cvfp ${LOG_STORE_DIR}/apamalogs_${TSTAMP}.tar.bz2 --use-compress-program ${PBZIP_DIR}/pbzip2 .

mv ${APAMA41_WORK_DIR}/logs /apama/tmp/logs.${TSTAMP}
mkdir ${APAMA41_WORK_DIR}/logs


cd ${APAMA42_WORK_DIR}/logs

tar cvfp ${LOG_STORE_DIR}/apama42logs_${TSTAMP}.tar.bz2 --use-compress-program ${PBZIP_DIR}/pbzip2 .

mv ${APAMA42_WORK_DIR}/logs /apama/tmp/logs42.${TSTAMP}
mkdir ${APAMA42_WORK_DIR}/logs


### Copy the files to the JSI server
rsync -acvz --progress -e 'ssh -i .ssh/id_dsa_transferuser_jcstny01' /apama/filestorage/ transferuser@secure.jacobsecurities.com:/var/jsi/storage/apama/
