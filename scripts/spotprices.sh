az account list-locations -o table --query "[].name" | sed 1d | \
while read i
    do
    echo $i'\c'
    j=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=contains(skuName,'DS3 v2 Spot') AND armRegionName eq '$i' AND productName eq 'Virtual Machines DSv2 Series'" --query 'Items [0].unitPrice' --only-show-errors)
    echo ","$j'\c'
    k=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=skuName eq 'DS3 v2' AND armRegionName eq '$i' AND productName eq 'Virtual Machines DSv2 Series' AND reservationTerm eq null" --query 'Items [0].unitPrice' --only-show-errors)
    echo ","$k
    done
