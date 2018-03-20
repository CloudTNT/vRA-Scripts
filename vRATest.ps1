$GLOBAL:STORAGESIZEGB = 10
$GLOBAL:STORAGEPRIORITY = 0
$GLOBAL:CSVIMPORTFILE = "C:\Draft\test.csv"

function buildvRAReservationParam ($theName, $theBusinessGroup, $theComputeResource, $thePlatformType, $theNetworkPath, $theNetworkProfile, $theDataStorePath) {
    $myComputeResource = Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name "Resource ($theComputeResource)"
    $myNetwork = New - vRAReservationNetworkDefinition - Type $thePlatformType - ComputeResourceId $myComputeResource.Id - NetworkPath $theNetworkPath - NetworkProfile $theNetworkProfile
    $myStorage = New - vRAReservationStorageDefinition - Type $thePlatformType - ComputeResourceId $myComputeResource.Id - Path $theDataStorePath - ReservedSizeGB $GLOBAL:STORAGESIZEGB - Priority $GLOBAL:STORAGEPRIORITY $StorageDefinitionArray +=$myStorage
    
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
        Storage = $myStorage;
        Network = $myNetwork;
        EnableAlerts = $false
    }
    return $myParam
} 

# Import our CSV data file
$ourCSVDataImport = Import-CSV -path $GLOBAL:CSVIMPORTFILE

# Build and empty object to hold all our reservaction objects
$ourReservations = @()

# Loop through the CSV data and add to our reservaction objects
ForEach ($item in $ourCSVDataImport) {
    $ourReservations += buildvRAReservationParam $item.theName $item.theBusinessGroup $item.theComputeResource $item.thePlatformType $item.theNetworkPath $item.theNetworkProfile $item.theDataStorePath
}

# Loop through each reservation in our reservation object and create the vRAReservation 
foreach($reservation in $ourReservations) {
    New-vRAReservation $reservation -Verbose
}