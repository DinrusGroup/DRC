; --------------------------------------------------------------------------------------------------
;                           lsasrvd.inc Copyright The MASM32 SDK 1998-2010
; --------------------------------------------------------------------------------------------------

IFNDEF LSASRVD_INC
LSASRVD_INC equ <1>

DsRolerDcAsDc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DsRolerDcAsReplica PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DsRolerDemoteDc PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
DsRolerGetDcOperationProgress PROTO STDCALL :DWORD,:DWORD,:DWORD
DsRolerGetDcOperationResults PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaIAuditAccountLogon PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaIAuditKdcEvent PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaIAuditNotifyPackageLoad PROTO STDCALL :DWORD
LsaIAuditSamEvent PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaICallPackage PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaICallPackageEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaICallPackagePassthrough PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaICancelNotification PROTO STDCALL :DWORD
LsaIDsNotifiedObjectChange PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaIEnumerateSecrets PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaIEventNotify PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsaIFreeDomainOrgInfo PROTO STDCALL :DWORD,:DWORD
LsaIFreeForestTrustInfo PROTO STDCALL :DWORD
LsaIFreeReturnBuffer PROTO STDCALL :DWORD

LsaIFree_LSAI_PRIVATE_DATA PROTO STDCALL :DWORD
IFNDEF __UNICODE__
  LsaIFree_LSAI_PRIVATE_DAT equ <LsaIFree_LSAI_PRIVATE_DATA>
ENDIF

