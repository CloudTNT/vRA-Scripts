
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
#$vRAConfig_IPAMNWProfiles	= import-excel "c:\draft\IPAMNWProfiles.xlsx"

#Get vRA Server, Tenant, User, and Password
$vRAServer          = getTenantInfo -msg 'Please enter your vRA server: i.e. vra-01.lab.local'
$vRATenant			= getTenantInfo -msg 'Please enter the Tenant name: i.e. lab'
$vRAUser 			= getTenantInfo -msg 'Please enter the FQDN of the user: i.e. vraadmin@lab.local'
$TextPassword 		= getTenantInfo -msg 'Please enter in the Password you want to use for the local User Tenant account:'
#$SecurePassword 	= ConvertTo-SecureString -String $TextPassword -AsPlainText -Force

$header = @{ "Accept" = "application/json"; "Content-Type" = "application/json"  }

$body = @{
    username = "$vRAUser";
    password = "$TextPassword";
    tenant   = "$vRATenant"
}

$URI = "https://$vRAServer/identity/api/tokens"
 
$token = restCall -URI $URI -Header $header -body (ConvertTo-Json $body)

$header.Add("Authorization", "Bearer " + $token.id)


$body = @"
{
 "profileType" : "EXTERNAL",
 "id" : null,
 "@type" : "ExternalNetworkProfile",
 "name" : "Splatting Network Profile",
 "IPAMEndpointId" : "c37c7634-5a76-4b31-b76d-ab1452ef82db",
 "addressSpaceExternalId" : "default",
 "description" : "Created by Postman",
 "definedRanges" : [{
	"externalId" : "network/default/10.254.0.0/27",
	"name" : "10.254.0.0/27",
	"description" : "Created by vRO package stub workflow",
	"state" : "UNALLOCATED",
	"beginIPv4Address" : null,
	"endIPv4Address" : null
 }
 ]
}
"@

$networkprofile = "https://$vRAServer/iaas-proxy-provider/api/network/profiles"

restCall -Uri $networkprofile -Header $header -Body $body

