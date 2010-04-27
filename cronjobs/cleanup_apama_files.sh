#!/bin/sh

### Create a daily timestamp
TSTAMP=`date +%Y%m%d`


### Export the EventStore data
${UTILS_DIR}/export_es_data.pl

### Archive the EventStore data
cd ${ES_DATA_DIR}
tar cvfp

### Archive the logfiles


### Copy the files to the JSI server
