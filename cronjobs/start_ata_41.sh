#!/bin/sh

APAMA_INSTALL_DIR=/opt/apama_4.1
ATA_DIR=/apama/ATA111/Accelerators/AlgorithmicTradingAccelerator

source ${APAMA_INSTALL_DIR}/bin/apama_env

cd ${ATA_DIR}
${ATA_DIR}/project.sh start

engine_send ${ATA_DIR}/src/jcsevents/SubscribeToData.evt
engine_send ${ATA_DIR}/adapters/events/start_capture.evt