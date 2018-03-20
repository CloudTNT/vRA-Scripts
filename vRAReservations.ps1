Import-Module -Name PowervRA -Scope Local

Connect-vRAServer -Server vra-01.lab.local -Tenant lab -Credential (Get-Credential)

$GLOBAL:STORAGESIZEGB = 10
$GLOBAL:STORAGEPRIORITY = 0
$GLOBAL:CSVIMPORTFILE = "C:\Draft\vRAReservationList.csv"

# Import our CSV data file
$ourCSVDataImport = Import-CSV -path $GLOBAL:CSVIMPORTFILE

function buildvRAReservationParam ($theName, $theBusinessGroup, $theComputeResource, $thePlatformType, $theNetworkPath1, $theNetworkProfile1, $theNetworkPath2, $theNetworkProfile2, $theDataStorePath1, $theDataStorePath2) {
    $myComputeResource = Get-vRAReservationComputeResource -Type $thePlatformType -Name $theComputeResource

	$NetworkDefinitionArray = @() 
	$myNetwork1 = New-vRAReservationNetworkDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -NetworkPath $theNetworkPath1 -NetworkProfile $theNetworkProfile1
	$myNetwork2 = New-vRAReservationNetworkDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -NetworkPath $theNetworkPath2 -NetworkProfile $theNetworkProfile2
	$NetworkDefinitionArray += $myNetwork1, $myNetwork2

	$StorageDefinitionArray = @() 
	$myStorage1 = New-vRAReservationStorageDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -Path $theDataStorePath1 -ReservedSizeGB $GLOBAL:STORAGESIZEGB -Priority $GLOBAL:STORAGEPRIORITY
	$myStorage2 = New-vRAReservationStorageDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -Path $theDataStorePath2 -ReservedSizeGB 8 -Priority 1
    $StorageDefinitionArray += $myStorage1, $myStorage2
	
	Write-Host $StorageDefinitionArray
    
	$myParam = @{
        Type = 'vSphere (vCenter)';
        Name = $theName;
        Tenant = 'Lab';
        BusinessGroup = $theBusinessGroup;
        ReservationPolicy = 'EDGE';
        Priority = 0;
        ComputeResourceId = $myComputeResource.id;
        Quota = 0;
        MemoryGB = 2048;
        Storage = $StorageDefinitionArray;
        Network = $NetworkDefinitionArray;
        EnableAlerts = $false
    }
    return $myParam
} 

# Build and empty object to hold all our reservaction objects
$ourReservations = @()

# Loop through the CSV data and add to our reservaction objects
ForEach ($item in $ourCSVDataImport) {
    $ourReservations += buildvRAReservationParam $item.theName $item.theBusinessGroup $item.theComputeResource $item.thePlatformType $item.theNetworkPath1 $item.theNetworkProfile1 $item.theNetworkPath2 $item.theNetworkProfile2 $item.theDataStorePath1 $item.theDataStorePath2
}

# Loop through each reservation in our reservation object and create the vRAReservation 
foreach($reservation in $ourReservations) {
    New-vRAReservation @reservation -Verbose
}