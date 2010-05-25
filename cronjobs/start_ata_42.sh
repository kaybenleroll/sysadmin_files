#!/bin/sh

APAMA_INSTALL_DIR=/opt/apama_4.2
ATA_DIR=/apama/ATA116/Accelerators/AlgorithmicTradingAccelerator

source ${APAMA_INSTALL_DIR}/bin/apama_env

cd ${ATA_DIR}
${ATA_DIR}/project.sh start

engine_send -p 25903 ${ATA_DIR}/jsi_extras/jsievents/SubscribeToData.evt