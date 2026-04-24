# Extrait depuis RP-05-ANDREO-Vincent.docx
# Contexte: 3.2.2 Configuration des GPOs via PowerShell

# ===== PRÉREQUIS : Module GroupPolicy =====
Import-Module GroupPolicy
Import-Module ActiveDirectory

# Variable du domaine
$DomainName = "iris-nice.local"
$DomainDN   = "DC=iris-nice,DC=local"

# ===== GPO 1 — POLITIQUE DE MOTS DE PASSE (CIS 1.1.x + ANSSI) =====
# Référence ANSSI : R31 — Politique de mots de passe robuste
# Référence CIS   : 1.1.1 à 1.1.6

$GPO1 = New-GPO -Name "GPO-SEC-PasswordPolicy" -Comment "CIS 1.1.x - ANSSI R31"
New-GPLink -Name "GPO-SEC-PasswordPolicy" -Target $DomainDN

# Configuration via Set-GPRegistryValue ou secedit
# Utilisation de secedit pour la password policy
$SecEditTemplate = @"
[System Access]
MinimumPasswordAge = 1
MaximumPasswordAge = 90
MinimumPasswordLength = 14
PasswordComplexity = 1
PasswordHistorySize = 24
ClearTextPassword = 0
"@
$SecEditTemplate | Out-File -FilePath "C:\Temp\password-policy.inf" -Encoding Unicode
secedit /configure /db C:\Temp\secedit.sdb /cfg C:\Temp\password-policy.inf /areas SECURITYPOLICY

# ===== GPO 2 — VERROUILLAGE DE COMPTE (CIS 1.2.x) =====
$SecEditLockout = @"
[System Access]
LockoutBadCount = 5
ResetLockoutCount = 15
LockoutDuration = 30
"@
$SecEditLockout | Out-File -FilePath "C:\Temp\lockout-policy.inf" -Encoding Unicode
secedit /configure /db C:\Temp\secedit.sdb /cfg C:\Temp\lockout-policy.inf /areas SECURITYPOLICY

# ===== GPO 3 — POLITIQUE D'AUDIT AVANCÉE (CIS 17.x + ANSSI R61) =====
$GPO3 = New-GPO -Name "GPO-SEC-AuditPolicy" -Comment "CIS 17.x - ANSSI R61"
New-GPLink -Name "GPO-SEC-AuditPolicy" -Target $DomainDN

# Configuration de l'audit avancé via auditpol
# CIS 17.1.1 — Audit: Account Logon — Credential Validation
auditpol /set /subcategory:"Credential Validation" /success:enable /failure:enable

# CIS 17.2 — Account Management
auditpol /set /subcategory:"Computer Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Other Account Management Events" /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable

# CIS 17.5 — Logon/Logoff
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable /failure:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable /failure:enable
auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable

# CIS 17.9 — System
auditpol /set /subcategory:"IPsec Driver" /success:enable /failure:enable
auditpol /set /subcategory:"Security State Change" /success:enable /failure:enable
auditpol /set /subcategory:"Security System Extension" /success:enable /failure:enable
auditpol /set /subcategory:"System Integrity" /success:enable /failure:enable

# CIS 17.6 — Object Access
auditpol /set /subcategory:"Removable Storage" /success:enable /failure:enable

# Vérification de la politique d'audit
auditpol /get /category:*

# ===== GPO 4 — DROITS UTILISATEUR (CIS 2.2.x) =====
$SecEditUserRights = @"
[Privilege Rights]
SeNetworkLogonRight = *S-1-5-32-544,*S-1-5-11
SeDenyNetworkLogonRight = *S-1-5-32-546,Guest
SeInteractiveLogonRight = *S-1-5-32-544
SeDenyInteractiveLogonRight = *S-1-5-32-546,Guest
SeRemoteInteractiveLogonRight = *S-1-5-32-544,*S-1-5-32-555
SeDenyRemoteInteractiveLogonRight = *S-1-5-32-546,Guest
SeShutdownPrivilege = *S-1-5-32-544
SeSystemTimePrivilege = *S-1-5-32-544,*S-1-5-19
"@
$SecEditUserRights | Out-File -FilePath "C:\Temp\userrights-policy.inf" -Encoding Unicode
secedit /configure /db C:\Temp\secedit.sdb /cfg C:\Temp\userrights-policy.inf /areas USER_RIGHTS

# ===== GPO 5 — OPTIONS DE SÉCURITÉ (CIS 2.3.x) =====
# Ces paramètres sont configurés via le registre et les modèles ADM/ADMX

# CIS 2.3.1.2 — Compte Administrateur local : statut désactivé
Set-GPRegistryValue -Name "GPO-SEC-SecurityOptions" `
    -Key "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "AutoAdminLogon" -Type DWORD -Value 0

# CIS 2.3.7.1 — Accès interactif : ne pas afficher le nom du dernier utilisateur
Set-GPRegistryValue -Name "GPO-SEC-SecurityOptions" `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "dontdisplaylastusername" -Type DWORD -Value 1

# CIS 2.3.11.7 — Niveau d'authentification LAN Manager = NTLMv2 uniquement
Set-GPRegistryValue -Name "GPO-SEC-SecurityOptions" `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" `
    -ValueName "LmCompatibilityLevel" -Type DWORD -Value 5

# CIS 2.3.11.1 — Stocker le hash LAN Manager : désactivé
Set-GPRegistryValue -Name "GPO-SEC-SecurityOptions" `
    -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" `
    -ValueName "NoLMHash" -Type DWORD -Value 1

# Forcer la mise à jour des GPOs
gpupdate /force
Invoke-GPUpdate -Computer $env:COMPUTERNAME -Force