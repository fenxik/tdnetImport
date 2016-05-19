#!/bin/bash
# You can call the script with the date that you would like to download public annoucement.
# The date must be in the format YYYYmmdd. If wrong, you may not receive result or wrong result.
# Usage:
#    1. Call script with a specified date:
#        $ ./downloadDailyAnnouncement.sh YYYYmmdd
#    2. Call script without a date (in this case, it will get data for current date):
#        # ./downloadDailyAnnouncement.sh

# The URI that contain zip files
baseUri=https://www.release.tdnet.info/inbs

# If no argument supplied, then set download date to current date
if [ $# -eq 0 ]; then
	downloadDate=`date +"%Y%m%d"`
else
	downloadDate=$1
fi

# Read number of items in one page, and total number of item from the first paging page
itemPerPage=`curl --silent $baseUri"/"I_list_001_${downloadDate}.html | grep -Eo  "[0-9]*件&nbsp;/&nbsp" | head -1 | grep -Eo "[0-9]*"`
itemNo=`curl --silent $baseUri"/"I_list_001_${downloadDate}.html | grep -Eo  "[0-9]*件</div>" | head -1 | grep -Eo "[0-9]*"`

# If cannot get one of itemNo or itemPerPage, it means that there is no result. Exit.
if [ "$itemPerPage" == "" -a  "$itemNo" == "" ]; then
	echo "There is no file to download on $downloadDate."
	exit 0
fi

# Calculate number of page
pageNo=`expr $itemNo / $itemPerPage`
if [ `expr $itemNo % $itemPerPage` -ne 0 ]; then
	pageNo=$((pageNo + 1))
fi

# Loop throw each page and download daily public announcement by "curl", then extract the name of all zip files attached.
# The zip file always have the pattern that consits of 18 digit characters and the extension ".zip".
downloadedFileCounter=0
for i in `seq -f "%03g" 1 $pageNo`; do
	while read -r line; do
		# Create (or reuse if existed) a new folder with the pattern yyyymmdd inside current directory,
		# then download .zip file and save there (overwrite if existed). 
		wget --quiet  ${baseUri}"/"${line} -P `pwd`/${downloadDate} -N

		# Count the files amount
		downloadedFileCounter=$[$downloadedFileCounter + 1]

		# Show message after finish download each file
		echo -ne "Downloading: ${downloadedFileCounter} file(s)\r"
	done < <(curl --silent $baseUri"/"I_list_${i}_${downloadDate}.html | grep -Eo  "[0-9]{18}.zip")
done

# Show summary message
if [ $downloadedFileCounter -eq 0 ]; then
	echo "There is no file to download on $downloadDate."
else
	echo "Download finished! ${downloadedFileCounter} file(s)"
fi

exit 0