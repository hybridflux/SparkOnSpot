#!/bin/bash

while getopts s:p:l:r: option 
do 
 case "${option}" 
 in 
 s) skuName=${OPTARG};;
 p) productName=${OPTARG};; 
 l) location=${OPTARG};; 
 r) isLoop=${OPTARG};; 
 esac 
done


if  [ "$skuName" == "" ] ; then
    skuName='DS3 v2'
fi
if  [ "$location" == ""  ] ; then
    location='US East'
fi
if  [ "$productName" == "" ] ; then
    productName='Virtual Machines DSv2 Series'
fi

if  [ "$isLoop" == "" ] ; then
    isLoop=false
fi

echo "Checkin prices for '$skuName' VM's in '$location' location"

while true
do
    vmPrice=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=skuName eq '$skuName' AND location eq '$location' AND serviceName eq 'Virtual Machines' AND reservationTerm eq null AND productName eq '$productName'" --query 'Items [0].unitPrice' --only-show-errors)
    spotVmPrice=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=contains(skuName,'$skuName Spot') AND location eq '$location' AND serviceName eq 'Virtual Machines' AND productName eq '$productName'" --query 'Items [0].unitPrice' --only-show-errors)

    echo "Regular VM price is: $vmPrice"
    echo "Spot VM price is: $spotVmPrice"

    if [ "$isLoop" == false ] ; then
        break
	fi

    if read -n1 -r -p "Do you want to check prices every 60 seconds? [y]es|[n]o" && [[ $REPLY == 'n' ]]; then
		break
	fi

    echo
    echo 'Press Ctrl+C when you no longer need price to be calculated'
    sleep 60

done