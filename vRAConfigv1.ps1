Import-Module -Name PowervRA -Scope Local

#Function to get Password
function getTenantInfo ($msg) {
	$title 	= 'World Wide Technology';
	[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
	[Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
}

#Function for the custom popup Box
function popupBox ($msg, $num) {
    $a = new-object -comobject wscript.shell
    $a.popup($msg, 0,"World Wide Technology",$num)
}

#Function to connect to a vRA instance
function connectvRA ($server,$credential,$tenant) {
    $param = @{
        Server = $server;
        Credential = $credential;
    }
    if ($tenant) {
        $param.Add("Tenant",$tenant)
    }
    Connect-vRAServer @param
}


#Message Box variable 
$a = new-object -comobject wscript.shell

#Get vRA name
$vRAServer = getTenantInfo -msg 'Please enter your vRA server: i.e. vra-01.lab.local'

# Import all the Excel Sheets into their own variable
$vRAConfig_NewTenant 			=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName New-Tenant
$vRAConfig_NewTenantUser 		=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName New-TenantUser
$vRAConfig_NewTenantDir 		=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName New-TenantDirectory
$vRAConfig_BusGroups 			=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName Business-Groups
$vRAConfig_NWProfiles 		=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName Network-Profile
$vRAConfig_ResPolicys 		=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName Reservation-Policy
$vRAConfig_StorResPolicys 	=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName StorageReservation-Policy
$vRAConfig_vRAReservations 	=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName vRA-Reservations
$vRAConfig_Entitlements 		=Import-excel "C:\code\vRAConfig.xlsx" -WorksheetName Entitlement 

# Creating Tenant 
$intAnswer = popupBox -msg "Is this your first time running the script?" -num '4'

If ($intAnswer -eq 6) {
    #Get all the credentials needed for the script
    popupBox -msg "Please enter in the Default Tenant Administrator Username and Password" -num 0
    $defaultTenant = (Get-Credential)

    #Store password for Local User Tenant account
    $TextPassword = getTenantInfo -msg 'Please enter in the Password you want to use for the local User Tenant account:'
    $SecurePassword = ConvertTo-SecureString -String $TextPassword -AsPlainText -Force

    #Connecting to Default Tenant as Administrator
    connectvRA -Server $vRAServer -Credential $defaultTenant
    
    $vRAConfig_NewTenant | ForEach-Object {
    New-vRATenant -Name $_.theName -Description $_.theDescription -URLName $_.theURL -ContactEmail $_.theEmail -ID $_.theID
    }
    #Creating Local user for each Tenant in the list
    $vRAConfig_NewTenantUser | ForEach-Object {
        New-vRAUserPrincipal -Tenant $_.theTenant -FirstName $_.theFTName -LastName $_.theLTName -EmailAddress $_.theEmail -Description `
        $_.theDescription -Password $SecurePassword -PrincipalId $_.thePrincipalID
        #Making user Tenant Administrator and IAAS Administrator with in their Tenant
        $rolelist = @("CSP_TENANT_ADMIN", "COM_VMWARE_IAAS_IAAS_ADMINISTRATOR")
            foreach($i in $rolelist) {
            Add-vRAPrincipalToTenantRole -TenantId $_.theTenant -PrincipalId $_.thePrincipalID -RoleId $i -Verbose -Confirm:$false
            }
    } 

    #Add AD Directory to New Tenant 
    $vRAConfig_NewTenantDir | ForEach-Object {
        New-vRATenantDirectory -ID $_.theID -Name $_.theName -Description $_.theDescription -Type $_.theType -Domain $_.theDomain -UserNameDN $_.theUserNameDN  `
        -Password $SecurePassword -URL $_.theURL -GroupBaseSearchDN $_.theGroupBaseSearchDN -UserBaseSearchDN $_.theUserBaseSearchDN -GroupBaseSearchDNs $_.theGroupBaseSearchDNs -TrustAll
    }
    $intAnswer = popupBox -msg "Please log into your new Tenant and Configure your Endpoints and Fabric Groups. Then run the script again. `
(Remember to click 'NO' when asked 'Is this your first time running the script?')" -num 0
        if ($intAnswer -eq  1) {
        exit
        }
} else {
    popupBox -msg "Continuing to configure vRA with your Business Groups, Storage and Reservation Policies, Network Profiles, and Reservation"
    
	#Custom Box to request Tenant to configure
	$TenantName = getTenantInfo -msg 'Please Enter your Tenant Name you would like to configure:'

	popupBox -msg "Please enter in the Tenant Username (FQDN) and Password you will use to configure vRA:"
	$TenantAccount = (Get-Credential)
	
	#Connecint to vRA Tenant to configure
    Connect-vRAServer -Server $vRAServer -Tenant $TenantName -Credential $TenantAccount

    #Business Group working cmd
    $vRAConfig_BusGroups | ForEach-Object {
        New-vRABusinessGroup -Name $_.theName -Description $_.theDescription -BusinessGroupManager $_.theBGGroupMgr -SupportUser $_.theBGSupportUser -User $_.theBGUser `
        -MachinePrefixId $_.theBGMachinePrefixId -SendManagerEmailsTo $_.theBGSendMgrEmailsTo
    }
    #ReservationPolicy - Write an If statement to confirm the sheet has been field out. If Null skip the Policy and move on to Network Profile section. 
    $vRAConfig_ResPolicys | ForEach-Object {
        New-vRAReservationPolicy -Name $_.theName -Description $_.theDescription -Confirm:$false
    }
    #Storage Reservation Policy working cmd
    $vRAConfig_StorResPolicys | ForEach-Object {
        New-vRAStorageReservationPolicy -Name $_.theName -Description $_.theDescription -Confirm:$false
    }

    #Network Profile - Currently script is creating vRA IPAM network Profiles. INFOBlox needs tobe tested. 
    #Look into rewriting these Section so that Multiple Ranges can be inside the same profile. Maybe a Max of 2 to 4 Ranges. 
	#anything above that might go into a different script. 
    function GetNetworkRange ($theStartIP,$theEndIP) {   
		$param = @{
			Name              = $_.theRangeName;
			Description		  = $_.theRangeDesc;
			StartIPv4Address  = $_.theStartIP;
			EndIPv4Address    = $_.theEndIP;
		}
    New-vRANetworkProfileIPRangeDefinition @param
}
	$vRAConfig_NWProfiles | ForEach-Object {
		$DefinedRange1 = @{
        IPRanage = (GetNetworkRange -theStartIP $resData.theNetworkPath1 -theEndIP $resData.theNetworkProfile1)
				   #(GetNetworkRange -theStartIP $resData.theNetworkPath2 -theEndIP $resData.theNetworkProfile2)
        }      
        #orginial cmd in script. 
		#$DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name $_.theRangeName -Description $_.theRangeDesc `
		#		      -StartIPv4Address $_.theStartIP -EndIPv4Address $_.theEndIP
        #$DefinedRange2 = New-vRANetworkProfileIPRangeDefinition -Name $theRangeName -Description $theRangeDesc `
		#				  -StartIPv4Address "10.60.1.10" -EndIPv4Address "10.60.1.20"	
        $Name 					= $_.theName
        $Description 			= $_.theDescription
        $SubnetMask 			= $_.theSubnetMask
        $GatewayAddress		= $_.theGateway
        $PrimaryDNSAddress    	= $_.thePrimaryDNS
        $SecondaryDNSAddress 	= $_.theSecondaryDNS
        $DNSSuffix				= $_.theDNSSuffix
        $DNSSearchSuffix 		= $_.theDNSSearchSuffix

        New-vRAExternalNetworkProfile -Name $Name -Description $Description -SubnetMask $SubnetMask -GatewayAddress $GatewayAddress -PrimaryDNSAddress $PrimaryDNSAddress `
                                      -SecondaryDNSAddress $SecondaryDNSAddress -DNSSuffix $DNSSuffix -DNSSearchSuffix $DNSSearchSuffix -IPRanges $DefinedRange1.IPRanage -Confirm:$false

}
    #Creating the vRA Reservation now that all required sections have been done.
    function buildvRAReservationParam ($theName, $theTenant, $theBusinessGroup, $theComputeResource, $theResPolicy, $thePlatformType, $theNetworkPath, `
                                       $theNetworkProfile, $theDataStorePath, $theMemoryGB, $theReservedSizeGB, $thePriority) {

        $myComputeResource = Get-vRAReservationComputeResource -Type $thePlatformType -Name $theComputeResource

	    $NetworkDefinitionArray = @() 
	    $myNetwork1 = New-vRAReservationNetworkDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -NetworkPath $theNetworkPath -NetworkProfile $theNetworkProfile
	    #$myNetwork2 = New-vRAReservationNetworkDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -NetworkPath $theNetworkPath2 -NetworkProfile $theNetworkProfile2
	    $NetworkDefinitionArray += $myNetwork1 #, $myNetwork2

	    $StorageDefinitionArray = @() 
	    $myStorage1 = New-vRAReservationStorageDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -Path $theDataStorePath -ReservedSizeGB $theReservedSizeGB -Priority $thePriority
	    #$myStorage2 = New-vRAReservationStorageDefinition -Type $thePlatformType -ComputeResourceId $myComputeResource.Id -Path $theDataStorePath2 -ReservedSizeGB $theReservedSizeGB -Priority $thePriority
        $StorageDefinitionArray += $myStorage1 #, $myStorage2
 
	    $myParam = @{
            Type 				= $thePlatformType;
            Name 				= $theName;
            Tenant 				= $theTenant;
            BusinessGroup 		= $theBusinessGroup;
            ReservationPolicy 	= $theResPolicy;
            Priority 			= $thePriority;
            ComputeResourceId 	= $myComputeResource.id;
            Quota 				= $theReservedSizeGB;
            MemoryGB 			= $theMemoryGB;
            Storage 			= $StorageDefinitionArray;
            Network 			= $NetworkDefinitionArray;
            EnableAlerts 		= $false
        }
        return $myParam
    } 

    # Build and empty object to hold all our reservaction objects
    $ourReservations = @()

    # Loop through the excel data and add to our reservaction objects
    ForEach ($item in $vRAConfig_vRAReservations) {
        $ourReservations += buildvRAReservationParam $item.thePlatformType $item.theName $item.theBusinessGroup $item.theComputeResource  $item.theNetworkPath $item.theNetworkProfile $item.theDataStorePath
    }

    # Loop through each reservation in our reservation object and create the vRAReservation 
    foreach($reservation in $ourReservations) {
        New-vRAReservation @reservation -Verbose
    }

    #Entitlements 
    $vRAConfig_Entitlements | ForEach-Object {
        New-vRAEntitlement -Name $_.theName -BusinessGroup $_.theBG -Description $_.theDescription -EntitledCatalogItems $_.theCatItem -Principals $_.thePrincipal -EntitledServices $_.theService -Confirm:$false
    }
}


#Items I would like to add into this eventually is 1) import vRA Icons, 2) Build out Services 3) 