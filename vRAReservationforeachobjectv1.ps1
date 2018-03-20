$filePath = import-csv c:\draft\test.csv

$filePath | ForEach-Object {

$ComputeResource = Get-vRAReservationComputeResource -Type $_.thePlatformType -Name $_.theComputeResource

$NetworkDefinitionArray = @() 
$Network1 = New-vRAReservationNetworkDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -NetworkPath $_.theNetworkPath -NetworkProfile $_.theNetworkProfile
$NetworkDefinitionArray += $Network1

$StorageDefinitionArray = @() 
$Storage1 = New-vRAReservationStorageDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -Path $_.theDataStorePath -ReservedSizeGB 10 -Priority 0
$StorageDefinitionArray += $Storage1

$resType = $_.thePlatformType
$resName = $_.theName
$resBG = $_.theBusinessGroup
$resCompute = $ComputeResource.Id
$resNetwork = $NetworkDefinitionArray
$resStorage = $StorageDefinitionArray
$resMEM = '2048'

New-vRAReservation -Type $resType -Name $resName -BusinessGroup $resBG -ComputeResourceId $resCompute -MemoryGB $resMEM -Storage $resStorage -Network $resNetwork -Confirm:$false
}