#!/bin/bash
set -e

scriptfile=/usr/bin/detectev.sh
apt install -y jq
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

cat << "EOF" > $scriptfile
#!/bin/bash
evictionlog=/var/log/evlog.txt
echo Detection eviction running $(date) >> $evictionlog

# collecting instance metadata
meta=$( curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | jq '{ name: .compute.name, rgname: .compute.resourceGroupName, location: .compute.location, privateIP: .network.interface[0].ipv4.ipAddress[0].privateIpAddress, sku: .compute.sku, vmSize: .compute.vmSize }')
i=5
while [ $i -gt 0 ]
do
  event=$(curl -s -H Metadata:true http://169.254.169.254/metadata/scheduledevents?api-version=2019-08-01 )
  if [[ "$event" == *"Preempt"* ]];
  then
    echo "Eviction detected at " $(date) >> $evictionlog 
    
    armLocation=$(eval echo $(echo $meta | jq .location))
    armSkuName=$(eval echo $(echo $meta | jq .vmSize))
    spotVmPrice=$(az rest --method get --url "https://prices.azure.com/api/retail/prices?\$filter=armSkuName eq '$armSkuName' AND armRegionName eq '$armLocation' AND serviceName eq 'Virtual Machines' AND reservationTerm eq null AND contains(productName, 'Windows') eq false AND contains(productName, 'promo') eq false AND contains(meterName, 'Low Priority') eq false AND contains(meterName, 'Spot')" --query 'Items [0].unitPrice' --only-show-errors)
    vmPrice=$(az rest --method get --url "https://prices.azure.com/api/retail/prices?\$filter=armSkuName eq '$armSkuName' AND armRegionName eq '$armLocation' AND serviceName eq 'Virtual Machines' AND reservationTerm eq null AND contains(productName, 'Windows') eq false AND contains(productName, 'promo') eq false AND contains(meterName, 'Low Priority') eq false AND contains(meterName, 'Spot') eq false" --query 'Items [0].unitPrice' --only-show-errors)
    
    meta=$(echo $meta | jq '. + {"vmPrice": '$vmPrice', "spotVmPrice": '$spotVmPrice'}')

    curl -s -X POST -d "${meta}" https://xtopheviction.azurewebsites.net/api/EvictionHandler 
    exit
  fi
  ((i--))
  sleep 10
  echo "No eviction at " $(date) >> $evictionlog
done
EOF

chmod 555 $scriptfile
echo Adding detection to system cron
echo "* * * * * root $scriptfile" >> /etc/crontab

echo verifying system crontab
cat /etc/crontab


