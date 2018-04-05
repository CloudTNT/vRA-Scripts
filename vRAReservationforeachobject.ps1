$filePath = Import-Excel C:\Draft\testmultiplent.xlsx

$gpFile = $filePath | Group-Object -Property theName

$gpfile | ForEach-Object {

$ComputeResource = Get-vRAReservationComputeResource -Type $_.thePlatformType -Name $_.theComputeResource

$NetworkDefinitionArray = @() 
$Network1 = New-vRAReservationNetworkDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -NetworkPath $_.theNetworkPath1 -NetworkProfile $_.theNetworkProfile1
#$Network2 = New-vRAReservationNetworkDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -NetworkPath $_.theNetworkPath2 -NetworkProfile $_.theNetworkProfile2
$NetworkDefinitionArray += $Network1


$StorageDefinitionArray = @() 
$Storage1 = New-vRAReservationStorageDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -Path $_.theDataStorePath1 -ReservedSizeGB $_.theReservedSizeGB -Priority $_.thePriority
#$Storage2 = New-vRAReservationStorageDefinition -Type $_.thePlatformType -ComputeResourceId $ComputeResource.Id -Path $_.theDataStorePath2 -ReservedSizeGB $_.theReservedSizeGB -Priority $_.thePriority
$StorageDefinitionArray += $Storage1

$resType    = $_.thePlatformType
$resName    = $_.theName
$resBG      = $_.theBusinessGroup
$resCompute = $ComputeResource.Id
$resNetwork = $NetworkDefinitionArray
$resStorage = $StorageDefinitionArray
$resMEM     = $_.theMemory

New-vRAReservation -Type $resType -Name $resName -BusinessGroup $resBG -ComputeResourceId $resCompute -MemoryGB $resMEM -Storage $resStorage -Network $resNetwork -Confirm:$false
}