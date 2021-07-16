az account list-locations -o tsv --query "[].name" | sed 1d | \
while read i
    do
    echo -n $i
    j=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=contains(skuName,'DS3 v2 Spot') AND armRegionName eq '$i' AND productName eq 'Virtual Machines DSv2 Series'" --query 'Items [0].unitPrice' --only-show-errors -o tsv)
    echo -n ","$j
    k=$(az rest --method GET --url "https://prices.azure.com/api/retail/prices?\$filter=skuName eq 'DS3 v2' AND armRegionName eq '$i' AND productName eq 'Virtual Machines DSv2 Series' AND reservationTerm eq null" --query 'Items [0].unitPrice' --only-show-errors -o tsv)
    echo ","$k
    done