LsaIFree_LSAI_SECRET_ENUM_BUFFER PROTO STDCALL :DWORD,:DWORD
LsaIFree_LSAPR_ACCOUNT_ENUM_BUFFER PROTO STDCALL :DWORD
LsaIFree_LSAPR_CR_CIPHER_VALUE PROTO STDCALL :DWORD
LsaIFree_LSAPR_POLICY_DOMAIN_INFORMATION PROTO STDCALL :DWORD,:DWORD
LsaIFree_LSAPR_POLICY_INFORMATION PROTO STDCALL :DWORD,:DWORD
LsaIFree_LSAPR_PRIVILEGE_ENUM_BUFFER PROTO STDCALL :DWORD
LsaIFree_LSAPR_PRIVILEGE_SET PROTO STDCALL :DWORD
LsaIFree_LSAPR_REFERENCED_DOMAIN_LIST PROTO STDCALL :DWORD
LsaIFree_LSAPR_SR_SECURITY_DESCRIPTOR PROTO STDCALL :DWORD
LsaIFree_LSAPR_TRANSLATED_NAMES PROTO STDCALL :DWORD
LsaIFree_LSAPR_TRANSLATED_SIDS PROTO STDCALL :DWORD
LsaIFree_LSAPR_TRUSTED_DOMAIN_INFO PROTO STDCALL :DWORD,:DWORD
LsaIFree_LSAPR_TRUSTED_ENUM_BUFFER PROTO STDCALL :DWORD
LsaIFree_LSAPR_TRUSTED_ENUM_BUFFER_EX PROTO STDCALL :DWORD
LsaIFree_LSAPR_TRUST_INFORMATION PROTO STDCALL :DWORD
LsaIFree_LSAPR_UNICODE_STRING PROTO STDCALL :DWORD
LsaIFree_LSAP_SITENAME_INFO PROTO STDCALL :DWORD
LsaIFree_LSAP_SITE_INFO PROTO STDCALL :DWORD
LsaIFree_LSAP_SUBNET_INFO PROTO STDCALL :DWORD
LsaIGetBootOption PROTO STDCALL :DWORD
LsaIGetCallInfo PROTO STDCALL :DWORD
LsaIGetPrivateData PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaIGetSerialNumberPolicy2 PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsaIGetSerialNumberPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaIGetSiteName PROTO STDCALL :DWORD
LsaIHealthCheck PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsaIInitializeWellKnownSids PROTO STDCALL :DWORD
LsaIIsClassIdLsaClass PROTO STDCALL :DWORD,:DWORD
LsaIIsDsPaused PROTO STDCALL
LsaIKerberosRegisterTrustNotification PROTO STDCALL :DWORD,:DWORD
LsaILookupWellKnownName PROTO STDCALL :DWORD
LsaIOpenPolicyTrusted PROTO STDCALL :DWORD
LsaIOssAlloc PROTO STDCALL :DWORD
LsaIOssFree PROTO STDCALL :DWORD
LsaIQueryDomainOrgInfo PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaIQueryForestTrustInfo PROTO STDCALL :DWORD,:DWORD
LsaIQueryInformationPolicyTrusted PROTO STDCALL :DWORD,:DWORD
LsaIQuerySiteInfo PROTO STDCALL :DWORD
LsaIQuerySubnetInfo PROTO STDCALL :DWORD
LsaIRegisterNotification PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaIRegisterPolicyChangeNotificationCallback PROTO STDCALL :DWORD,:DWORD
LsaISafeMode PROTO STDCALL
LsaISamIndicatedDsStarted PROTO STDCALL
LsaISetBootOption PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaISetClientDnsHostName PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsaISetPrivateData PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaISetSerialNumberPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsaISetTimesSecret PROTO STDCALL :DWORD,:DWORD,:DWORD
LsaISetupWasRun PROTO STDCALL
LsaITestCall PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsaIUnregisterAllPolicyChangeNotificationCallback PROTO STDCALL :DWORD
LsaIUnregisterPolicyChangeNotificationCallback PROTO STDCALL :DWORD,:DWORD
LsaIWriteAuditEvent PROTO STDCALL :DWORD,:DWORD
LsapAuOpenSam PROTO STDCALL
LsapCheckBootMode PROTO STDCALL
LsapDsDebugInitialize PROTO STDCALL
LsapDsInitializeDsStateInfo PROTO STDCALL :DWORD
LsapDsInitializePromoteInterface PROTO STDCALL
LsapInitLsa PROTO STDCALL
LsarAddPrivilegesToAccount PROTO STDCALL :DWORD,:DWORD
LsarClose PROTO STDCALL :DWORD
LsarCreateAccount PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarCreateSecret PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarCreateTrustedDomain PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarCreateTrustedDomainEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarDelete PROTO STDCALL :DWORD
LsarEnumerateAccounts PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarEnumeratePrivileges PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarEnumeratePrivilegesAccount PROTO STDCALL :DWORD,:DWORD
LsarEnumerateTrustedDomains PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarEnumerateTrustedDomainsEx PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarGetQuotasForAccount PROTO STDCALL :DWORD,:DWORD
LsarGetSystemAccessAccount PROTO STDCALL :DWORD,:DWORD
LsarLookupNames PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarLookupPrivilegeDisplayName PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarLookupPrivilegeName PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarLookupPrivilegeValue PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarLookupSids2 PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarLookupSids PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarOpenAccount PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarOpenPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarOpenSecret PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarOpenTrustedDomain PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarOpenTrustedDomainByName PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarQueryDomainInformationPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarQueryInfoTrustedDomain PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarQueryInformationPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarQuerySecret PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LsarQuerySecurityObject PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarQueryTrustedDomainInfo PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarQueryTrustedDomainInfoByName PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
LsarRemovePrivilegesFromAccount PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetDomainInformationPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetInformationPolicy PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetInformationTrustedDomain PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetQuotasForAccount PROTO STDCALL :DWORD,:DWORD
LsarSetSecret PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetSecurityObject PROTO STDCALL :DWORD,:DWORD,:DWORD
LsarSetSystemAccessAccount PROTO STDCALL :DWORD,:DWORD
LsarSetTrustedDomainInfoByName PROTO STDCALL :DWORD,:DWORD,:DWORD,:DWORD
ServiceInit PROTO STDCALL

ELSE
  echo ------------------------------------------
  echo WARNING duplicate include file lsasrvd.inc
  echo ------------------------------------------
ENDIF
