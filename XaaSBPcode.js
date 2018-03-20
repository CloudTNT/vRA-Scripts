
//Combine the business unit and 5 character product field to create the ProductName passed to back to VRA
var combinedProductName = business_unit + ProductName;
var combinedProductName = (business_unit.toLowerCase() + ProductName.toLowerCase());

//Setup network decisions
switch(Location) {
	case "HQ":
		var locationAdjusted = "edge";
		break;
	case "New DataCenter":
		var locationAdjusted = "sdrs";
		break;		
	case "DataCenter A":
		var locationAdjusted = "MGMT-res";
		break;
	case "Sandbox":
		var locationAdjusted = "Reservation01";
		var hostname_format = "devwn{VirtualMachine.CustomName.ProductName}{%}"
		break;		
	default:
		System.error("No valid location specified");
}
//Change blueprint being requested based on Dev-Sandbox
if (Location == 'HETD-Sandbox') {
   if (Tier == 'db'){
       if (SQL_storage == 'small'){
           request(sandbox_sql_itemsm);
       } else if (SQL_storage == 'medium'){
           request(sandbox_sql_itemmd);
       } else if (SQL_storage == 'large'){
           request(sandbox_sql_itemlg);
       }
   }else {
       request(sandbox_windows_item);
   }
}else if (Tier == 'db'){
   if (Location == 'HETD') {
       if (SQL_storage == 'small'){
           request(dev_sql_itemsm);
       } else if (SQL_storage == 'medium'){
           request(dev_sql_itemmd);
       } else if (SQL_storage == 'large'){
           request(dev_sql_itemlg);
       }
   }else if (SQL_version == '2014'){
       if (SQL_storage == 'small'){
          	request(sql_itemsm);
       } else if (SQL_storage == 'medium'){
           request(sql_itemmd);
       } else if (SQL_storage == 'large'){
           request(sql_itemlg);
       }
   }else if (SQL_version == '2016'){
       if (SQL_storage == 'small'){
            request(sql_2016_itemsm);
       } else if (SQL_storage == 'medium'){
            request(sql_2016_itemmd);
       } else if (SQL_storage == 'large'){
            request(sql_2016_itemlg);
        }
   } 
}else {
   request(Windows_Item);
}		

function request(catalog){
System.log("deploying "+Windows+" Windows server's with "+Windows_CPU+" CPUs and "+Windows_Memory+" memory and "+Windows_Storage+" Storage and "+Location+" Location");
for(i=0;i<Windows;i++){
var myProvisioningRequest = vCACCAFERequestsHelper.getProvisioningRequestForCatalogItem(catalog);
System.log(myProvisioningRequest);

var disk = new Properties();     //create disk properties object
var diskdata = new Properties(); //create disk data object
var businessGroupId = System.getContext().getParameter("__asd_subtenantRef");
System.debug("businessGroupId: "+businessGroupId);

myProvisioningRequest.setDescription(description);
myProvisioningRequest.setReasons(reason);
myProvisioningRequest.setBusinessGroupId(businessGroupId);


var getProvisioningRequestData = vCACCAFERequestsHelper.getProvisioningRequestData(myProvisioningRequest);
var setRequestData = JSON.parse(getProvisioningRequestData);

// Calculate totalStorage by looping through all existing disks and adding their capacity to additional, request-time storage.
var totalStorage = Windows_Storage;
for (var i = 0; i < setRequestData.vSphere_Machine_1.data.disks.length; i++) {
	totalStorage += setRequestData.vSphere_Machine_1.data.disks[i].data.capacity;
  }
System.log("totalStorage: " + totalStorage);
  

//var provisioningRequest = vCACCAFERequestsHelper.getProvisioningRequestForCatalogItem(catalog);
setRequestData.vSphere_Machine_1.data.cpu = Windows_CPU;
setRequestData.vSphere_Machine_1.data.memory = Windows_Memory;
setRequestData.vSphere_Machine_1.data["Vrm.DataCenter.Location"] = locationAdjusted;
setRequestData.vSphere_Machine_1.data["Environment"] = Environment;
setRequestData.vSphere_Machine_1.data["Tier"] = Tier;
setRequestData.vSphere_Machine_1.data["VirtualMachine.CustomName.ProductName"] = combinedProductName;
setRequestData.vSphere_Machine_1.data["requestedFor"] = requestedFor;
setRequestData.vSphere_Machine_1.data["addedStorage"] = Windows_Storage;
setRequestData.vSphere_Machine_1.data["storage"] = totalStorage;

//Set the properties at the data level
diskdata.capacity = Windows_Storage;
diskdata.custom_properties = null;
diskdata.initial_location = "";
diskdata.is_clone = false;
diskdata.label = "Hard disk 3";
diskdata.userCreated = true;
diskdata.volumeId = 2;
 
//Set the properties on the disk object. 
disk.classId = "Infrastructure.Compute.Machine.MachineDisk";
disk.componentId = null;
disk.componentTypeId = "com.vmware.csp.iaas.blueprint.service";
disk.typeFilter = null;

//Add diskdata properties object to the disk object
disk.put ("data",diskdata);

//Now push the new cell to the disks array in the JSON object 
setRequestData.vSphere_Machine_1.data.disks.push (disk);

vCACCAFERequestsHelper.setProvisioningRequestData(myProvisioningRequest, JSON.stringify(setRequestData));
System.getModule("com.vmware.library.vcaccafe.request").requestCatalogItemWithProvisioningRequest(catalog, myProvisioningRequest);
//System.sleep(60000);
}
}
