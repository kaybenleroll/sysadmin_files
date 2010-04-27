#!/bin/sh

APAMA_INSTALL_DIR=/opt/apama_4.1
APAMA_WORK=/apama/apama-work
ATA_DIR=/apama/ATA111/Accelerators/AlgorithmicTradingAccelerator
UTILS_DIR=/apama/sysadmin/utilities

ES_DATA_DIR=/apama/filestorage/eventstore_dumps

source ${APAMA_DIR}/bin/apama_env

### Stop the ATA
${ATA_DIR}/project.sh stop

