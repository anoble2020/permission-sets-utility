public with sharing class PermissionsUtilityController {

    /*@AuraEnabled(cacheable=true)
    public static List<PermissionSet> getAllPermissionSets() {
        List<PermissionSet> permSets = [SELECT Id, Name FROM PermissionSet];
        Map<String, List<String>> permsMap = new Map<String, List<String>>();

        for(PermissionSet ps : permSets){
            List<String> details = new List<String>{ps.Id, ps.Label};
            permsMap.put(ps.Name, details);
        }

        return permsMap;
    }*/

    @AuraEnabled(cacheable=true)
    public static List<PermissionSet> getAllPermissionSets() {
        return [SELECT Id, Label FROM PermissionSet WHERE IsCustom = true AND NamespacePrefix = null];
    }

    @AuraEnabled
    public static Map<String, List<SObject>> getFieldPermissions(String permissionSetId, String objectName) {

        List<FieldPermissions> fieldPermissions = [
            SELECT Id, SObjectType, Field, PermissionsEdit, PermissionsRead
            FROM FieldPermissions
            WHERE ParentId = :permissionSetId AND SObjectType = :objectName
            ];

        List<ObjectPermissions> objectPermissions = [
            SELECT Id, PermissionsCreate, PermissionsDelete, PermissionsEdit, PermissionsRead, PermissionsModifyAllRecords, PermissionsViewAllRecords
            FROM ObjectPermissions
            WHERE ParentId = :permissionSetId AND SObjectType = :objectName LIMIT 1
        ];

        return new Map<String, List<SObject>>{'objects' => objectPermissions, 'fields' => fieldPermissions};
    }

    @AuraEnabled (cacheable=true)
    public static Map<String, String> getAllObjects() {
        try {      
            Map<String, String> objectMap = new Map<String, String>();
            Map<String, String> sortedObjectMap = new Map<String, String>();

            List<Schema.SObjectType> objects = Schema.getGlobalDescribe().values();

            for(Schema.SObjectType o : objects){
                Schema.DescribeSObjectResult objResult = o.getDescribe();
                if(!objResult.isCustomSetting() && objResult.isAccessible() && objResult.isQueryable() && !isSetupSObject(objResult.getName())){
                    objectMap.put(objResult.getLabel(), objResult.getName());
                }
            }

            List<String> keyList = new List<String>();
            keyList.addAll(objectMap.keySet());
            keyList.sort();

            for(String key : keyList){
                sortedObjectMap.put(objectMap.get(key), key);
            }

            return sortedObjectMap;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Set<String> SETUP_OBJECTS = new Set<String> { 'ActionLinkGroupTemplate',
    'ActionLinkTemplate', 'AdminSetupEvent', 'AdminSetupEventStream', 'AggregateResult',
    'AnimationRule', 'ApexClass', 'ApexClassMember', 'ApexCodeCoverage',
    'ApexCodeCoverageAggregate', 'ApexComponent', 'ApexComponentMember',
    'ApexEmailNotification', 'ApexExecutionOverlayAction', 'ApexExecutionOverlayResult',
    'ApexLog', 'ApexOrgWideCoverage', 'ApexPage', 'ApexPageInfo', 'ApexPageMember',
    'ApexResult', 'ApexTestQueueItem', 'ApexTestResult', 'ApexTestResultLimits',
    'ApexTestRunResult', 'ApexTestSuite', 'ApexTrigger', 'ApexTriggerMember', 'ApiEvent',
    'ApiEventStream', 'AppAnalyticsQueryRequest', 'AppDefinition', 'AppMenuItem',
    'AppTabMember', 'AssetTokenEvent', 'AssignmentRule', 'AsyncApexJob', 'AsyncOperationEvent',
    'AsyncOperationStatus', 'AuraDefinition', 'AuraDefinitionBundle',
    'AuraDefinitionBundleInfo', 'AuraDefinitionInfo', 'AuthConfig', 'AuthConfigProviders',
    'AuthProvider', 'AuthSession', 'AutoResponseRule', 'BackgroundOperation',
    'BatchApexErrorEvent', 'BrandingSet', 'BrandingSetProperty', 'BrandTemplate',
    'BusinessHours', 'BusinessProcess', 'CampaignMemberStatus', 'CaseStatus', 'Certificate',
    'CleanDataService', 'CleanRule', 'ClientBrowser', 'ColorDefinition', 'Community',
    'CommunityWorkspacesNode', 'CompactLayout', 'CompactLayoutInfo', 'CompactLayoutItemInfo',
    'ConnectedApplication', 'ContainerAsyncRequest', 'ContentBody', 'ContentHubItem',
    'ContentHubRepository', 'ContentWorkspace', 'ContractStatus', 'CorsWhitelistEntry',
    'CronJobDetail', 'CronTrigger', 'CspTrustedSite', 'CustomApplication', 'CustomBrand',
    'CustomBrandAsset', 'CustomField', 'CustomFieldMember', 'CustomHelpMenuItem',
    'CustomHelpMenuSection', 'CustomHttpHeader', 'CustomNotificationType', 'CustomObject',
    'CustomObjectUserLicenseMetrics', 'CustomPermission', 'CustomPermissionDependency',
    'CustomTab', 'Dashboard', 'DashboardComponent', 'DataAssessmentConfigItem',
    'DataAssessmentFieldMetric', 'DataAssessmentMetric', 'DataAssessmentValueMetric',
    'DatacloudAddress', 'DataIntegrationRecordPurchasePermission', 'DataStatistics',
    'DataType', 'DataUseLegalBasis', 'DataUsePurpose', 'DebugLevel', 'DeployDetails',
    'DirectMessage', 'DirectMessageMember', 'Document', 'DocumentAttachmentMap', 'Domain',
    'DomainSite', 'DuplicateJobDefinition', 'DuplicateJobMatchingRuleDefinition',
    'DuplicateRecordItem', 'DuplicateRecordSet', 'DuplicateRule', 'EmailCapture',
    'EmailDomainFilter', 'EmailDomainKey', 'EmailMessage', 'EmailRelay',
    'EmailServicesAddress', 'EmailServicesFunction', 'EmailStatus', 'EmailTemplate',
    'EmbeddedServiceBranding', 'EmbeddedServiceConfig', 'EmbeddedServiceCustomLabel',
    'EmbeddedServiceDetail', 'EmbeddedServiceFieldService', 'EmbeddedServiceLabel',
    'EmbeddedServiceLiveAgent', 'EmbeddedServiceQuickAction', 'EngagementEvent',
    'EnhancedLetterhead', 'EntityDefinition', 'EntityLimit', 'EntityParticle',
    'EventBusSubscriber', 'EventDelivery', 'EventLogFile', 'EventSubscription',
    'ExpressionFilter', 'ExpressionFilterCriteria', 'ExternalDataSource',
    'ExternalDataUserAuth', 'ExternalServiceRegistration', 'ExternalString', 'FieldDefinition',
    'FieldMapping', 'FieldMappingField', 'FieldMappingRow', 'FieldPermissions',
    'FieldSecurityClassification', 'FieldSet', 'FileSearchActivity', 'FiscalYearSettings',
    'FlexiPage', 'FlexQueueItem', 'Flow', 'FlowDefinition', 'FlowDefinitionView',
    'FlowElementTestCoverage', 'FlowInterview', 'FlowTestCoverage', 'FlowVariableView',
    'FlowVersionView', 'ForecastingDisplayedFamily', 'FormulaFunction', 'FormulaOperator',
    'GlobalValueSet', 'GrantedByLicense', 'Group', 'GroupMember',
    'HeapDump', 'HistoryRetentionJob', 'Holiday', 'HomePageComponent', 'HomePageLayout',
    'IconDefinition', 'IdpEventLog', 'IframeWhiteListUrl', 'Index', 'IndexField',
    'InstalledMobileApp', 'InstalledSubscriberPackage', 'InstalledSubscriberPackageVersion',
    'KeywordList', 'KnowledgeableUser', 'Layout', 'LeadStatus', 'LightningComponentBundle',
    'LightningComponentResource', 'LightningExitByPageMetrics', 'LightningExperienceTheme',
    'LightningToggleMetrics', 'LightningUriEvent', 'LightningUriEventStream',
    'LightningUsageByAppTypeMetrics', 'LightningUsageByBrowserMetrics',
    'LightningUsageByFlexiPageMetrics', 'LightningUsageByPageMetrics', 'ListView',
    'ListViewChart', 'ListViewChartInstance', 'ListViewEvent', 'ListViewEventStream',
    'LoginAsEvent', 'LoginAsEventStream', 'LoginEvent', 'LoginEventStream', 'LoginGeo',
    'LoginIp', 'LogoutEvent', 'LogoutEventStream', 'LookupFilter', 'Macro', 'MacroInstruction',
    'MacroUsage', 'MailmergeTemplate', 'ManagedContentNodeType', 'ManagedContentType',
    'MatchingRule', 'MatchingRuleItem', 'MenuItem', 'MetadataComponentDependency',
    'MetadataContainer', 'MetadataPackage', 'MetadataPackageVersion', 'Metric',
    'MetricDataLink', 'MobileApplicationDetail', 'ModerationRule', 'MyDomainDiscoverableLogin',
    'Name', 'NamedCredential', 'NavigationLinkSet', 'NavigationMenuItem', 'Network',
    'NetworkActivityAudit', 'NetworkAffinity', 'NetworkDiscoverableLogin', 'NetworkMember',
    'NetworkMemberGroup', 'NetworkModeration', 'NetworkPageOverride', 'NetworkSelfRegistration',
    'NetworkUserHistoryRecent', 'OauthCustomScope', 'OauthToken', 'ObjectPermissions',
    'OnboardingMetrics', 'OperationLog', 'OpportunitySplitType', 'OpportunityStage',
    'Organization', 'OrgDeleteRequest', 'OrgLifecycleNotification', 'OrgWideEmailAddress',
    'OutgoingEmail', 'OwnerChangeOptionInfo', 'Package2', 'Package2Member', 'Package2Version',
    'Package2VersionCreateRequest', 'Package2VersionCreateRequestError',
    'PackageInstallRequest', 'PackageLicense', 'PackageUploadRequest',
    'PackageVersionUninstallRequestError', 'PathAssistant', 'PathAssistantStepInfo',
    'PathAssistantStepItem', 'Period', 'PermissionDependency', 'PermissionSet',
    'PermissionSetAssignment', 'PermissionSetGroup', 'PermissionSetGroupComponent',
    'PermissionSetLicense', 'PermissionSetLicenseAssign', 'PermissionSetPortalDelegate',
    'PermissionSetTabSetting', 'PicklistValueInfo', 'PlatformAction', 'PlatformCachePartition',
    'PlatformCachePartitionType', 'PlatformEventChannel', 'PlatformEventChannelMember',
    'PlatformStatusAlertEvent', 'PostTemplate', 'ProcessDefinition', 'ProcessInstance',
    'ProcessInstanceNode', 'ProcessInstanceStep', 'ProcessInstanceWorkitem', 'ProcessNode',
    'ProductConsumptionSchedule', 'Profile', 'ProfileLayout', 'Prompt', 'PromptAction',
    'PromptVersion', 'Publisher', 'PushTopic', 'PushUpgradeExcludedOrg', 'QueryResult',
    'QueueSobject', 'QuickActionDefinition', 'QuickActionList', 'QuickActionListItem',
    'QuickText', 'QuickTextUsage', 'RecentlyViewed', 'Recommendation', 'RecommendationStrategy',
    'RecordAction', 'RecordActionDeployment', 'RecordType', 'RelationshipDomain',
    'RelationshipInfo', 'RemoteProxy', 'Report', 'ReportEvent', 'ReportEventStream',
    'ReputationLevel', 'ReputationPointsRule', 'S2XEventMap', 'SamlSsoConfig', 'SandboxInfo',
    'SandboxProcess', 'Scontrol', 'SearchActivity', 'SearchLayout', 'SearchPromotionRule',
    'SecureAgent', 'SecureAgentPlugin', 'SecureAgentPluginProperty', 'SecureAgentsCluster',
    'SecurityCustomBaseline', 'SecurityHealthCheck', 'SecurityHealthCheckRisks',
    'ServiceFieldDataType', 'SessionPermSetActivation', 'SetupAuditTrail', 'SetupEntityAccess',
    'Site', 'SiteDetail', 'SiteIframeWhiteListUrl', 'SOQLResult', 'SolutionStatus',
    'SourceMember', 'Stamp', 'StampAssignment', 'StandardAction', 'StandardValueSet',
    'StaticResource', 'StreamingChannel', 'SubscriberPackage', 'SubscriberPackageVersion',
    'SubscriberPackageVersionUninstallRequest', 'SymbolTable', 'TabDefinition', 'TaskPriority',
    'TaskStatus', 'TenantUsageEntitlement', 'TestSuiteMembership', 'ThirdPartyAccountLink',
    'TimeSheetTemplate', 'TraceFlag', 'TransactionSecurityPolicy', 'TwoFactorInfo',
    'TwoFactorMethodsInfo', 'TwoFactorTempCode', 'UriEvent', 'UriEventStream', 'User',
    'UserAppInfo', 'UserAppMenuCustomization', 'UserAppMenuItem', 'UserCriteria',
    'UserCustomBadge', 'UserEmailPreferredPerson', 'UserEntityAccess', 'UserFieldAccess',
    'UserLicense', 'UserListView', 'UserListViewCriterion', 'UserLogin', 'UserPackageLicense',
    'UserPermissionAccess', 'UserPreference', 'UserProvAccount', 'UserProvAccountStaging',
    'UserProvisioningConfig', 'UserProvisioningLog', 'UserProvisioningRequest',
    'UserProvMockTarget', 'UserRecordAccess', 'ValidationRule', 'VisualforceAccessMetrics',
    'WebLink', 'WorkflowAlert', 'WorkflowFieldUpdate', 'WorkflowOutboundMessage',
    'WorkflowRule', 'WorkflowTask', 'WorkSkillRouting', 'WorkSkillRoutingAttribute' };

    public static Boolean isSetupSObject(String sObjectType){
        if (sObjectType == null) { return false; }

        return SETUP_OBJECTS.contains(sObjectType);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String,Object>> getObjectInfo(String objectApiName) {
        Map<String, Map<String,Object>> fieldsMap = new Map<String, Map<String,Object>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType != null) {
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            for (Schema.SObjectField field : objDescribe.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                fieldsMap.put(
                    fieldDescribe.getName(), 
                    new Map<String,Object>{
                        'Label' => fieldDescribe.getLabel(), 
                        'Permissionable' => fieldDescribe.isPermissionable(),
                        'Type' => fieldDescribe.getType()
                    }
                );
            }
        }
        return fieldsMap;
    }

    @AuraEnabled
    public static String getIconName(String sObjectName){
        String u;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return u;
    }

    @AuraEnabled
    public static void saveFieldPermissions(String fieldPermissions) {

        System.debug('perms: ' + fieldPermissions);
        List<FieldPermissions> fieldPermissionsToUpsert = new List<FieldPermissions>();
        List<ObjectPermissions> objectPermissionsToUpsert = new List<ObjectPermissions>();

        PermissionsWrapper permissionsList = (PermissionsWrapper) JSON.deserialize(fieldPermissions, PermissionsWrapper.class);
        
        for (FieldPerm permission : permissionsList.fieldPermissions) {

            /*String fieldApiName = (String) permissionMap.get('fieldApiName');
            String permSet = (String) permissionMap.get('permSet');
            Boolean read = (Boolean) permissionMap.get('read');
            Boolean edit = (Boolean) permissionMap.get('edit');
            String objType = (String) permissionMap.get('objType');
            */

            // Create or update FieldPermissions__c records based on the draftValues
            FieldPermissions fieldPermission = new FieldPermissions(
                Field = permission.fieldApiName,
                ParentId = permission.permSet,
                PermissionsEdit = permission.edit,
                PermissionsRead = permission.read,
                SobjectType = permission.objType
            );

            fieldPermissionsToUpsert.add(fieldPermission);
        }

        Set<String> objectTypes = new Set<String>();
        
        for (ObjectPerm permission : permissionsList.objectPermissions) {
            objectTypes.add(permission.objType);
        }


        List<ObjectPermissions> objPermsList = [SELECT ]

        for (ObjectPerm permission : permissionsList.objectPermissions) {

            /*String fieldApiName = (String) permissionMap.get('fieldApiName');
            String permSet = (String) permissionMap.get('permSet');
            Boolean read = (Boolean) permissionMap.get('read');
            Boolean edit = (Boolean) permissionMap.get('edit');
            String objType = (String) permissionMap.get('objType');
            */

            // Create or update FieldPermissions__c records based on the draftValues
            ObjectPermissions objPermission = new ObjectPermissions(
                Id = 
                ParentId = permission.permSet,
                SobjectType = permission.objType,
                PermissionsEdit = permission.edit,
                PermissionsRead = permission.read,
                PermissionsCreate = permission.create,
                PermissionsDelete = permission.del,
                PermissionsViewAllRecords = permission.viewAll,
                PermissionsModifyAllRecords = permission.modifyAll
            );

            objectPermissionsToUpsert.add(objPermission);
        }
        upsert fieldPermissionsToUpsert;
        upsert objectPermissionsToUpsert;
    }
    
    public class PermissionsWrapper {
        @AuraEnabled 
        public List<FieldPerm> fieldPermissions {get; set;}
        @AuraEnabled 
        public List<ObjectPerm> objectPermissions {get; set;}
    }

        public class FieldPerm {
            @AuraEnabled
            public String fieldApiName { get; set; }
            @AuraEnabled
            public Boolean read { get; set; }
            @AuraEnabled
            public Boolean edit { get; set; }
            @AuraEnabled
            public String objType { get; set; }
            @AuraEnabled
            public String permSet { get; set; }
        }

        public class ObjectPerm {
            @AuraEnabled 
            public Boolean read {get; set;}
            @AuraEnabled 
            public Boolean edit {get; set;}
            @AuraEnabled 
            public Boolean create {get; set;}
            @AuraEnabled 
            public Boolean del {get; set;}
            @AuraEnabled 
            public Boolean viewAll {get; set;}
            @AuraEnabled 
            public Boolean modifyAll {get; set;}
            @AuraEnabled
            public String objType { get; set; }
            @AuraEnabled
            public String permSet { get; set; }
        }

        /*public PermissionsWrapper(String fieldApiName, String permSet, Boolean read, Boolean edit, String objType) {
            this.fieldApiName = fieldApiName;
            this.permSet = permSet;
            this.read = read;
            this.edit = edit;
            this.objType = objType;
        }*/
}