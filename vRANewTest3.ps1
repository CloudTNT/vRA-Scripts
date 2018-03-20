$ComputeResource = Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Resource (https://vc.lab.local/sdk)'

$NetworkDefinitionArray = @() 
$Network1 = New-vRAReservationNetworkDefinition -Type 'vSphere (vCenter)' -ComputeResourceId $ComputeResource.Id -NetworkPath 'vxw-dvs-64-virtualwire-3-sid-5002-vRA-VMs' -NetworkProfile 'vRA-VMs'
$NetworkDefinitionArray += $Network1

$StorageDefinitionArray = @() 
$Storage1 = New-vRAReservationStorageDefinition -Type 'vSphere (vCenter)' -ComputeResourceId $ComputeResource.Id -Path 'Resource Storage Cluster' -ReservedSizeGB 10 -Priority 0
$StorageDefinitionArray += $Storage1

$resType = 'vSphere (vCenter)'
$resName = 'Test'
$resBG = 'BG01'
$resCompute = '48cd89cd-fa8b-4450-ad6f-1851d748666a'

$resNetwork = $NetworkDefinitionArray
$resStorage = $StorageDefinitionArray
$resMEM = '2048'
New-vRAReservation -Type $resType -Name $resName -BusinessGroup $resBG -ComputeResourceId $resCompute -MemoryGB $resMEM -Storage $resStorage -Network $resNetwork
