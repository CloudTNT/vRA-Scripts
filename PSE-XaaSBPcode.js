var str = "SQEWPHONO05V01";
var str.length
var arr = str.split('');
var n = str.length; 
System.log(n);
switch (n) {
    case 13:
      var app = arr[5] + arr[6] + arr[7];
      var domain = arr[8] + arr[9];
      break;
    case 14: case 15:
      var app = arr[5] + arr[6] + arr[7] + arr[8];
      var domain = arr[9] + arr[10];
      break;
    default:
		System.error("Netbios named passed in is not valid");
}

var loc = arr[0] + arr[1] + arr[2];
var OS = arr[3];
var env = arr[4];

switch (loc) {
    case "SQE":
        loc = "Deploys to new vCenter";
        break;
    case "CAS":
        loc = "Deploys to new vCenter";
        break;
    case "VLS":
        loc = "Deploys to new vCenter";
        break;
    case "BOT":
        loc = "Boston";
        break;
    case "EST":
        loc = "Estates";
        break;
    case "BHS":
        loc = "BHS Who";
        break;
    case "ESO":
        loc = "Moon";
}

switch (domain) {
    case "01":
        domain = "Puget.com";
        break;
    case "02":
        domain = "testpse.loc";
        break;
    case "03":
        domain = "pugetops.loc";
        break;
    case "04":
        domain = "gasprod.loc";
        break;
    case "05":
        domain = "gastest.loc";
        break;
    case "06":
        domain = "psepublic.loc";
        break;
    case "07":
        domain = "webtest.loc";
        break;
    case "08":
        domain = "ecstestlab.loc";
        break;
    case "00":
        domain = "workgroup";
}
System.log(loc);
System.log(domain);

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
