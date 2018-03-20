# VMware vRealize Automation API sample in PowerSHell
#
# Submits a catalog item request via the vRA API
# 
# For vRO 7.0+


#set global variables
$baseUrl = 'https://ehcauto.ngdcatc.local'
$vrauser = 'tejadaj'
$vrapass = 'WWTwwt1!'
$tenant = 'EHC'
$catalogItemName = 'HVD 7'

#connect to AppHost
$url = "$baseUrl/identity/api/tokens"
$req = [System.Net.WebRequest]::Create($url) 
$req.Method ="POST"
$req.Contenttype = "application/json"
$Body = [byte[]][char[]] '{"username":"$vrauser","password":"$vrapass","tenant":"$tenant"}';
$Stream = $req.GetRequestStream();
$Stream.Write($Body, 0, $Body.Length);
$Stream.Flush();
$Stream.Close();
$response = $req.GetResponse();
$reader = new-object System.IO.StreamReader($response.GetResponseStream())
$stuff = $reader.ReadToEnd() 
$obJson = $stuff | ConvertFrom-Json
$jID = $obJson.id
$jExpires = $obJson.expires

#get catalog item by name
$url = "$baseUrl/catalog-service/api/consumer/entitledCatalogItemViews?`$filter=name+eq+'$catalogItemName'"
$req = [System.Net.WebRequest]::Create($url) 
$req.Method ="GET"
$req.Headers.Add('Authorization','Bearer ' + $jID)
$response = $req.GetResponse();
$reader = new-object System.IO.StreamReader($response.GetResponseStream())
$stuff = $reader.ReadToEnd()
$obJson = $stuff | ConvertFrom-Json
$arrContent = $obJson.content | select catalogItemId, name, description | Where-Object {$_.name -eq $catalogItemName}
$CatalogItemId = $arrContent.catalogItemId

# get catalog item template
$url = "$baseUrl/catalog-service/api/consumer/entitledCatalogItems/$CatalogItemId/requests/template"
$R=Invoke-WebRequest $url -Headers $headers

# modify the template as needed for the request
$Form = $R.Content | ConvertFrom-Json
$Form.data.vSphere_Machine_1.data.cpu = 8
$Form.data.vSphere_Machine_1.data.memory = 8192

#submit request 
$url = "$baseUrl/catalog-service/api/consumer/entitledCatalogItems/$CatalogItemId/requests"
$cjson = $Form  | ConvertTo-Json -Depth 10
$K=Invoke-WebRequest $url -Headers $headers -Method POST -Body $cjson -ContentType "application/json" 
if ($K.StatusCode -eq 201) {write-host "successful"}