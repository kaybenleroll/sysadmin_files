#!/bin/sh

APAMA_INSTALL_DIR=/opt/apama_4.1
ATA_DIR=/apama/ATA111/Accelerators/AlgorithmicTradingAccelerator

source ${APAMA_INSTALL_DIR}/bin/apama_env

### Stop the ATA
${ATA_DIR}/project.sh stop

