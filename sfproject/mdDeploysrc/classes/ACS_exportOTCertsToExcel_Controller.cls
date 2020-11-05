public class ACS_exportOTCertsToExcel_Controller  {
    public ApexPages.StandardController stdCtrl {get; set;}
    @AuraEnabled
    public String recordId {get; set;}
    
    //Maps & Lists
    public Map<String, List<ACS_CertificationLineItem__c>> mapOTCert {get; set;}
    
    @AuraEnabled
    public List<ACS_CertificationLineItem__c> listCertLI {get; set;}
    public List<String> labels {get; set;}
    public List<String> nullList {get; set;}
    
    //Vars
    public String objectAPIName {get; set;}
    public String activity {get; set;}
    public String UrlToPass {get; set;}
    public String dateExport {get;set;}
    
    //Classes
    public class cli {
        public String subject {get; set;}
        public String certification {get; set;}
        public String productName {get; set;}
        public String productLink {get; set;}
        public String cliName {get; set;}
        public String cliType {get; set;}
        public String description {get; set;}
        public String pricebook {get;set;}
        public String pricebookLink {get; set;}
        public String unitPrice {get; set;}
        public String k {get;set;}
        public String totalPrice {get; set;}
    }
    
    public class OT{
        public double totalPerOT {get; set;}
        public integer noLines {get; set;}
        public List<ACS_CertificationLineItem__c> listToExcel {get; set;}
    }
    
    public Map<String, OT> mapOTDetails {get;set;}

    public String xlsHeader {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0" encoding="UTF-8"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    
    public ACS_exportOTCertsToExcel_Controller (ApexPages.StandardController controller){
       
        stdCtrl = controller;
        UrlToPass = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        dateExport = String.valueOfGmt(Datetime.now());

        //get parameters from URL.
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        activity = ApexPages.currentPage().getParameters().get('activity');
        
        //Set column headers label
        labels = new List<String>{'Certificación','Nº de Encargo','Ítem de Baremo', 'Nombre', 'Tipo', 'Descripción', 'Lista de Precios', 'Precio', 'K', 'Precio Final'};
        

        //initiate lists & maps.
		listCertLI = new List<ACS_CertificationLineItem__c>();
        nullList = new List<String>();
        mapOTDetails = new Map<String,OT>();
        mapOTCert = new Map<String, List<ACS_CertificationLineItem__c>>();
            if(activity == 'undefined'){
                Id recordObject = Id.valueOf(recordId);
                objectAPIName = recordObject.getSObjectType().getDescribe().getName();    
                
                listCertLI = ACS_FinancialControlController.getCLIs(objectAPIName, null, recordId);
                system.debug(listCertLI);
            }else{
                listCertLI = ACS_FinancialControlController.getCLIs('Activity', activity, recordId);
            }
        
        mapOTCert = getOTCLIMap(listCertLI);
        mapOTDetails = getMapToExcel(listCertLI);
        
        if(mapOTDetails.keySet().size() == 0){
            nullList.add('Por el momento, no hay líneas de certificación disponibles.');
        }
    }
	
    public Map<String, List<ACS_CertificationLineItem__c>> getOTCLIMap(List<ACS_CertificationLineItem__c> cliList){
        Map<String, List<ACS_CertificationLineItem__c>> mapToReturn = new Map<String, List<ACS_CertificationLineItem__c>>();
        for(ACS_CertificationLineItem__c cli : cliList){
            if(!mapToReturn.containsKey(cli.ACS_OT__r.Name)){
                mapToReturn.put(cli.ACS_OT__r.Name, new List<ACS_CertificationLineItem__c>{cli});
            }else{
                mapToReturn.get(cli.ACS_OT__r.Name).add(cli);
            }
        }
        return mapToReturn;
    }
    
    public Map<String, OT> getMapToExcel(List<ACS_CertificationLineItem__c> cliList){
        Map<String, OT> mapToExcel = new Map<String, OT>();
        for(ACS_CertificationLineItem__c thisCli : cliList){
            thisCli.ACS_OT__r.Name = getOTName(thisCli);
            if(!mapToExcel.containsKey(thisCli.ACS_OT__r.Name)){
                OT ot = new OT();
                ot.totalPerOT = thisCli.ACS_Total__c;
                ot.listToExcel = new List<ACS_CertificationLineItem__c>{thisCli};
                mapToExcel.put(thisCli.ACS_OT__r.Name, ot);
            }else{
                OT ot = mapToExcel.get(thisCli.ACS_OT__r.Name);
                ot.totalPerOT = ot.totalPerOT + thisCli.ACS_Total__c;
                ot.listToExcel.add(thisCli);
            }
        }
        
        return mapToExcel;
    }
    
    public String getOTName(ACS_CertificationLineItem__c cli){
        List<String> invalidChars = new List<String>{'\\','/','*','[',']',':','?'};
            String nameToReturn;
        for(String naChar : invalidChars){
            if(cli.ACS_OT__r.Name.contains(naChar)){
                cli.ACS_OT__r.Name = cli.ACS_OT__r.Name.replace(naChar, '_');
                nameToReturn = cli.ACS_OT__r.Name;
            }else{
                nameToReturn = cli.ACS_OT__r.Name;
            }
        }
        return nameToReturn;
    }
    
    
}