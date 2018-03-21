
#Function Invoke-RestMethod
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

#Function for the custom popup Box
function popupBox ($msg, $num) {
    $a = new-object -comobject wscript.shell
    $a.popup($msg, 0,"World Wide Technology",$num)
}

#import xcel data
$vRAConfig_IPAMNWProfiles	= import-excel "c:\draft\IPAMNWProfiles.xlsx"

#Get vRA Server, Tenant, User, and Password
$vRAServer         = getTenantInfo -msg 'Please enter your vRA server: i.e. vra-01.lab.local'
$vRATenant			= getTenantInfo -msg 'Please enter the Tenant name: i.e. lab'
$vRAUser 			= getTenantInfo -msg 'Please enter the FQDN of the user: i.e. vraadmin@lab.local'
$TextPassword 		= getTenantInfo -msg 'Please enter in the Password you want to use for the local User Tenant account:'

$header = @{ "Accept" = "application/json"; "Content-Type" = "application/json"  }

$body = @{
    username = "$vRAUser";
    password = "$TextPassword";
    tenant   = "$vRATenant"
}
#API links
$URI 				= "https://$vRAServer/identity/api/tokens"
$networkprofile 	= "https://$vRAServer/iaas-proxy-provider/api/network/profiles"
 
$token = restCall -URI $URI -Header $header -body (ConvertTo-Json $body)

$header.Add("Authorization", "Bearer " + $token.id)

$vRAConfig_IPAMNWProfiles | forEach-object {

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
