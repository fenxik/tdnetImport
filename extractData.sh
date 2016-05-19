#!/bin/bash
# You can call the script with the date that you would like to extract data.
# The date must be in the format YYYYmmdd. If wrong, you may not receive result or wrong result.
# Usage:
#    1. Call script with a specified date:
#        $ ./extractData.sh YYYYmmdd
#    2. Call script without a date (in this case, it will get data for current date):
#        # ./extractData.sh
# Prerequirement: You have to install unzip tool.

# If no argument supplied, then set extract date to current date
if [ $# -eq 0 ]; then
	extractDate=`date +"%Y%m%d"`
else
	extractDate=$1
fi

# Extract all .zip files in the folder of input date (extractDate) to folder extractTmp
mkdir -p `pwd`/${extractDate}/extractTmp/
inflateCount=0
zipFiles=($(find `pwd`/${extractDate}/ -type f -name "*.zip"))
for zipFile in ${zipFiles[@]}; do
	unzip -qo $zipFile -d `pwd`/${extractDate}/extractTmp/
	inflateCount=$[$inflateCount + 1]
	echo -ne "Inflating: ${inflateCount} file(s)\r"
done
if [ ${inflateCount} -eq 0 ]; then
	echo "There is no file to extract on ${extractDate}."
	rm -rf `pwd`/${extractDate}/
	exit 0
fi
echo "Inflate finished! ${inflateCount} file(s)"

# Move all extracted .htm files into one folder named htmTmp
mkdir -p `pwd`/${extractDate}/htmTmp/
find `pwd`/${extractDate}/extractTmp/ -type f -name '*.htm' -exec mv -i -f {} `pwd`/${extractDate}/htmTmp/  \;

# Delete folder extractTmp and all its contents (now it does not contains any .htm file).
# From now, we only work on htmTmp folder.
rm -rf `pwd`/${extractDate}/extractTmp/

# Function to determine the index of one string in another. Usage: strindex "baseString" "findString"
strindex() { 
	x="${1%%$2*}"
	[[ $x = $1 ]] && echo -1 || echo ${#x}
}

# Function to extract value from <ix:nonNumeric> tag with specific name from specified htm file. Usage: extractNonNumeric "htmlFile" "tagName"
extractNonNumeric() {
	matchText=`grep -o "<ix:nonNumeric[^<]*name=\"${2}\"[^<]*</ix:nonNumeric>" ${1}`
	if [ "$matchText" == "" ]; then
		echo ""
		exit 0
	fi
	firstIndex=$(strindex "$matchText" ">")
	lastIndex=$(strindex "$matchText" "</")
	echo "${matchText:firstIndex+1:lastIndex-(firstIndex+1)}"
}

# Function to extract value from <ix:nonFraction> tag with specific name from specified htm file. Usage: extractNonNumeric "htmlFile" "tagName"
extractNonFraction() {
	matchText=`grep -o "<ix:nonFraction[^<]*name=\"${2}\"[^<]*</ix:nonFraction>" ${1}`
	if [ "$matchText" == "" ]; then
		echo ""
		exit 0
	fi
	firstIndex=$(strindex "$matchText" ">")
	lastIndex=$(strindex "$matchText" "</")
	value=${matchText:firstIndex+1:lastIndex-(firstIndex+1)}

	# Check whether the value contain sign="-"
	signIndex=$(strindex "$matchText" "sign=\"-\"")
	if [ $signIndex -eq 0 ]; then
		echo "${value}"
	else
		echo "-${value}"
	fi
}

# Write header to .csv file
headerLine="HAPPYO_DATE,MEIGARA_CD,CurrentFiscalYearStartDateDEI,"
headerLine=$headerLine"CurrentPeriodEndDateDEI,CurrentAssets,PropertyPlantAndEquipment,"
headerLine=$headerLine"IntangibleAssets,InvestmentsAndOtherAssets,NoncurrentAssets,Assets,"
headerLine=$headerLine"CurrentLiabilities,NoncurrentLiabilities,Liabilities,ShareholdersEquity,"
headerLine=$headerLine"ValuationAndTranslationAdjustments,NetAssets,LiabilitiesAndNetAssets,"
headerLine=$headerLine"NetAssets,LiabilitiesAndNetAssets,NetSales,OperatingIncome,GrossProfit,"
headerLine=$headerLine"SellingGeneralAndAdministrativeExpenses,NonOperatingIncome,"
headerLine=$headerLine"NonOperatingExpenses,OrdinaryIncome,ExtraordinaryIncome,"
headerLine=$headerLine"IncomeBeforeIncomeTaxes,IncomeTaxesCurrent,IncomeTaxesDeferred,"
headerLine=$headerLine"IncomeTaxes,NetIncome,NetCashProvidedByUsedInOperatingActivities,"
headerLine=$headerLine"NetCashProvidedByUsedInInvestmentActivities,"
headerLine=$headerLine"NetCashProvidedByUsedInFinancingActivities,CashDividendsPaidFinCF"
echo "$headerLine" > `pwd`/${extractDate}.csv

# Lookup in each .htm file and extract informations for writing to csv file.
successFileCounter=0
nondataFileCounter=0
htmFiles=$(find `pwd`/${extractDate}/htmTmp/ -type f -name "*.htm")
for htmFile in ${htmFiles[@]}; do
	securityCodeDEI=$(extractNonNumeric ${htmFile} "jpdei_cor:SecurityCodeDEI")
	currentFiscalYearStartDateDEI=$(extractNonNumeric ${htmFile} "jpdei_cor:CurrentFiscalYearStartDateDEI")
	currentPeriodEndDateDEI=$(extractNonNumeric ${htmFile} "jpdei_cor:CurrentPeriodEndDateDEI")
	currentFiscalYearStartDateDEI=$(extractNonNumeric ${htmFile} "jpdei_cor:CurrentFiscalYearStartDateDEI")
	currentPeriodEndDateDEI=$(extractNonNumeric ${htmFile} "jpdei_cor:CurrentPeriodEndDateDEI")
	currentAssets=$(extractNonFraction ${htmFile} "jppfs_cor:CurrentAssets")
	propertyPlantAndEquipment=$(extractNonFraction ${htmFile} "jppfs_cor:PropertyPlantAndEquipment")
	intangibleAssets=$(extractNonFraction ${htmFile} "jppfs_cor:IntangibleAssets")
	investmentsAndOtherAssets=$(extractNonFraction ${htmFile} "jppfs_cor:InvestmentsAndOtherAssets")
	noncurrentAssets=$(extractNonFraction ${htmFile} "jppfs_cor:NoncurrentAssets")
	assets=$(extractNonFraction ${htmFile} "jppfs_cor:Assets")
	currentLiabilities=$(extractNonFraction ${htmFile} "jppfs_cor:CurrentLiabilities")
	noncurrentLiabilities=$(extractNonFraction ${htmFile} "jppfs_cor:NoncurrentLiabilities")
	liabilities=$(extractNonFraction ${htmFile} "jppfs_cor:Liabilities")
	shareholdersEquity=$(extractNonFraction ${htmFile} "jppfs_cor:ShareholdersEquity")
	valuationAndTranslationAdjustments=$(extractNonFraction ${htmFile} "jppfs_cor:ValuationAndTranslationAdjustments")
	netAssets=$(extractNonFraction ${htmFile} "jppfs_cor:NetAssets")
	liabilitiesAndNetAssets=$(extractNonFraction ${htmFile} "jppfs_cor:LiabilitiesAndNetAssets")
	#########################################################################################
	netSales=$(extractNonFraction ${htmFile} "jppfs_cor:NetSales")
	operatingIncome=$(extractNonFraction ${htmFile} "jppfs_cor:OperatingIncome")
	grossProfit=$(extractNonFraction ${htmFile} "jppfs_cor:GrossProfit")
	sellingGeneralAndAdministrativeExpenses=$(extractNonFraction ${htmFile} "jppfs_cor:SellingGeneralAndAdministrativeExpenses")
	operatingIncome=$(extractNonFraction ${htmFile} "jppfs_cor:OperatingIncome")
	nonOperatingIncome=$(extractNonFraction ${htmFile} "jppfs_cor:NonOperatingIncome")
	nonOperatingExpenses=$(extractNonFraction ${htmFile} "jppfs_cor:NonOperatingExpenses")
	ordinaryIncome=$(extractNonFraction ${htmFile} "jppfs_cor:OrdinaryIncome")
	extraordinaryIncome=$(extractNonFraction ${htmFile} "jppfs_cor:ExtraordinaryIncome")
	incomeBeforeIncomeTaxes=$(extractNonFraction ${htmFile} "jppfs_cor:IncomeBeforeIncomeTaxes")
	incomeTaxesCurrent=$(extractNonFraction ${htmFile} "jppfs_cor:IncomeTaxesCurrent")
	incomeTaxesDeferred=$(extractNonFraction ${htmFile} "jppfs_cor:IncomeTaxesDeferred")
	incomeTaxes=$(extractNonFraction ${htmFile} "jppfs_cor:IncomeTaxes")
	netIncome=$(extractNonFraction ${htmFile} "jppfs_cor:NetIncome")
	#########################################################################################
	netCashProvidedByUsedInOperatingActivities=$(extractNonFraction ${htmFile} "jppfs_cor:NetCashProvidedByUsedInOperatingActivities")
	netCashProvidedByUsedInInvestmentActivities=$(extractNonFraction ${htmFile} "jppfs_cor:NetCashProvidedByUsedInInvestmentActivities")
	netCashProvidedByUsedInFinancingActivities=$(extractNonFraction ${htmFile} "jppfs_cor:NetCashProvidedByUsedInFinancingActivities")
	cashDividendsPaidFinCF=$(extractNonFraction ${htmFile} "jppfs_cor:CashDividendsPaidFinCF")

	line=\"${securityCodeDEI}\",\"${currentFiscalYearStartDateDEI}\",
	line=${line}\"${currentPeriodEndDateDEI}\",\"${currentAssets}\",\"${propertyPlantAndEquipment}\",
	line=${line}\"${intangibleAssets}\",\"${investmentsAndOtherAssets}\",\"${noncurrentAssets}\",\"${assets}\",
	line=${line}\"${currentLiabilities}\",\"${noncurrentLiabilities}\",\"${liabilities}\",\"${shareholdersEquity}\",
	line=${line}\"${valuationAndTranslationAdjustments}\",\"${netAssets}\",\"${liabilitiesAndNetAssets}\",
	line=${line}\"${netAssets}\",\"${liabilitiesAndNetAssets}\",\"${netSales}\",\"${operatingIncome}\",\"${grossProfit}\",
	line=${line}\"${sellingGeneralAndAdministrativeExpenses}\",\"${nonOperatingIncome}\",
	line=${line}\"${nonOperatingExpenses}\",\"${ordinaryIncome}\",\"${extraordinaryIncome}\",
	line=${line}\"${incomeBeforeIncomeTaxes}\",\"${incomeTaxesCurrent}\",\"${incomeTaxesDeferred}\",
	line=${line}\"${incomeTaxes}\",\"${NetIncome}\",\"${netCashProvidedByUsedInOperatingActivities}\",
	line=${line}\"${netCashProvidedByUsedInInvestmentActivities}\",
	line=${line}\"${netCashProvidedByUsedInFinancingActivities}\",\"${cashDividendsPaidFinCF}\"

	# Only append lines that contain data, avoid empty lines
	if [ "$line" == "\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"" ]; then
		# Count non-data files amount
		nondataFileCounter=$[$nondataFileCounter + 1]
	else
		line=\"${extractDate}\",${line}
		echo "$line" >> `pwd`/${extractDate}.csv
		# Count the files amount
		successFileCounter=$[$successFileCounter + 1]
	fi
	echo -ne "Extracting data: $[${successFileCounter} + ${nondataFileCounter}] file(s)\r"
done

# Delete folder htmTmp and all its contents
rm -rf `pwd`/${extractDate}/htmTmp/

# Show summary message
# Show summary message
if [ $[${successFileCounter} + ${nondataFileCounter}] -eq 0 ]; then
	echo "There is no file to extract on $downloadDate."
else
	echo "Extract data finished! $[${successFileCounter} + ${nondataFileCounter}] .htm file(s)"
	echo "(${successFileCounter} files contain data, ${nondataFileCounter} files do not contain data.)"
fi
echo "Output file: `pwd`/${extractDate}.csv"

exit 0