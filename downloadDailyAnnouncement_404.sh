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

# Download daily public announcement by "curl", then extract the name of all zip files attached.
# The zip file always have the pattern that consits of 18 digit characters and the extension ".zip".
downloadedFileCounter=0
pageNo=0
for pageNo in `seq -w 1 999`; do
	# Because we cannot know how much pages are there, so we have to loop from 1 to 999
	# (guest from the pattern of the page URI, I_list_xxx_yyyymmdd.html). And for each page,
	# we have to check whether it exist or not by finding the string "404 Not Found".
	# If page not found then break the loop.
	checker=`curl --silent $baseUri"/"I_list_${pageNo}_${downloadDate}.html | grep -Eo  "404 Not Found"`
	if [ "${checker}" == "404 Not Found" ];	then
		break
	fi

	while read -r line; do
		# Create (or reuse if existed) a new folder with the pattern yyyymmdd inside current directory,
		# then download .zip file and save there (overwrite if existed). 
		wget --quiet  ${baseUri}"/"${line}  -P `pwd`/${downloadDate} -N

		# Count the files amount
		downloadedFileCounter=$[$downloadedFileCounter + 1]

		# Show message after finish download each file
		echo -ne "Downloading: ${downloadedFileCounter} file(s)\r"
	done < <(curl --silent $baseUri"/"I_list_${pageNo}_${downloadDate}.html | grep -Eo  "[0-9]{18}.zip")
done

# Show summary message
if [ $downloadedFileCounter -eq 0 ]; then
	echo "There is no file to download on $downloadDate."
else
	echo "Download finished! ${downloadedFileCounter} file(s)"
fi

exit 0