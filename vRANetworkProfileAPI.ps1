
#Function to Invoke-RestMethod
function restCall ($URI, $Header, $body) {
	$param = @{
		Method 	= "Post";
		Uri 	= $URI;
		Headers	= $header;
		Body	= $body;
	}
	Invoke-RestMethod @param
}

#Function to get Password
function getTenantInfo ($msg) {
	$title 	= 'World Wide Technology';
	[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
	[Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
}

#import xcel data
$vRAConfig_IPAMNWProfiles	= import-excel "c:\draft\IPAMNWProfiles.xlsx"

#Get vRA Server, Tenant, User, and Password information for the env your run this in
$vRAServer         = getTenantInfo -msg 'Please enter your vRA server: i.e. vra-01.lab.local'
$vRATenant			= getTenantInfo -msg 'Please enter the Tenant name: i.e. lab'
$vRAUser 			= getTenantInfo -msg 'Please enter the FQDN of the User: i.e. vraadmin@lab.local'
$Password 			= getTenantInfo -msg 'Please enter in the Password for the User account:'

#These are all the API links the script will be calling
$URI 				= "https://$vRAServer/identity/api/tokens"
$networkprofile 	= "https://$vRAServer/iaas-proxy-provider/api/network/profiles"

#This creates the initial Header and body for authentication
$header = @{ "Accept" = "application/json"; "Content-Type" = "application/json"  }

$body = @{
    username = "$vRAUser";
    password = "$Password";
    tenant   = "$vRATenant"
}
 
#Holds the token as a variable to use as the Bearer Token for authentication 
$token = restCall -URI $URI -Header $header -body (ConvertTo-Json $body)

#Adding the Bearer token to the header
$header.Add("Authorization", "Bearer " + $token.id)

#This goes through the excel import and loops through each line to create the network profile in vRA
$vRAConfig_IPAMNWProfiles | forEach-object {

$body = @"
{
 "profileType" : "EXTERNAL",
 "id" : null,
 "@type" : "ExternalNetworkProfile",
 "name" : "$($_.theName)",
 "IPAMEndpointId" : "$($_.theEndpointId)",
 "addressSpaceExternalId" : "$($_.theAddrSpaceId)",
 "description" : "$($_.theDescription)",
 "definedRanges" : [{
	"externalId" : "$($_.theExternalId)",
	"name" : "$($_.theRangeName)",
	"description" : "Created by vRO package stub workflow",
	"state" : "UNALLOCATED",
	"beginIPv4Address" : null,
	"endIPv4Address" : null
 }
 ]
}
"@

restCall -Uri $networkprofile -Header $header -Body $body
}



