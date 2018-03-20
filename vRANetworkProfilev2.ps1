$filePath = import-csv "C:\draft\NetworkProfileList.csv"

$filePath | ForEach-Object {
    $DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name $_.theRangeName -Description $_.theRangeDesc -StartIPv4Address $_.theStartIP -EndIPv4Address $_.theEndIP
    #$DefinedRange2 = New-vRANetworkProfileIPRangeDefinition -Name $theRangeName -Description $theRangeDesc -StartIPv4Address "10.60.1.10" -EndIPv4Address "10.60.1.20"
        $Name = $_.theName
        $Description = $_.theDescription
        $SubnetMask = $_.theSubnetMask
        $GatewayAddress = $_.theGateway
        $PrimaryDNSAddress =$_.thePrimaryDNS
        $SecondaryDNSAddress =$_.theSecondaryDNS
        $DNSSuffix = $_.theDNSSuffix
        $DNSSearchSuffix = $_.theDNSSearchSuffix

New-vRAExternalNetworkProfile -Name $Name -Description $Description -SubnetMask $SubnetMask -GatewayAddress $GatewayAddress -PrimaryDNSAddress $PrimaryDNSAddress -SecondaryDNSAddress $SecondaryDNSAddress -DNSSuffix $DNSSuffix -DNSSearchSuffix $DNSSearchSuffix -IPRanges $DefinedRange1 -Verbose -Confirm:$false

}

#working cmd below
#$DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-01" -Description "Example 1" -StartIPv4Address "10.60.1.2" -EndIPv4Address "10.60.1.5"
#$DefinedRange2 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-02" -Description "Example 2" -StartIPv4Address "10.60.1.10" -EndIPv4Address "10.60.1.20"
#New-vRAExternalNetworkProfile -Name Network-External -Description "External" -SubnetMask "255.255.255.0" -GatewayAddress "10.60.1.1" -PrimaryDNSAddress "10.60.1.100" -SecondaryDNSAddress "10.60.1.101" -DNSSuffix "corp.local" -DNSSearchSuffix "corp.local" -IPRanges $DefinedRange1,$DefinedRange2 -Confirm:$false


