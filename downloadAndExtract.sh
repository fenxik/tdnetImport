#!/bin/bash

# If no argument supplied, then set download date to current date
if [ $# -eq 0 ]; then
	executeDate=`date +"%Y%m%d"`
else
	executeDate=$1
fi

./downloadDailyAnnouncement_404.sh ${executeDate} && ./extractData.sh ${executeDate}