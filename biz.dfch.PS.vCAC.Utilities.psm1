Set-Variable MODULE_NAME -Option 'Constant' -Value 'biz.dfch.PS.vCAC.Utilities';
Set-Variable MODULE_URI_BASE -Option 'Constant' -Value 'http://dfch.biz/PS/vCAC/Utilities/';
$fn = $MODULE_NAME;
$Version = New-Object System.Version(1,0,20140224,0);

Set-Variable gotoSuccess -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoSuccess' -Confirm:$false -WhatIf:$false;
Set-Variable gotoError -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoError' -Confirm:$false -WhatIf:$false;
Set-Variable gotoFailure -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoFailure' -Confirm:$false -WhatIf:$false;
Set-Variable gotoNotFound -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoNotFound' -Confirm:$false -WhatIf:$false;

$regexVcacCriticalSection = "^VcacCriticalSection;\ '(?<Name>[^']+)':\ '(?<Description>[^']*)'\ \[(?<HostInstanceId>[^\]]+)\]";

# Load module configuration file
# As (Get-Module $MODULE_NAME).ModuleBase does not return the module path during 
# module load we resort to searching the whole PSModulePath. Configuration file 
# is loaded on a first match basis.
$mvar = $MODULE_NAME.Replace('.', '_');
foreach($var in $ENV:PSModulePath.Split(';')){ 
	[string] $ModuleDirectoryBase = Join-Path -Path $var -ChildPath $MODULE_NAME;
	[string] $ModuleConfigFile = '{0}.xml' -f $MODULE_NAME;
	[string] $ModuleConfigurationPathAndFile = Join-Path -Path $ModuleDirectoryBase -ChildPath $ModuleConfigFile;
	if($true -eq (Test-Path -Path $ModuleConfigurationPathAndFile)) {
		if($true -ne (Test-Path variable:$($mvar))) {
			Log-Debug $fn ("Loading module configuration file from: '{0}' ..." -f $ModuleConfigurationPathAndFile);
			Set-Variable -Name $mvar -Value (Import-Clixml -Path $ModuleConfigurationPathAndFile) -Description "The array contains the public configuration properties of the module '$MODULE_NAME'.`n$MODULE_URI_BASE" ;
			break;
		} # if()
	} # if()
} # for()
if($true -ne (Test-Path variable:$($mvar))) {
	Write-Error "Could not find module configuration file '$ModuleConfigFile' in 'ENV:PSModulePath'.`nAborting module import...";
	break; # Aborts loading module.
} # if()
Export-ModuleMember -Variable $mvar;

[string] $ManifestFile = '{0}.psd1' -f (Get-Item $PSCommandPath).BaseName;
$ManifestPathAndFile = Join-Path -Path $PSScriptRoot -ChildPath $ManifestFile;
if( Test-Path -Path $ManifestPathAndFile)
{
	$Manifest = (Get-Content -raw $ManifestPathAndFile) | iex;
	foreach( $ScriptToProcess in $Manifest.ScriptsToProcess) 
	{ 
		$ModuleToRemove = (Get-Item (Join-Path -Path $PSScriptRoot -ChildPath $ScriptToProcess)).BaseName;
		if(Get-Module $ModuleToRemove)
		{ 
			Remove-Module $ModuleToRemove -ErrorAction:SilentlyContinue;
		}
	}
}

(Get-Variable -Name $mvar).Value.Version =  $Version; Remove-Variable Version;

if( (Get-Variable -Name $mvar).Value.ServerBaseUri.Scheme -eq 'httpS' ) { 
	(Get-Variable -Name $mvar).Value.fSecure = $true; 
} else { 
	(Get-Variable -Name $mvar).Value.fSecure = $false; 
} # if
(Get-Variable -Name $mvar).Value.ServerName = (Get-Variable -Name $mvar).Value.ServerBaseUri.DnsSafeHost; 
(Get-Variable -Name $mvar).Value.ServerUri = "{0}/{1}/{2}" -f (Get-Variable -Name $mvar).Value.ServerBaseUri.AbsoluteUri.Trim('/'), (Get-Variable -Name $mvar).Value.BaseUrl.Trim('/'), (Get-Variable -Name $mvar).Value.ManagementModelEntities.Trim('/');
Add-Type -AssemblyName System.Net;
Add-Type -AssemblyName System.Web.Extensions;

try {
$Path = $ExecutionContext.InvokeCommand.ExpandString((Get-Variable -Name $mvar).Value.DynamicOpsCoreCommon);
Log-Debug $fn ("Loading DynamicOpsCoreCommon '{0}' ..." -f $Path);
Add-Type -Path $Path -ErrorAction:SilentlyContinue;
} # try
catch {
	$ErrorText += (($_ | fl * -Force) | Out-String);
	$ErrorText += (($_.Exception | fl * -Force) | Out-String);
	$ErrorText += (Get-PSCallStack | Out-String);
	Log-Warning $fn ("Loading DynamicOpsCoreCommon '{0}' FAILED. [{1}]" -f $Path, $ErrorText);
	Remove-Variable ErrorText;
} # catch
try {
$Path = $ExecutionContext.InvokeCommand.ExpandString((Get-Variable -Name $mvar).Value.DynamicOpsCommon);
Log-Debug $fn ("Loading DynamicOpsCommon '{0}' ..." -f $Path);
Add-Type -Path $Path -ErrorAction:SilentlyContinue;
} # try
catch {
	$ErrorText += (($_ | fl * -Force) | Out-String);
	$ErrorText += (($_.Exception | fl * -Force) | Out-String);
	$ErrorText += (Get-PSCallStack | Out-String);
	Log-Warning $fn ("Loading DynamicOpsCommon '{0}' FAILED. [{1}]" -f $Path, $ErrorText);
	Remove-Variable ErrorText;
} # catch
try {
$Path = $ExecutionContext.InvokeCommand.ExpandString((Get-Variable -Name $mvar).Value.ManagementModelCommon);
Log-Debug $fn ("Loading ManagementModelCommon '{0}' ..." -f $Path);
Add-Type -Path $Path -ErrorAction:SilentlyContinue;
} # try
catch {
	$ErrorText += (($_ | fl * -Force) | Out-String);
	$ErrorText += (($_.Exception | fl * -Force) | Out-String);
	$ErrorText += (Get-PSCallStack | Out-String);
	Log-Warning $fn ("Loading ManagementModelCommon '{0}' FAILED. [{1}]" -f $Path, $ErrorText);
	Remove-Variable ErrorText;
} # catch
try {
$Path = $ExecutionContext.InvokeCommand.ExpandString((Get-Variable -Name $mvar).Value.ManagementModelClient);
Log-Debug $fn ("Loading ManagementModelClient '{0}' ..." -f $Path);
Add-Type -Path $Path -ErrorAction:SilentlyContinue;
} # try
catch {
	$ErrorText += (($_ | fl * -Force) | Out-String);
	$ErrorText += (($_.Exception | fl * -Force) | Out-String);
	$ErrorText += (Get-PSCallStack | Out-String);
	Log-Warning $fn ("Loading ManagementModelClient '{0}' FAILED. [{1}]" -f $Path, $ErrorText);
	Remove-Variable ErrorText;
} # catch

#Set-SslSecurityPolicy -TrustAllCertificates -Confirm:$false;
Log-Debug $fn ("Creating ManagementModelClient for '{0}' ..." -f (Get-Variable -Name $mvar).Value.ServerUri);
$m = New-Object -Type DynamicOps.ManagementModel.ManagementModelEntities -ArgumentList (Get-Variable -Name $mvar).Value.ServerUri;
$m.Credentials = [System.Net.CredentialCache]::DefaultCredentials;
(Get-Variable -Name $mvar).Value.MgmtContext = $m;

# Load Metadata for ManagementModelEntities.svc
try {
	if( ($m.Credentials -is [System.Net.NetworkCredential]) -Or !$m.Credentials.Username) {
		Log-Debug $fn ("Loading Metadata '{0}' [{1}] ..." -f $m.GetMetadataUri().AbsoluteUri, $m.Credentials.GetType().FullName);
		[xml] (Get-Variable -Name $mvar).Value.Metadata = Invoke-RestMethod $m.GetMetadataUri() -UseDefaultCredentials;
	} else {
		Log-Debug $fn ("Loading Metadata '{0}' [{1}] ..." -f $m.GetMetadataUri().AbsoluteUri, $m.Credentials.Username);
		[xml] (Get-Variable -Name $mvar).Value.Metadata = Invoke-RestMethod $m.GetMetadataUri() -Credential $m.Credentials;
	} # if
	Log-Debug $fn ("Loading Metadata '{0}' SUCCEEDED." -f $m.GetMetadataUri().AbsoluteUri);
} # try
catch {
	$msg = ("Loading Metadata '{0}' FAILED." -f $m.GetMetadataUri().AbsoluteUri);
	Log-Critical $fn $msg;
	$e = New-CustomErrorRecord -msg $msg -cat OperationStopped -o $m.GetMetadataUri()
	$PSCmdlet.ThrowTerminatingError($e);
} # catch

$null = Remove-Variable m;
$null = Remove-Variable mvar;

function Set-VcacPropertyDefinitionOdata {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Set-VcacPropertyDefinitionOdata/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias("pd")]
	[Alias("n")]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[Alias("a")]
	[Alias("an")]
	[string] $AttributeName
	,
	[ValidateSet("ValueList", "Relationship", "ValueExpression", "OrderIndex", 'HelpText')]
	[Parameter(Mandatory = $true, Position = 2)]
	[Alias("t")]
	[Alias("at")]
	[string] $AttributeType
	,
	[Parameter(Mandatory = $true, Position = 3)]
	[Alias("c")]
	[string] $Content
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name: '{0}'. AttributeName: '{1}'" -f $Name, $AttributeName) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	#. C:\data\scripts\vcacscripts\scripts\DynamicOpsRestFunctions.ps1

	$q = '/PropertyDefinitions()?{0}$expand=PropertyValues,ControlType,PropertyAttributes,PropertyDefinitionSet'
	$f = "`$filter=PropertyName eq '{0}'&" -f $Name;
	$pd = Get-VcacData ($q -f $f)
	if(!$pd) { 
		$msg = "Updating vCAC Property Defintion '{0}' [{1}/{2}] FAILED. Property Definition not found." -f $Name, $AttributeName, $AttributeType;
		Log-Error $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat ObjectNotFound -o $Name;
		throw($gotoError);
	}

	#$pa = $pd.PropertyAttributes | ? ( (PropertyAttributeTypeName -eq $AttributeType) -and (AttributeName -eq $AttributeName) );
	$fReturn = $false; 
	foreach($pa in $pd.PropertyAttributes) { if( ($pa.PropertyAttributeTypeName -eq $AttributeType) -and ($pa.AttributeName -eq $AttributeName) ) { $fReturn = $true; break; } }
	if(!$pa -or !$fReturn) { 
		$msg = "Updating vCAC Property Defintion '{0}' [{1}/{2}] FAILED. Attribute name and type not found." -f $Name, $AttributeName, $AttributeType;
		Log-Error $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat ObjectNotFound -o ("'{0}': '{1}'" -f $AttributeName, $AttributeType);
		throw($gotoError);
	}
	#$pa.AttributeName = "tralala";
	#$pa.AttributeValue = "tralala";
	$pa.AttributeValue = $Content;

	$fReturn = Set-VcacData $pa.'__metadata'.uri (ConvertTo-Json $pa);

	if(!$fReturn) {
		$msg = "Updating vCAC Property Defintion '{0}' [{1}/{2}] FAILED." -f $Name, $AttributeName, $AttributeType;
		Log-Error $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat WriteError -o $pa;
		throw($gotoError);
	} # if
	$fReturn = $True;
	$OutputParameter = $fReturn;

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} elseif($gotoNotFound -eq $_.Exception.Message) {
		$fReturn = $false;
		$OutputParameter = $null;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # Get-Data
#Export-ModuleMember -Function Set-VcacPropertyDefinition;

function Get-VcacPropertyDefinitionOdata {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Get-VcacPropertyDefinitionOdata/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias("pd")]
	[Alias("n")]
	[string] $Name
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name: '{0}'" -f $Name) -fac 1;
} # BEGIN

PROCESS {
[boolean] $fReturn = $false;
$OutputParameter = $null;

try {
	# Parameter validation
	# N/A

	$q = '/PropertyDefinitions()?{0}$expand=PropertyValues,ControlType,PropertyAttributes,PropertyDefinitionSet'
	$f = "`$filter=PropertyName eq '{0}'&" -f $Name;
	$pd = Get-VcacData ($q -f $f)
	if(!$pd) { 
		$msg = "Updating vCAC Property Defintion '{0}' [{1}/{2}] FAILED. Property Definition not found." -f $Name, $AttributeName, $AttributeType;
		Log-Error $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat ObjectNotFound -o $Name;
		throw($gotoError);
	}

	$OutputParameter = $pd;
	$fReturn = $True;

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} elseif($gotoNotFound -eq $_.Exception.Message) {
		$fReturn = $false;
		$OutputParameter = $null;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally
return $OutputParameter;
} # PROCESS


END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg "RET. fReturn: [$fReturn]. Execution time: [$(($datEnd - $datBegin).TotalMilliseconds)]ms. Started: [$($datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'))]." -fac 2;
} # END

} # Get-Data
#Export-ModuleMember -Function Get-VcacPropertyDefinitionOdata;

function New-VcacGlobalProfile {
<#

.SYNOPSIS

Creates a new GlobalProfile (Build Profile).



.DESCRIPTION

Creates a new GlobalProfile (Build Profile).

Objects are then visible in the "Enterprise Administrator" tab under "Build Profiles".



.OUTPUTS

This Cmdlet returns a [ChangeOperationResponse] object (or an array if operating on multiple objects). On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

The name of the GlobalProfile can be either specified as a string or as an array of strings either taken as an parameter argument or from the pipeline. The description is then used for all input strings.



.PARAMETER Name

The name of the GlobalProfile/BuildProfile to create.



.PARAMETER Description

The description text of the GlobalProfile/BuildProfile to create. Used for all GlobalProfile names.



.PARAMETER m

The managementContext object representing the repository of vCAC. By default this is taken from the module configuration variable and initialised only once.



.EXAMPLE

Create a new GlobalProfile/BuildProfile with name and description. mgmtContext is taken from module configuration variable.

New-VcacGlobalProfile -Name "biz.dfch.vcac.BuildProfile1" -Description "This is my description for the GlobalProfile";



.EXAMPLE

Create a new GlobalProfile/BuildProfile with name and description. Parameters are passed via position instead of name. mgmtContext is taken from module configuration variable.

New-VcacGlobalProfile "biz.dfch.vcac.BuildProfile1" "This is my description for the GlobalProfile";



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacGlobalProfile/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacGlobalProfile/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("GlobalProfile")]
	[alias("ProfileName")]
	$Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[string] $Description
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	foreach($GlobalProfile in $Name) {
		# Check if profile exists
		if(!$GlobalProfile -is [String]) {
			$msg = "GlobalProfile: Parameter check FAILED. 'Name' is not a [String]. Aborting ...";
			$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $GlobalProfile;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if
		$gp = $m.GlobalProfiles |? ProfileName -eq $GlobalProfile;
		if($gp) {
			$msg = "GlobalProfile: Parameter check FAILED. '{0}' does already exist. Aborting ..." -f $GlobalProfile;
			$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $GlobalProfile;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if

		# Create new global profile
		$gp = New-Object DynamicOps.ManagementModel.GlobalProfile
		$gp.GlobalProfileID = [Guid]::NewGuid();
		$gp.ProfileName = $GlobalProfile;
		if($Description) { $gp.Description = $Description; }

		$r = $null;
		if($PSCmdlet.ShouldProcess($GlobalProfile)) {
			# Add Profile to Repository
			$m.AddToGlobalProfiles($gp);
			## Update Profile
			#$m.UpdateObject($gp);
			# Save repository
			$r = $m.SaveChanges();
		} # if
		if($r) {
			switch($As) {
			'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
			Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
			} # switch
			$fReturn = $true;
		} # if
	} # foreach

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name New-VcacBuildProfile -Value New-VcacGlobalProfile;
Export-ModuleMember -Function New-VcacGlobalProfile -Alias New-VcacBuildProfile;

function Remove-VcacGlobalProfile {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacGlobalProfile/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacGlobalProfile/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("GlobalProfile")]
	[alias("ProfileName")]
	$Name
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if profile exists
	foreach($GlobalProfile in $Name) {
		if(!$GlobalProfile -is [String]) {
			$msg = "GlobalProfile: Parameter check FAILED. 'Name' is not a [String]. Aborting ...";
			$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $GlobalProfile;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if
		$gp = $m.GlobalProfiles |? ProfileName -eq $GlobalProfile;
		if(!$gp) {
			$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
			$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if

		$r = $null;
		if($PSCmdlet.ShouldProcess($GlobalProfile)) {
			# Delete profile
			$m.DeleteObject($gp);
			# Save repository
			$r = $m.SaveChanges();
		} # if
		if($r) {
			switch($As) {
			'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
			Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
			} # switch
			$fReturn = $true;
		} # if
	} # foreach

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Remove-VcacBuildProfile -Value Remove-VcacGlobalProfile;
Export-ModuleMember -Function Remove-VcacGlobalProfile -Alias Remove-VcacBuildProfile;

function Set-VcacGlobalProfile {
<#

.SYNOPSIS

Changes a new GlobalProfile (Build Profile).



.DESCRIPTION

Changes a new GlobalProfile (Build Profile).

Objects are visible in the "Enterprise Administrator" tab under "Build Profiles".



.OUTPUTS

This Cmdlet returns a [ChangeOperationResponse] object (or an array if operating on multiple objects). On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

You can change the name and the description of a GlobalProfile. If not specified the new name of the GlobalProfile defaults to the existing name.



.PARAMETER Name

The name of the GlobalProfile/BuildProfile to change.



.PARAMETER NewName

The new name of the GlobalProfile/BuildProfile.



.PARAMETER Description

The description text of the GlobalProfile/BuildProfile to change.



.PARAMETER m

The managementContext object representing the repository of vCAC. By default this is taken from the module configuration variable and initialised only once.



.EXAMPLE

Changes a GlobalProfile/BuildProfile with name 'biz.dfch.vcac.BuildProfile1' to description 'new description'. mgmtContext is taken from module configuration variable.

Set-VcacGlobalProfile -Name "biz.dfch.vcac.BuildProfile1" -Description "new description";



.EXAMPLE

Changes a GlobalProfile/BuildProfile with name 'biz.dfch.vcac.BuildProfile1' to new name 'biz.dfch.vcac.BuildProfile2' . mgmtContext is taken from module configuration variable.

Set-VcacGlobalProfile -Name "biz.dfch.vcac.BuildProfile1" -Name "biz.dfch.vcac.BuildProfile2";



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Set-VcacGlobalProfile/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Set-VcacGlobalProfile/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("GlobalProfile")]
	[alias("ProfileName")]
	[string] $Name
	,
	[Parameter(Mandatory = $false)]
	[string] $NewName = $Name
	,
	[Parameter(Mandatory = $false)]
	[string] $Description
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if profile exists
	$GlobalProfile = $Name;
	if(!$GlobalProfile -is [String]) {
		$msg = "GlobalProfile: Parameter check FAILED. 'Name' is not a [String]. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $GlobalProfile;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	$gp = $m.GlobalProfiles |? ProfileName -eq $GlobalProfile;
	if(!$gp) {
		$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Prepare Update global profile
	$gp.ProfileName = $NewName;
	if($Description) { $gp.Description = $Description; }

	$r = $null;
	if($PSCmdlet.ShouldProcess( ("[{0}]: '{1}', '{2}'" -f $GlobalProfile, $NewName, $Description) )) {
		# Update Profile
		$m.UpdateObject($gp);
		# Save repository
		$r = $m.SaveChanges();
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Set-VcacBuildProfile -Value Set-VcacGlobalProfile;
Export-ModuleMember -Function Set-VcacGlobalProfile -Alias Set-VcacBuildProfile;

function Get-VcacGlobalProfile {
<#

.SYNOPSIS

Creates a new GlobalProfile (Build Profile).



.DESCRIPTION

Creates a new GlobalProfile (Build Profile).

Objects are then visible in the "Enterprise Administrator" tab under "Build Profiles".



.OUTPUTS

This Cmdlet returns a [GlobalProfile] object (or an array if operating on multiple objects). If ReturnValue is specified it reutrns an array of strings. On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

The name of the GlobalProfile can be specified as a string. The ListAvailable switch parameter returns all existing GlobalProfiles.



.PARAMETER Name

The name of the GlobalProfile/BuildProfile to return.



.PARAMETER ListAvailable

When specifying this parameter all GlobalProfiles are returned.



.PARAMETER ReturnValue

When specifying ListAvailable you can specify to either return the full objects or only the names or ids of the GlobalProfiles.



.PARAMETER m

The managementContext object representing the repository of vCAC. By default this is taken from the module configuration variable and initialised only once.



.EXAMPLE

Lists all GlobalProfile/BuildProfile. mgmtContext is taken from module configuration variable.

Get-VcacGlobalProfile -ListAvailable



.EXAMPLE

Lists all GlobalProfile/BuildProfile and returns only their names. mgmtContext is taken from module configuration variable.

Get-VcacGlobalProfile -ListAvailable -ReturnValue Name



.EXAMPLE

Gets a GlobalProfile/BuildProfile with name 'biz.dfch.vcac.BuildProfile1'. mgmtContext is taken from module configuration variable.

Get-VcacGlobalProfile -Name 'biz.dfch.vcac.BuildProfile1'



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Get-VcacGlobalProfile/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Get-VcacGlobalProfile/'
)]
Param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'n')]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("GlobalProfile")]
	[alias("ProfileName")]
	$Name
	,
	[ValidateSet('Default', 'None', 'GlobalProfileProperties', 'VirtualMachineTemplates', 'All')]
	[Parameter(Mandatory = $false, ParameterSetName  = 'n')]
	[string] $Expand = 'Default'
	,
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[alias("Registered")]
	[switch] $ListAvailable = $true
	,
	[ValidateSet('Default', 'Name', 'ID')]
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[string] $ReturnValue = 'Default'
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	if($PSCmdlet.ParameterSetName -eq 'l') {
		if($PSCmdlet.ShouldProcess("ListAvailable")) {
			$agp = $m.GlobalProfiles;
			if('Name' -eq $ReturnValue) {
				$r = $agp.ProfileName;
			} elseif('ID' -eq $ReturnValue) {
				$r = $agp.GlobalProfileID;
			} else {
				$r = $agp;
			} # if
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
			throw($gotoSuccess);
		} # if
	} else {
		# Check if profile exists
		$GlobalProfile = $Name;
		if(!$GlobalProfile -is [String]) {
			$msg = "GlobalProfile: Parameter check FAILED. 'Name' is not a [String]. Aborting ...";
			$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $GlobalProfile;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if

		$r = $null;
		if($PSCmdlet.ShouldProcess($GlobalProfile)) {
			$gp = $m.GlobalProfiles |? ProfileName -eq $GlobalProfile;
			if(!$gp) {
				$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
				$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
				Log-Error $fn $msg;
				throw($gotoError);
			} # if
			switch($Expand) {
			'VirtualMachineTemplates' { 
				$null = $m.LoadProperty($gp, 'VirtualMachineTemplates');
			}
			'GlobalProfileProperties' { 
				$null = $m.LoadProperty($gp, 'GlobalProfileProperties');
			}
			'All' { 
				$null = $m.LoadProperty($gp, 'VirtualMachineTemplates');
				$null = $m.LoadProperty($gp, 'GlobalProfileProperties');
			}
			} # switch
			$r = $gp;
		} # if
		if($r) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Get-VcacBuildProfile -Value Get-VcacGlobalProfile;
Export-ModuleMember -Function Get-VcacGlobalProfile -Alias Get-VcacBuildProfile;

function Get-VcacGlobalProfileProperty {
<#

.SYNOPSIS

Deletes a GlobalProfile Property (BuildProfile).



.DESCRIPTION

Deletes a GlobalProfile Property (BuildProfile).

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/Infrastructure/Utilities/Remove-VcacGlobalProfileProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS//Utilities/Get-VcacGlobalProfileProperty/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName  = 'n')]
	[alias("gpp")]
	[alias("n")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[alias("Registered")]
	[switch] $ListAvailable = $true
	,
	[ValidateSet('Default', 'Name', 'ID')]
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[string] $ReturnValue = 'Default'
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	if($PSCmdlet.ParameterSetName -eq 'l') {
		if($PSCmdlet.ShouldProcess("ListAvailable")) {
			$agpp = $m.GlobalProfileProperties;
			if('Name' -eq $ReturnValue) {
				$r = $agpp.PropertyName;
			} elseif('ID' -eq $ReturnValue) {
				$r = $agpp.Id;
			} else {
				$r = $agpp;
			} # if
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
			throw($gotoSuccess);
		} # if
	} else {
		# Check if property already exists
		$gpp = $m.GlobalProfileProperties |? PropertyName -eq $Name;
		if(!$gpp) {
			$msg = "GlobalProfileProperty '{0}' does not exist. Aborting ..." -f $Name;
			$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if
		$r = $gpp;
		if($r) {
			switch($As) {
			'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
			Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Get-VcacGlobalProfileProperty;

function New-VcacGlobalProfileProperty {
<#

.SYNOPSIS

Creates a GlobalProfile Property (BuildProfile).



.DESCRIPTION

Creates a GlobalProfile Property (BuildProfile).

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

This Cmdlet returns a [ChangeOperationResponse] object. On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER GlobalProfile

An existing GlobalProfile where the property should be added to.



.PARAMETER Name

Name of the GlobalProfile Property to be created.



.PARAMETER Value

Value of the GlobalProfile Property to be created.



.EXAMPLE

Create a GlobalProfileProperty with Name and Value.

New-VcacGlobalProfileProperty -GlobalProfile "biz.dfch.vcac.BuildProfile1" -Name "myGlobalProfileProperty" -Value "my Value"



.EXAMPLE

Create a GlobalProfileProperty with Name and Value. The user is prompted to enter a value for it upon blueprint request.

New-VcacGlobalProfileProperty -gp "biz.dfch.vcac.BuildProfile1" -gpp "myGlobalProfileProperty" -Value "my Value" -IsRuntime



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacGlobalProfileProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacGlobalProfileProperty/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("ProfileName")]
	[string] $GlobalProfile
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("gpp")]
	[alias("GlobalProfileProperty")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Value = [NullString]::Value
	,
	[Parameter(Mandatory = $false)]
	[alias("h")]
	[switch] $IsHidden = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("r")]
	[alias("PromptUser")]
	[switch] $IsRuntime = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("e")]
	[alias("Encrypted")]
	[switch] $IsEncrypted = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. GlobalProfile '{0}'. Name '{1}'." -f $GlobalProfile, $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	# N/A
	
	# Check if profile exists
	$gp = $null;
	try { $gp = Get-VcacGlobalProfile -GlobalProfile $GlobalProfile -Expand GlobalProfileProperties -m $m; }
	catch { }
	if(!$gp) {
		$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$gpp = $gp.GlobalProfileProperties |? PropertyName -eq $Name;
	if($gpp) {
		$msg = "GlobalProfileProperty '{0}' does already exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	$r = $null;
	if($PSCmdlet.ShouldProcess( ("[{0}]: '{1}'='{2}'" -f $GlobalProfile, $Name, $Value) )) {
		# Create GlobalProfileProperty
		$gpp =  New-Object DynamicOps.ManagementModel.GlobalProfileProperty;
		$gpp.PropertyName = $Name;
		$gpp.PropertyValue = $Value;
		$gpp.IsHidden = $IsHidden;
		$gpp.IsRuntime = $IsRuntime;
		$gpp.IsEncrypted = $IsEncrypted;

		# Add Property to Repository
		$m.AddToGlobalProfileProperties($gpp);
		# Add Property to Profile
		$m.SetLink($gpp, 'GlobalProfile', $gp);
		# Update Profile
		$m.UpdateObject($gp);
		$m.UpdateObject($gpp);
		# Save repository
		$r = $m.SaveChanges();
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
		Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
		} # switch
		$fReturn = $true;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($gp) { $null = $m.Detach($gp); }
	if($gpp) { $null = $m.Detach($gpp); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name New-VcacBuildProfileProperty -Value New-VcacGlobalProfileProperty;
Export-ModuleMember -Function New-VcacGlobalProfileProperty -Alias New-VcacBuildProfileProperty;

function Set-VcacGlobalProfileProperty {
<#

.SYNOPSIS

Creates a GlobalProfile Property (BuildProfile).



.DESCRIPTION

Creates a GlobalProfile Property (BuildProfile).

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

This Cmdlet returns a [ChangeOperationResponse] object. On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER GlobalProfile

An existing GlobalProfile where the property should be added to.



.PARAMETER Name

Name of the GlobalProfile Property to be created.



.PARAMETER Value

Value of the GlobalProfile Property to be created.



.EXAMPLE

Create a GlobalProfileProperty with Name and Value.

Set-VcacGlobalProfileProperty -GlobalProfile "biz.dfch.vcac.BuildProfile1" -Name "myGlobalProfileProperty" -Value "my Value"



.EXAMPLE

Create a GlobalProfileProperty with Name and Value. The user is prompted to enter a value for it upon blueprint request.

Set-VcacGlobalProfileProperty -gp "biz.dfch.vcac.BuildProfile1" -gpp "myGlobalProfileProperty" -Value "my Value" -IsRuntime



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Set-VcacGlobalProfileProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Set-VcacGlobalProfileProperty/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("ProfileName")]
	[string] $GlobalProfile
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("gpp")]
	[alias("GlobalProfileProperty")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[AllowEmptyString()]
	[string] $Value
	,
	[Parameter(Mandatory = $false)]
	[alias("h")]
	[switch] $IsHidden = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("r")]
	[alias("PromptUser")]
	[switch] $IsRuntime = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("e")]
	[alias("Encrypted")]
	[switch] $IsEncrypted = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. GlobalProfile '{0}'. Name '{1}'." -f $GlobalProfile, $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	# N/A
	
	# Check if profile exists
	$gp = $null;
	try { $gp = Get-VcacGlobalProfile -GlobalProfile $GlobalProfile -Expand GlobalProfileProperties -m $m; }
	catch { }
	if(!$gp) {
		$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$gpp = $gp.GlobalProfileProperties |? PropertyName -eq $Name;
	if(!$gpp) {
		$msg = "GlobalProfileProperty '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	$r = $null;
	if($PSCmdlet.ShouldProcess( ("[{0}]: '{1}'" -f $GlobalProfile, $Name) )) {
		# Update GlobalProfileProperty
		$gpp.PropertyName = $Name;
		if($Value -ne $null) { $gpp.PropertyValue = $Value; }
		if($IsHidden.IsPresent) { $gpp.IsHidden = $IsHidden; }
		if($IsHidden.IsRuntime) { $gpp.IsRuntime = $IsRuntime; }
		if($IsHidden.IsEncrypted) { $gpp.IsEncrypted = $IsEncrypted; }

		$m.UpdateObject($gpp);
		# Save repository
		$r = $m.SaveChanges();
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
		Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
		} # switch
		$fReturn = $true;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($gp) { $null = $m.Detach($gp); }
	if($gpp) { $null = $m.Detach($gpp); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Set-VcacBuildProfileProperty -Value Set-VcacGlobalProfileProperty;
Export-ModuleMember -Function Set-VcacGlobalProfileProperty -Alias Set-VcacBuildProfileProperty;

function Remove-VcacGlobalProfileProperty {
<#

.SYNOPSIS

Removes a GlobalProfile Property (BuildProfile).



.DESCRIPTION

Removes a GlobalProfile Property (BuildProfile).

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

This Cmdlet returns a [ChangeOperationResponse] object. On failure the OutputParameter contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER GlobalProfile

An existing GlobalProfile where the property should be removed from.



.PARAMETER Name

Name of the GlobalProfile Property to be removed.



.PARAMETER Value

Value of the GlobalProfile Property to be removed.



.EXAMPLE

Removes a GlobalProfileProperty.

Remove-VcacGlobalProfileProperty -GlobalProfile "biz.dfch.vcac.BuildProfile1" -Name "myGlobalProfileProperty"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacGlobalProfileProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

Requires vCAC assembly DynamicOps.ManagementModel.ManagementModelEntities.dll and related assemblies.



.RELATED

New-VcacGlobalProfile
Remove-VcacGlobalProfile
Set-VcacGlobalProfile
Get-VcacGlobalProfile
New-VcacGlobalProfileProperty
Remove-VcacGlobalProfileProperty
Set-VcacGlobalProfileProperty
Get-VcacGlobalProfileProperty
#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacGlobalProfileProperty/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("gp")]
	[alias("BuildProfile")]
	[alias("ProfileName")]
	[string] $GlobalProfile
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("gpp")]
	[alias("GlobalProfileProperty")]
	[string] $Name
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. GlobalProfile '{0}'. Name '{1}'." -f $GlobalProfile, $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	# N/A
	
	# Check if profile exists
	$gp = $null;
	try { $gp = Get-VcacGlobalProfile -GlobalProfile $GlobalProfile -Expand GlobalProfileProperties -m $m; }
	catch { }
	if(!$gp) {
		$msg = "GlobalProfile: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $GlobalProfile;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $GlobalProfile;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property exists
	$gpp = $null;
	$gpp = $gp.GlobalProfileProperties |? PropertyName -eq $Name;
	if(!$gpp) {
		$msg = "GlobalProfileProperty '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	$r = $null;
	if($PSCmdlet.ShouldProcess( ("[{0}]: '{1}'" -f $GlobalProfile, $Name) )) {
		# Remove Property from Profile
		$m.DeleteObject($gpp);
		#$m.UpdateObject($gpp);
		#$m.DeleteLink($gp, 'GlobalProfileProperties', $gpp);
		#$m.UpdateObject($gp);
		# Save repository
		$r = $m.SaveChanges();
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
		Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
		} # switch
		$fReturn = $true;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($gp) { $null = $m.Detach($gp); }
	if($gpp) { $null = $m.Detach($gpp); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Remove-VcacBuildProfileProperty -Value Remove-VcacGlobalProfileProperty;
Export-ModuleMember -Function Remove-VcacGlobalProfileProperty -Alias Remove-VcacBuildProfileProperty;

function New-VcacPropertyDefinition {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacPropertyDefinition/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacPropertyDefinition/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("n")]
	[alias("pd")]
	[alias("PropertyDefintion")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("v")]
	[string] $Value
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $DisplayName
	,
	[Parameter(Mandatory = $false, Position = 3)]
	[string] $Description
	,
	[ValidateSet('CheckBox', 'DateTimeEdit', 'DropDown', 'DropDownList', 'Integer', 'Label', 'Link', 'Notes', 'Password', 'TextBox')]
	[Parameter(Mandatory = $true, Position = 4)]
	[alias("t")]
	[string] $Type = 'TextBox'
	,
	[Parameter(Mandatory = $false)]
	[alias("h")]
	[switch] $IsHidden = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("r")]
	[alias("PromptUser")]
	[switch] $IsRuntime = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("e")]
	[alias("Encrypted")]
	[switch] $IsEncrypted = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("f")]
	[switch] $IsRequired = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$pd = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if($pd) {
		$msg = "PropertyDefinition '{0}' does already exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Create Property Definition
	$pd =  New-Object DynamicOps.ManagementModel.PropertyDefinition;
	$pd.PropertyName = $Name;
	if($Value) { $pd.PropertyValue = $Value; } else { $pd.PropertyValue = ''; }
	if($Description) { $pd.FullDescription = $Description; } else { $pd.FullDescription = ''; }
	if($DisplayName) { $pd.DisplayName = $DisplayName; } else { $pd.DisplayName = ''; }
	$pd.IsHidden = $IsHidden;
	$pd.IsRuntime = $IsRuntime;
	$pd.IsRequired = $IsRequired;
	$pd.IsEncrypted = $IsEncrypted;
	$pd.ControlTypeName = $Type;

	# Add Property to Repository
	if($PSCmdlet.ShouldProcess($Name)) {
		$m.AddToPropertyDefinitions($pd);
		# Save repository
		$r = $m.SaveChanges();

		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function New-VcacPropertyDefinition;

function Set-VcacVirtualMachineProperty {
<#

.SYNOPSIS

Sets a property on a virtual machine entity.



.DESCRIPTION

Sets a property on a virtual machine entity.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Returns a System.Data.Services.Client.DataServiceResponse object with the result of the SaveChanges() operation. As an alternative the result is returned as an JSON or XML string.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Takes a MgmtContext and a MachineId or Machine object to operate o

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER MgmtContext

A DynamicOps.ManagementModel.ManagementModelEntities representing the vCAC repository.



.PARAMETER MachineId

A vCAC machine guid in string form.



.PARAMETER Machine

A DynamicOps.ManagementModel.VirtualMachine object



.PARAMETER Name

The name of the property to be set.



.PARAMETER Value

The value to be set on the property.



.EXAMPLE

Set the property 'CurrentTask' with value 'Preparing task' on the machine spcified by id. The management context is taken from the config variable of the module.

Set-VcacVirtualMachineProperty -MachineId 43af193d-6d16-4616-986c-51f1ad685816 -Value CurrentTask -Value "Preparing task"



.EXAMPLE

Set the name of a virtual machine vm to 'server01'. The management context is explicitly specified.

Set-VcacVirtualMachineProperty -MgmtContext $m -Machine $vm -Value VirtualMachineName -Value "server01"



.LINK

Online Version: http://dfch.biz/PS/Vcac/Utilities/Set-VcacVirtualMachineProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Vcac/Utilities/Set-VcacVirtualMachineProperty/'
)]
Param (
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'id')]
	[alias("id")]
	[alias("idMachine")]
	[string] $MachineId
	,
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'o')]
	[alias("vm")]
	[Object] $Machine
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Value = [NullString]::Value
	,
	[Parameter(Mandatory = $false)]
	[alias("m")]
	$MgmtContext = $biz_dfch_PS_vCAC_Utilities.MgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. MachineId '{1}'. Machine '{2}'. Name '{3}'. ParameterSetName: '{4}'." -f ($MgmtContext -is [Object]), $MachineId, ($Machine -is [Object]), $Name, $PsCmdlet.ParameterSetName) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($MgmtContext -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "MgmtContext: Parameter validation FAILED.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $MgmtContext;
		throw($gotoError);
	} # if
	if($PSCmdlet.ParameterSetName -eq 'id') {
		$Machine = $MgmtContext.VirtualMachines |? VirtualMachineId -eq $MachineId;
	} # if
	if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
		$msg = "MachineId: Parameter validation FAILED. No machine with id '{0}' found." -f $MachineId;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $MachineId;
		throw($gotoError);
	} # if
	if( !(Get-Member -Name $Name -InputObject $Machine) ) { 
		$msg = "PropertyName '{0}': Parameter validation FAILED. No machine with id '{1}' found." -f $Name, $Machine.VirtualMachineId;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $MachineId;
		throw($gotoError);
	} # if
	
	$ValueOld = $Machine.($Name);
	Log-Debug $fn ("{0}: Changing Property '{1}' to '{2}' [{3}] ..." -f $Machine.VirtualMachineName, $Name, $Value, $ValueOld);
	$Machine.($Name) = $Value;
	$MgmtContext.UpdateObject($Machine);
	$r = $MgmtContext.SaveChanges();
	Log-Debug $fn ("{0}: Changing Property '{1}' to '{2}' [{3}] COMPLETED" -f $Machine.VirtualMachineName, $Name, $Value, $ValueOld);

	switch($As) {
	'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
	'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
	'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
	'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
	Default { $OutputParameter = $r; }
	} # switch
	$fReturn = $true;
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Set-VcacVirtualMachineProperty;

function ConvertTo-VcacArrayOfProperties {
	[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/System/Utilities/ConvertTo-VcacArrayOfProperties/'
    )]
Param(
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
	$InputObject
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias('fn')]
	[String] $FilterName = 'FilterName'
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[Alias('fv')]
	[String] $FilterValue = 'FilterValue'
	,
	[Parameter(Mandatory = $false, Position = 3)]
	[Alias('val')]
	[String] $Value = 'Value'
	)

BEGIN {
	
	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. FilterName: '{0}'. FilterValue: '{1}'. Value: '{2}'" -f $FilterName, $FilterValue, $Value) -fac 1;
	[Boolean] $fReturn = $false;
	# Return values are always and only returned via OutputParameter.
	$OutputParameter = $null;
	
	$IO = New-Object System.IO.StringWriter;
	$XmlWriter = New-Object System.Xml.XmlTextWriter($IO);
	$XmlWriter.Formatting = [System.Xml.Formatting]::Indented;
	$XmlWriter.Indentation = 2;
	$XmlWriter.IndentChar = " ";
	#$XmlWriter.Namespaces = $true;
	$XmlWriter.WriteStartDocument($true);
	$XmlWriter.WriteStartElement('ArrayOfPropertyValue');
	$XmlWriter.WriteAttributeString("xmlns", "xsi", "http://www.w3.org/2000/xmlns/", "http://www.w3.org/2001/XMLSchema-instance");

} # BEGIN
PROCESS {

try {

	# Parameter validation
	# N/A
	foreach($Object in $InputObject) {
		$ValueFilterName = $Object.($FilterName);
		$ValueFilterValue = $Object.($FilterValue);
		$ValueValue = $Object.($Value);
		
		if($PSCmdlet.ShouldProcess( ("FilterName: '{0}', FilterValue: '{1}'. Value: '{2}'" -f $FilterName, $FilterValue, $Value) )) {
			$XmlWriter.WriteStartElement('PropertyValue');
				if($ValueFilterName) {
					$XmlWriter.WriteElementString('FilterName', $ValueFilterName);
				} else {
					$XmlWriter.WriteElementString('FilterName', $FilterName);
				} # if
				$XmlWriter.WriteElementString('FilterValue', $ValueFilterValue);
				$XmlWriter.WriteElementString('Value', $ValueValue);
			$XmlWriter.WriteEndElement();
		} # if
	} # foreach
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -eq $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				throw($_);
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up

} # finally

} # PROCESS

END {
	$XmlWriter.WriteEndElement();
	$XmlWriter.WriteEndDocument();
	$XmlWriter.Flush();
	$XmlWriter.Close();
	$fReturn = $true;
	$OutputParameter = $IO.ToString().Replace('encoding="utf-16"', 'encoding="utf-8"');
	$XmlWriter.Dispose();
	$IO.Dispose();
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
	return $OutputParameter;
} # END

} # ConvertTo-VcacArrayOfProperties
Export-ModuleMember -Function ConvertTo-VcacArrayOfProperties;

function Remove-VcacPropertyDefinition {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacPropertyDefinition/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacPropertyDefinition/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
	[alias("PropertyName")]
	[alias("PropertyDefinition")]
	$Name
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
	,
	[Parameter(Mandatory = $false)]
	[alias("Recurse")]
	[switch] $Force = $false
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	
	foreach($PropertyName in $Name) {

		# Check if property already exists
		$pd = $m.PropertyDefinitions |? PropertyName -eq $PropertyName;
		if(!$pd) {
			$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $PropertyName;
			$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $PropertyName;
			Log-Error $fn $msg;
			throw($gotoError);
		} # if

		$r = $null;
		if($PSCmdlet.ShouldProcess($PropertyName)) {
			$null = $m.LoadProperty($pd, 'PropertyAttributes');
			if($pd.PropertyAttributes.Count -ne 0) {
				if(!$Force) {
					$msg = "PropertyDefinition '{0}' has linked PropertyAttributes and cannot be deleted. Delete PropertyAttributes first or use '-Force' switch. Aborting ..." -f $PropertyName;
					$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $PropertyName;
					Log-Error $fn $msg;
					throw($gotoError);
					$r = $null;
				} # if
				foreach($pda in $pd.PropertyAttributes) {
					Log-Debug $fn ("Deleting property definition attribute: '{0}\{1}' ..." -f $pd.PropertyName, $pda.AttributeName);
					$m.DeleteObject($pda);
					$r = $m.SaveChanges();
					Log-Debug $fn ("Deleting property definition attribute: '{0}\{1}' SUCCEEDED." -f $pd.PropertyName, $pda.AttributeName);
					if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; }
				} # foreach
			} # if
			# Delete PropertyName
			$m.DeleteObject($pd);
			# Save repository
			$r = $m.SaveChanges();
		} # if
		if($r) {
			switch($As) {
			'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
			Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
			} # switch
			$fReturn = $true;
		} # if
	} # foreach
		
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($pd) { $null = $m.Detach($pd); }

} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Remove-VcacPropertyDefinition;

function Get-VcacPropertyDefinition {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Get-VcacPropertyDefinition/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Get-VcacPropertyDefinition/'
)]
Param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, ParameterSetName = 'n')]
	[alias("ProfileName")]
	[alias("ProfileDefintion")]
	$Name
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('Default', 'None', 'PropertyAttributes', 'PropertyValues', 'ControlInstances', 'All')]
	[Parameter(Mandatory = $false, ParameterSetName  = 'n')]
	[string] $Expand = 'Default'
	,
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[alias("Registered")]
	[switch] $ListAvailable = $true
	,
	[ValidateSet('Default', 'Name', 'ID')]
	[Parameter(Mandatory = $false, ParameterSetName  = 'l')]
	[string] $ReturnValue = 'Default'
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	if($PSCmdlet.ParameterSetName -eq 'l') {
		if($PSCmdlet.ShouldProcess("ListAvailable")) {
			$apd = $m.PropertyDefinitions;
			if('Name' -eq $ReturnValue) {
				$r = $apd.PropertyName;
			} elseif('ID' -eq $ReturnValue) {
				$r = $apd.Id;
			} else {
				$r = $apd;
			} # if
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
			throw($gotoSuccess);
		} # if
	} else {
		foreach($PropertyName in $Name) {
			if($PSCmdlet.ShouldProcess($PropertyName)) {
				# Check if property already exists
				$pd = $m.PropertyDefinitions |? PropertyName -eq $PropertyName;
				if(!$pd) {
					$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $PropertyName;
					$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $PropertyName;
					Log-Error $fn $msg;
					throw($gotoError);
				} # if
				switch($Expand) {
				'PropertyAttributes' { 
					$null = $m.LoadProperty($pd, 'PropertyAttributes');
				}
				'PropertyValues' { 
					$null = $m.LoadProperty($pd, 'PropertyValues');
				}
				'ControlInstances' { 
					$null = $m.LoadProperty($pd, 'ControlInstances');
				}
				'All' { 
					$null = $m.LoadProperty($pd, 'PropertyAttributes');
					$null = $m.LoadProperty($pd, 'PropertyValues');
					$null = $m.LoadProperty($pd, 'ControlInstances');
				}
				} # switch
				$r = $pd;
				if($r) {
					switch($As) {
					'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
					'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
					'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
					'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
					Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
					} # switch
					$fReturn = $true;
				} # if
			} # if
		} # foreach
	} # if
		
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Get-VcacPropertyDefinition;

function Set-VcacPropertyDefinition {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Set-VcacPropertyDefinition/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Set-VcacPropertyDefinition/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("n")]
	[alias("pd")]
	[alias("PropertyDefintion")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("v")]
	[string] $Value
	,
	[Parameter(Mandatory = $false)]
	[string] $NewName = $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $DisplayName
	,
	[Parameter(Mandatory = $false, Position = 3)]
	[string] $Description
	,
	[ValidateSet('CheckBox', 'DateTimeEdit', 'DropDown', 'DropDownList', 'Integer', 'Label', 'Link', 'Notes', 'Password', 'TextBox')]
	[Parameter(Mandatory = $false, Position = 4)]
	[alias("t")]
	[string] $Type = [NullString]::Value
	,
	[Parameter(Mandatory = $false)]
	[alias("h")]
	[switch] $IsHidden
	,
	[Parameter(Mandatory = $false)]
	[alias("r")]
	[alias("PromptUser")]
	[switch] $IsRuntime
	,
	[Parameter(Mandatory = $false)]
	[alias("e")]
	[alias("Encrypted")]
	[switch] $IsEncrypted
	,
	[Parameter(Mandatory = $false)]
	[alias("f")]
	[switch] $IsRequired
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$pd = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if(!$pd) {
		$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Update Proprety Definition
	if($PSBoundParameters.ContainsKey('NewName')) { $pd.PropertyName = $NewName; }
	if($PSBoundParameters.ContainsKey('Value')) { $pd.PropertyValue = $Value; }
	if($PSBoundParameters.ContainsKey('Description')) { $pd.FullDescription = $Description; }
	if($PSBoundParameters.ContainsKey('DisplayName')) { $pd.DisplayName = $DisplayName; }
	if($PSBoundParameters.ContainsKey('IsHidden')) { $pd.IsHidden = $IsHidden; }
	if($PSBoundParameters.ContainsKey('IsRuntime')) { $pd.IsRuntime = $IsRuntime; }
	if($PSBoundParameters.ContainsKey('IsRequired')) { $pd.IsRequired = $IsRequired; }
	if($PSBoundParameters.ContainsKey('IsEncrypted')) { $pd.IsEncrypted = $IsEncrypted; }
	if($PSBoundParameters.ContainsKey('Type')) { $pd.ControlTypeName = $Type; }

	# Add Property to Repository
	if($PSCmdlet.ShouldProcess($Name)) {
		$m.UpdateObject($pd);
		# Save repository
		$r = $m.SaveChanges();

		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($pd) { $null = $m.Detach($pd); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Set-VcacPropertyDefinition;

function New-VcacPropertyDefinitionAttribute {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacPropertyDefinitionAttribute/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacPropertyDefinitionAttribute/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("n")]
	[alias("pd")]
	[alias("PropertyDefintion")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[Alias("a")]
	[Alias("an")]
	[string] $AttributeName = $AttributeType
	,
	[Parameter(Mandatory = $true, Position = 2)]
	[Alias("av")]
	[Alias("AttributeValue")]
	[string] $Value
	,
	[ValidateSet("ValueList", "Relationship", "ValueExpression", "OrderIndex", 'HelpText')]
	[Parameter(Mandatory = $true, Position = 3)]
	[Alias("t")]
	[Alias("at")]
	[Alias("Type")]
	[string] $AttributeType
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$pd = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if(!$pd) {
		$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$null = $m.LoadProperty($pd, 'PropertyAttributes');
	$pa = $pd.PropertyAttributes |? AttributeName -eq $AttributeName;
	if($pa) {
		$msg = "PropertyAttribute '{0}' in PropertyDefinition '{1}' does already exist. Aborting ..." -f $AttributeName, $Name;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $AttributeName;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Create Property Definition Attribute
	$pa = New-Object DynamicOps.ManagementModel.PropertyAttribute;
	$pa.AttributeName = $AttributeName;
	$pa.AttributeValue = $Value;
	$pa.PropertyAttributeTypeName = $AttributeType;

	# Add PropertyAttribute to Repository
	if($PSCmdlet.ShouldProcess($AttributeName)) {
		$m.AddToPropertyAttributes($pa);
		$m.SetLink($pa, 'PropertyDefinition', $pd)
		$m.UpdateObject($pa);
		# Save repository
		$r = $m.SaveChanges();
		if($r) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($pd) { $null = $m.Detach($pd); }
	if($pa) { $null = $m.Detach($pa); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function New-VcacPropertyDefinitionAttribute;

function Remove-VcacPropertyDefinitionAttribute {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacPropertyDefinitionAttribute/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacPropertyDefinitionAttribute/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("n")]
	[alias("pd")]
	[alias("PropertyDefintion")]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[Alias("a")]
	[Alias("an")]
	[string] $AttributeName
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$pd = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if(!$pd) {
		$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$null = $m.LoadProperty($pd, 'PropertyAttributes');
	$pa = $pd.PropertyAttributes |? AttributeName -eq $AttributeName;
	if(!$pa) {
		$msg = "PropertyAttribute '{0}' in PropertyDefinition '{1}' does not exist. Aborting ..." -f $AttributeName, $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $AttributeName;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	if($pa.Count -gt 1) {
		$msg = "PropertyAttribute '{0}' in PropertyDefinition '{1}' exists multiple times. Cannot delete PropertyAttribute. Aborting ..." -f $AttributeName, $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $AttributeName;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	

	# Add PropertyAttribute to Repository
	if($PSCmdlet.ShouldProcess($AttributeName)) {
		# Delete profile
		$m.DeleteObject($pa);
		# Save repository
		$r = $m.SaveChanges();
		if($r) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($pd) { $null = $m.Detach($pd); }
	if($pa) { $null = $m.Detach($pa); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Remove-VcacPropertyDefinitionAttribute;

function Set-VcacVirtualMachineLinkedProperty {
<#

.SYNOPSIS

Sets a property on a virtual machine entity.



.DESCRIPTION

Sets a property on a virtual machine entity.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Returns a System.Data.Services.Client.DataServiceResponse object with the result of the SaveChanges() operation. As an alternative the result is returned as an JSON or XML string.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Takes a MgmtContext and a MachineId or Machine object to operate o

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER MgmtContext

A DynamicOps.ManagementModel.ManagementModelEntities representing the vCAC repository.



.PARAMETER MachineId

A vCAC machine guid in string form.



.PARAMETER Machine

A DynamicOps.ManagementModel.VirtualMachine object



.PARAMETER Name

The name of the property to be set.



.PARAMETER Value

The value to be set on the property.



.EXAMPLE

Set the property 'CurrentTask' with value 'Preparing task' on the machine spcified by id. The management context is taken from the config variable of the module.

Set-VcacVirtualMachineLinkedProperty -MachineId 43af193d-6d16-4616-986c-51f1ad685816 -Value CurrentTask -Value "Preparing task"



.EXAMPLE

Set the name of a virtual machine vm to 'server01'. The management context is explicitly specified.

Set-VcacVirtualMachineLinkedProperty -MgmtContext $m -Machine $vm -Value VirtualMachineName -Value "server01"



.LINK

Online Version: http://dfch.biz/PS/Vcac/Utilities/Set-VcacVirtualMachineLinkedProperty/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/Vcac/Utilities/Set-VcacVirtualMachineLinkedProperty/'
)]
Param (
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'id')]
	[alias("id")]
	[alias("idMachine")]
	[string] $MachineId
	,
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'o')]
	[alias("vm")]
	[Object] $Machine
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Value = [NullString]::Value
	,
	[Parameter(Mandatory = $false)]
	[alias("h")]
	[switch] $IsHidden = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("r")]
	[alias("PromptUser")]
	[switch] $IsRuntime = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("e")]
	[alias("Encrypted")]
	[switch] $IsEncrypted = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("m")]
	$MgmtContext = $biz_dfch_PS_vCAC_Utilities.MgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. MachineId '{1}'. Machine '{2}'. Name '{3}'. ParameterSetName: '{4}'." -f ($MgmtContext -is [Object]), $MachineId, ($Machine -is [Object]), $Name, $PsCmdlet.ParameterSetName) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($MgmtContext -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "MgmtContext: Parameter validation FAILED.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $MgmtContext;
		throw($gotoError);
	} # if
	if($PSCmdlet.ParameterSetName -eq 'id') {
		$Machine = $MgmtContext.VirtualMachines |? VirtualMachineId -eq $MachineId;
	} # if
	if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
		$msg = "MachineId: Parameter validation FAILED. No machine with id '{0}' found." -f $MachineId;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $MachineId;
		throw($gotoError);
	} # if
	
	$avmp = $MgmtContext.LoadProperty($Machine, 'VirtualMachineProperties');
	$vmp = $avmp |? PropertyName -eq $Name;
	if($vmp -isnot [DynamicOps.ManagementModel.VirtualMachineProperty]) {
		$msg = "Name: Parameter validation FAILED. Machine '{0}' has no VirtualMachineProperty '{1}' found." -f $Machine.VirtualMachineName, $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $MachineId;
		throw($gotoError);
	} # if
	if($PSCmdlet.ShouldProcess($Name)) {
		$ValueOld = $vmp.PropertyValue;
		Log-Debug $fn ("{0}: Changing Property '{1}\{2}' to '{3}' [{4}] ..." -f $Machine.VirtualMachineName, 'VirtualMachineProperties', $Name, $Value, $ValueOld);
		if($PSBoundParameters.ContainsKey('Value')) { $vmp.PropertyValue = $Value; }
		if($PSBoundParameters.ContainsKey('IsHidden')) { $vmp.IsHidden = $IsHidden; }
		if($PSBoundParameters.ContainsKey('IsRuntime')) { $vmp.IsRuntime = $IsRuntime; }
		if($PSBoundParameters.ContainsKey('IsRequired')) { $vmp.IsRequired = $IsRequired; }
		if($PSBoundParameters.ContainsKey('IsEncrypted')) { $vmp.IsEncrypted = $IsEncrypted; }
		$MgmtContext.UpdateObject($vmp);
		$r = $MgmtContext.SaveChanges();
		Log-Debug $fn ("{0}: Changing Property '{1}\{2}' to '{3}' [{4}] COMPLETED." -f $Machine.VirtualMachineName, 'VirtualMachineProperties', $Name, $Value, $ValueOld);
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($vmp) { $null = $MgmtContext.Detach($vmp); }
	#if(!$PSBoundParameters.ContainsKey('Machine')) { if($Machine) { $null = $m.Detach($Machine); } }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Set-VcacVirtualMachineCustomProperty -Value Set-VcacVirtualMachineLinkedProperty;
Export-ModuleMember -Function Set-VcacVirtualMachineLinkedProperty -Alias Set-VcacVirtualMachineCustomProperty;

function Set-VcacMachineStatus {
<#

.SYNOPSIS

Sets the CurrenTask/Status property on a virtual machine entity.



.DESCRIPTION

Sets the CurrenTask/Status property on a virtual machine entity.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Returns a System.Data.Services.Client.DataServiceResponse object with the result of the SaveChanges() operation. As an alternative the result is returned as an JSON or XML string.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Takes a MgmtContext and a MachineId or Machine object to operate o

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER MgmtContext

A DynamicOps.ManagementModel.ManagementModelEntities representing the vCAC repository.



.PARAMETER MachineId

A vCAC machine guid in string form.



.PARAMETER Machine

A DynamicOps.ManagementModel.VirtualMachine object



.PARAMETER Name

The name of the property to be set.



.PARAMETER Value

The value to be set on the property.



.EXAMPLE

Set the property 'CurrentTask' with value 'Preparing task' on the machine spcified by id. The management context is taken from the config variable of the module.

Set-VcacMachineStatus -MachineId 43af193d-6d16-4616-986c-51f1ad685816 -Value CurrentTask -Value "Preparing task"



.EXAMPLE

Set the name of a virtual machine vm to 'server01'. The management context is explicitly specified.

Set-VcacMachineStatus -MgmtContext $m -Machine $vm -Value VirtualMachineName -Value "server01"



.LINK

Online Version: http://dfch.biz/PS/Infoblox/Api/Set-VcacMachineStatus/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/Vcac/Utitilites/Set-VcacMachineStatus/'
)]
Param (
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'id')]
	[alias("id")]
	[alias("idMachine")]
	[alias("MachineID")]
	[string] $VirtualMachineID
	,
	[Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'o')]
	[alias("vm")]
	[alias("VirtualMachine")]
	[Object] $Machine
	,
	[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'id')]
	[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'o')]
	[alias("CurrentTask")]
	[alias("Status")]
	[string] $Value = [NullString]::Value
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'id')]
	[Parameter(Mandatory = $false, ParameterSetName = 'o')]
	[switch] $Clear = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("m")]
	$MgmtContext = $biz_dfch_PS_vCAC_Utilities.MgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. MachineId '{1}'. Machine '{2}'. Value '{3}'. ParameterSetName: '{4}'." -f ($MgmtContext -is [Object]), $VirtualMachineID, ($Machine -is [Object]), $Value, $PsCmdlet.ParameterSetName) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($MgmtContext -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "MgmtContext: Parameter validation FAILED.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $MgmtContext;
		throw($gotoError);
	} # if
	if($PSCmdlet.ParameterSetName -eq 'id') {
		$Machine = $MgmtContext.VirtualMachines |? VirtualMachineId -eq $MachineId;
	} # if
	if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
		$msg = "MachineId: Parameter validation FAILED. No machine with id '{0}' found." -f $MachineId;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $MachineId;
		throw($gotoError);
	} # if
	$VirtualMachineID = $Machine.VirtualMachineID;
	
	$ValueOld = $Machine.CurrentTask;
	if(!$PSCmdlet.ShouldProcess( ("{0}: Setting Property '{1}' to '{2}' [{3}] ..." -f $Machine.VirtualMachineName, 'CurrentTask', $Value, $ValueOld) )) {
		$fReturn = $false;
		$OutputParameter = $null;
	} else {
		if($Clear) { $Value = [NullString]::Value; }
		Log-Debug $fn ("{0}: Setting Property '{1}' to '{2}' [{3}] ..." -f $Machine.VirtualMachineName, 'CurrentTask', $Value, $ValueOld);
		$Machine.CurrentTask = $Value;
		$MgmtContext.UpdateObject($Machine);
		$r = $MgmtContext.SaveChanges();
		Log-Info $fn ("{0}: Setting Property '{1}' to '{2}' [{3}] SUCCEEDED." -f $Machine.VirtualMachineName, 'CurrentTask', $Value, $ValueOld);
		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Set-VcacVirtualMachineCurrentTask -Value Set-VcacMachineStatus;
Set-Alias -Name Set-VcacVirtualMachineStatus -Value Set-VcacMachineStatus;
Export-ModuleMember -Function Set-VcacMachineStatus -Alias Set-VcacVirtualMachineStatus, Set-VcacVirtualMachineCurrentTask;

function New-VcacUserLog {
<#

.SYNOPSIS

Adds a new user log / recent event entry.



.DESCRIPTION

Adds a new user log / recent event entry.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Returns a System.Data.Services.Client.DataServiceResponse object with the result of the SaveChanges() operation. As an alternative the result is returned as an JSON or XML string.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Takes a MgmtContext and a MachineId or Machine object to operate o

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER MgmtContext

A DynamicOps.ManagementModel.ManagementModelEntities representing the vCAC repository.



.PARAMETER MachineId

A vCAC machine guid in string form.



.PARAMETER Machine

A DynamicOps.ManagementModel.VirtualMachine object



.PARAMETER Name

The name of the property to be set.



.PARAMETER Value

The value to be set on the property.



.EXAMPLE

Set the property 'CurrentTask' with value 'Preparing task' on the machine spcified by id. The management context is taken from the config variable of the module.

New-VcacUserLog -MachineId 43af193d-6d16-4616-986c-51f1ad685816 -Value CurrentTask -Value "Preparing task"



.EXAMPLE

Set the name of a virtual machine vm to 'server01'. The management context is explicitly specified.

New-VcacUserLog -MgmtContext $m -Machine $vm -Value VirtualMachineName -Value "server01"



.LINK

Online Version: http://dfch.biz/PS/Infoblox/Api/New-VcacUserLog/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true
	,
    ConfirmImpact="Medium"
	,
	HelpURI='http://dfch.biz/PS/Vcac/Utitilites/New-VcacUserLog/'
	,
	DefaultParameterSetName = 'n'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'n')]
	[string] $Username
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias("idUser")]
	[int] $UserID
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("msg")]
	[string] $Message
	,
	[ValidateSet('INFO', 'WARN', 'ERROR')]
	[Parameter(Mandatory = $false)]
	$Type = "INFO"
	,
	[Parameter(Mandatory = $false)]
	$Date = [DateTime]::UtcNow
	,
	[Parameter(Mandatory = $false)]
	[alias("m")]
	$MgmtContext = $biz_dfch_PS_vCAC_Utilities.MgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. Message [{1}]." -f ($MgmtContext -is [Object]), $Message.Length) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($MgmtContext -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "MgmtContext: Parameter validation FAILED.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $MgmtContext;
		throw($gotoError);
	} # if
	
	switch($Type) {
	'WARN' { $ValueType = [DynamicOps.ManagementModel.UserLogSeverity]::Warn; }
	'ERROR' { $ValueType = [DynamicOps.ManagementModel.UserLogSeverity]::Error; }
	default { $ValueType = [DynamicOps.ManagementModel.UserLogSeverity]::Info; }
	} # switch
	if($PSCmdlet.ShouldProcess($Message)) {
		# Create a new user log object
		$ul = New-Object DynamicOps.ManagementModel.UserLog;
		$ul.Type = $ValueType;
		$ul.Timestamp = $Date;
		$ul.UserName = $Username;
		$ul.Message = $Message
		$MgmtContext.AddToUserLogs($ul);
		$r = $MgmtContext.SaveChanges();
		#Log-Info $fn ("{0}: Setting CurrentTask of '{1}' to '{2}' [{3}] ..." -f $Machine.VirtualMachineID, $Machine.VirtualMachineName, $Status, $Machine.CurrentTask);

		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name New-VcacUserLogEntry -Value New-VcacUserLog;
Export-ModuleMember -Function New-VcacUserLog -Alias New-VcacUserLogEntry;

function New-VcacControlLayout {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacControlLayout/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacControlLayout/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("ControlLayout")]
	[alias("LayoutName")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[string] $Description
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $Label
	,
	[Parameter(Mandatory = $false, Position = 3)]
	[string] $Title
	,
	[Parameter(Mandatory = $false)]
	[string] $ControlWidth
	,
	[Parameter(Mandatory = $false)]
	[string] $LabelWidth
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$cl = $m.ControlLayouts |? LayoutName -eq $Name;
	if($cl) {
		$msg = "ControlLayout '{0}' does already exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Create Property Definition
	$cl =  New-Object DynamicOps.ManagementModel.ControlLayout;
	$cl.LayoutName = $Name;
	if($Description) { $cl.FullDescription = $Description; } else { $cl.FullDescription = ''; }
	if($Label) { $cl.Label = $Label; } else { $cl.Label = ''; }
	if($Title) { $cl.Title = $Title; } else { $cl.Title = ''; }
	if($ControlWidth) { $cl.ControlWidth = $ControlWidth; } else { $cl.ControlWidth = ''; }
	if($LabelWidth) { $cl.LabelWidth = $LabelWidth; } else { $cl.LabelWidth = ''; }

	# Add Property to Repository
	if($PSCmdlet.ShouldProcess($Name)) {
		$m.AddToControlLayouts($cl);
		# Save repository
		$r = $m.SaveChanges();

		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
		Default { $OutputParameter = $r; }
		} # switch
		$fReturn = $true;
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name New-VcacPropertyLayout -Value New-VcacControlLayout;
Export-ModuleMember -Function New-VcacControlLayout -Alias New-VcacPropertyLayout;

function Remove-VcacControlLayout {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacControlLayout/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacControlLayout/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("ControlLayout")]
	[alias("LayoutName")]
	[string] $Name
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property already exists
	$cl = $m.ControlLayouts |? LayoutName -eq $Name;
	if(!$cl) {
		$msg = "ControlLayout '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if


	# Add Property to Repository
	if($PSCmdlet.ShouldProcess($Name)) {
		# Delete profile
		$m.DeleteObject($cl);
		# Save repository
		$r = $m.SaveChanges();

		if($r) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Set-Alias -Name Remove-VcacPropertyLayout -Value Remove-VcacControlLayout;
Export-ModuleMember -Function Remove-VcacControlLayout -Alias Remove-VcacPropertyLayout;

function New-VcacControlInstance {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/New-VcacControlInstance/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacControlInstance/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("LayoutName")]
	[string] $ControlLayout
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("PropertyName")]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $OrderIndex
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ControlLayout '{0}'. Name '{1}'." -f $ControlLayout, $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if control layout exists
	$cl = $m.ControlLayouts |? LayoutName -eq $ControlLayout;
	if(!$cl) {
		$msg = "ControlLayout '{0}' does not exist. Aborting ..." -f $ControlLayout;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $ControlLayout;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property definition exists
	$p = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if(!$p) {
		$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	
	# Add Property to Repository
	if($PSCmdlet.ShouldProcess($Name)) {
		# Create Control Instance
		$ci =  New-Object DynamicOps.ManagementModel.ControlInstance;
		$m.AddToControlInstances($ci);
		
		# Set orderindex
		$ci.OrderIndex = $OrderIndex;

		# link to control layout
		$ci.ControlLayoutId = $cl.Id;
		$m.SetLink($ci, 'ControlLayout', $cl);

		# link to property definition
		$ci.ControlLayoutId = $p.Id;
		$m.SetLink($ci, 'PropertyDefinition', $p);
		
		$m.UpdateObject($ci);
		$r = $m.SaveChanges();

		if($r) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
			} # switch
			$fReturn = $true;
		} # if
	} # if
	
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($ci) { $null = $m.Detach($ci); }
	if($p) { $null = $m.Detach($p); }
	if($cl) { $null = $m.Detach($cl); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function New-VcacControlInstance;

function Remove-VcacControlInstance {
<#

.SYNOPSIS

This is a short description of the Cmdlet.



.DESCRIPTION

This is a short description of the Cmdlet.

This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. This is the full description of the Cmdlet. 



.OUTPUTS

Here we describe the output of the Cmdlet. This Cmdlet returns a [String] parameter. On failure the string contains $null.

For more information about output parameters see 'help about_Functions_OutputTypeAttribute'.



.INPUTS

Here we describe the input to the Cmdlet. See PARAMETER section for a description of input parameters.

For more information about input parameters see 'help about_Functions_Advanced_Parameters'.



.PARAMETER Param1

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param2

Description of the parameter. You may be more elaborate on this.



.PARAMETER Param3

Description of the parameter. You may be more elaborate on this.



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.EXAMPLE

Here we give examples on how to use the Cmdlet in various scenarios. If your Cmdlet supports parameter sets you should give examples for each parameter set.

My-Cmdlet -Param1 "Value1" -Param2 "Value2" -Param3 "Value3"



.LINK

Online Version: http://dfch.biz/PS/vCAC/Utilities/Remove-VcacControlInstance/



.NOTES

Requires Powershell v3.

Requires module 'biz.dfch.PS.System.Logging'.

#>
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="High",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Remove-VcacControlInstance/'
)]
[OutputType([String])]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[alias("LayoutName")]
	[string] $ControlLayout
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[alias("PropertyName")]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 2)]
	[string] $OrderIndex
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	$m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ControlLayout '{0}'. Name '{1}'." -f $ControlLayout, $Name) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext does not exist. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if control layout exists
	$cl = $m.ControlLayouts |? LayoutName -eq $ControlLayout;
	if(!$cl) {
		$msg = "ControlLayout '{0}' does not exist. Aborting ..." -f $ControlLayout;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $ControlLayout;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	# Check if property definition exists
	$p = $m.PropertyDefinitions |? PropertyName -eq $Name;
	if(!$p) {
		$msg = "PropertyDefinition '{0}' does not exist. Aborting ..." -f $Name;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if
	
	# Get all control instances on this control layout
	$aci = $m.LoadProperty($cl, 'ControlInstances');
	foreach($ci in $aci) { 
		if($PSBoundParameters.ContainsKey('OrderIndex')) { 
			if($ci.OrderIndex -ne $OrderIndex) { continue; }
		} # if
		$p = $m.LoadProperty($ci, 'PropertyDefinition');
		if($ci.PropertyDefinitionId -ne $p.Id) { $null = $m.DetachObject($p); continue; }

		if($PSCmdlet.ShouldProcess($Name)) {
			$m.DeleteObject($ci);
			$r = $m.SaveChanges();
			if($r) {
				switch($As) {
				'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
				'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
				'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
				'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
				Default { $OutputParameter = $r; }
				} # switch
				$fReturn = $true;
			} # if
		} # if
		break;
	} # foreach

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($ci) { $null = $m.Detach($ci); }
	if($p) { $null = $m.Detach($p); }
	if($cl) { $null = $m.Detach($cl); }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function Remove-VcacControlInstance;

function Backup-VcacDataContext {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Backup-VcacDataContext/'
)]
[OutputType([hashtable])]
Param (
	[Parameter(Mandatory = $false, Position = 0)]
	[alias("mgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'ListAvailable')]
	[alias("Registered")]
	[switch] $ListAvailable = $false
) # Param

	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. DataContext stack size '{0}'. Tracked objects currently: Entities [{1}]. Links [{2}]." -f $biz_dfch_PS_vCAC_Utilities.DataContext.Count,  $m.Entities.Count, $m.Links.Count) -fac 1;

	$fReturn = $false;
	$OutputParameter = $null;
	if($m -is [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$e = '';
		$aE = New-Object System.Collections.ArrayList;
		foreach($e in $m.Entities) { $null = $aE.Add($e.Entity); };
		$l = '';
		$aL = New-Object System.Collections.ArrayList;
		foreach($l in $m.Links) { $null = $aL.Add($l); };

		$ht = @{};
		$ht.Links = $aL;
		$ht.Entities = $aE;
		if(!$ListAvailable) {
			$biz_dfch_PS_vCAC_Utilities.DataContext.Push($ht.Clone());
		} # if
		$OutputParameter = $ht.Clone();
		$ht.Clear();
		Remove-Variable ht;
		Remove-Variable aE;
		Remove-Variable e;
		Remove-Variable aL;
		Remove-Variable l;
	} # if
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
	return $OutputParameter;

} # function
Export-ModuleMember -Function Backup-VcacDataContext;

function Restore-VcacDataContext {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Restore-VcacDataContext/'
)]
[OutputType([Boolean])]
Param (
	[ValidateScript({$_.Count -gt 0})]
	[Parameter(Mandatory = $false, Position = 0)]
	[hashtable] $Context = $biz_dfch_PS_vCAC_Utilities.DataContext.Pop()
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[Parameter(Mandatory = $false)]
	[switch] $Clear = $false
	,
	[Parameter(Mandatory = $false)]
	[Object[]] $Exclude
) # Param

	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. DataContext stack size '{0}'. Tracked objects currently: Entities [{1}]. Links [{2}]." -f $biz_dfch_PS_vCAC_Utilities.DataContext.Count,  $m.Entities.Count, $m.Links.Count) -fac 1;
	
	if(!$Context -Or ($Context -isnot [hashtable])) { $fReturn = $false; }
	$fReturn = $false;
	$OutputParameter = $null;
	$fLinks = $false;
	$fEntities = $false;
	if($Clear) {
		foreach($e in $m.Entities) { $null = $m.Detach($e.Entity); };
		foreach($l in $m.Links) { $null = $m.DetachLink($l.Source, $l.SourceProperty, $l.Target); };
	} else {
		if( ($Context -is [hashtable]) -And ($m -is [DynamicOps.ManagementModel.ManagementModelEntities]) ) {
			if($Context.ContainsKey('Entities')) {
				$e = '';
				$aE = $Context.Entities;
				foreach($e in $m.Entities) { if(!$aE.Contains($e.Entity)) { $null = $m.Detach($e.Entity); } ; };
				$aE.Clear();
				Remove-Variable aE;
				Remove-Variable e;
				$fEntities = $true;
			} # if
			if($Context.ContainsKey('Links')) {
				$l = '';
				$aL = $Context.Links;
				foreach($l in $m.Links) { if(!$aL.Contains($l)) { $null = $m.DetachLink($l.Source, $l.SourceProperty, $l.Target); } ; };
				$aL.Clear();
				Remove-Variable aL;
				Remove-Variable l;
				$fLinks = $true;
			} # if
		} # if
	} # if
	if($fLinks -Or $fEntities) { $fReturn = $true; }
	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]. Tracked objects currently: Entities [{3}]. Links [{4}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'), $m.Entities.Count, $m.Links.Count) -fac 2;
	return $fReturn;

} # function
Export-ModuleMember -Function Restore-VcacDataContext;

function Enter-VcacCriticalSection {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Enter-VcacCriticalSection/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Name
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[string] $Description = ''
	,
	[Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'wait')]
	[ValidateRange(-1,[double]::MaxValue)]
	[double] $WaitTimeoutMillisecond = [double]::MaxValue
	,
	[Parameter(Mandatory = $false)]
	[double] $SpinTimeoutMillisecond = 1000
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'try')]
	[alias("Try")]
	[switch] $TryOnce
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'try')]
	[switch] $ReturnExisting = $false
	,
	[Parameter(Mandatory = $false)]
	[switch] $Signal = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("MgmtContext")]
	[Object] $m = $biz_dfch_PS_vCAC_Utilities.MgmtContext
) # Param

BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. Name '{1}'." -f ($m -is [Object]), $Name) -fac 1;
} # BEGIN

PROCESS {
# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	$sha1 = New-Object System.Security.Cryptography.SHA1Managed;
	$sha1.Initialize();
	$ab = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Name));
	$sha1.Dispose();
	$NameHash = [System.BitConverter]::ToString($ab).Replace('-','');
	$Description = "VcacCriticalSection; '{0}': '{1}' [{2}]" -f $Name.Replace("'", ''), $Description.Replace("'", ''), $Host.InstanceId;

	# backward compatibility, handle -1
	if($WaitTimeoutMillisecond -eq -1) { $WaitTimeoutMillisecond = [double]::MaxValue; }
	if($PSCmdlet.ParameterSetName -eq 'try') { $WaitTimeoutMillisecond = 0;	}
	$SpinTimeoutMillisecond = [Math]::Min($SpinTimeoutMillisecond, $WaitTimeoutMillisecond);
	$sw = [System.Diagnostics.Stopwatch]::StartNew();

	# Try to create lock
	$SpinTimeoutMillisecondLocal = 0;
	do {
		Start-Sleep -Milliseconds $SpinTimeoutMillisecondLocal;
		if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }

		$a = New-Object DynamicOps.ManagementModel.Announcement;
		$a.LastUpdate = $datBegin;
		$a.Name = $NameHash;
		$a.Culture = '';
		$a.Message = $Description;
		$m.AddToAnnouncements($a);
		$m.UpdateObject($a);
		try {
			Log-Debug $fn ("Creating lock '{0}' [{1}] ..." -f $Name, $NameHash);
			$r = $m.SaveChanges();
			if($r) { $OutputParameter = $true; }
			Log-Debug $fn ("Creating lock '{0}' [{1}] SUCCEEDED." -f $Name, $NameHash);
			if($Signal) { 
				$r = Exit-VcacCriticalSection -Name $Name -WaitTimeoutMillisecond $WaitTimeoutMillisecond -SpinTimeoutMillisecond $SpinTimeoutMillisecond -m $m;
				if($r) { $OutputParameter = $true; }
			} # if
			break;
		} # try
		catch {
			Log-Debug $fn ("Creating lock '{0}' [{1}] FAILED as it already exists." -f $Name, $NameHash);
			$m.DeleteObject($a);
			$r = $m.SaveChanges();
			$OutputParameter = $false;
			
			$SpinTimeoutMillisecondLocal = $SpinTimeoutMillisecond;
		} # catch
		finally {
			# $null = $m.Detach($a);
			if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
				$null = Restore-VcacDataContext;
				Remove-Variable DataContext;
			} # if
		} # finally
	} while($WaitTimeoutMillisecond -gt $sw.ElapsedMilliseconds);

	if( ($PSCmdlet.ParameterSetName -eq 'try') -And $ReturnExisting) {
		# $null = Backup-VcacDataContext;
		# $null = Restore-VcacDataContext -Clear;
		$a = $m.Announcements |? Name -eq $NameHash;
		$CriticalSection = @{};
		if(!$a) {
			$CriticalSection.Name = [string]::Empty;
			$CriticalSection.NameHash = [string]::Empty;
			$CriticalSection.Description = [string]::Empty;
			$CriticalSection.CreationDate = [datetime]::MinValue;
			$CriticalSection.HostInstanceId = [guid]::Empty;
		} else {
			# $fReturn = $a.Message -match "^VcacCriticalSection;\ '(?<Name>[^']+)':\ '(?<Description>[^']*)'\ \[(?<HostInstanceId>[^\]]+)\]";
			$fReturn = $a.Message -match $regexVcacCriticalSection;
			if(!$fReturn) {
				$CriticalSection.Name = [string]::Empty;
				$CriticalSection.NameHash = [string]::Empty;
				$CriticalSection.Description = [string]::Empty;
				$CriticalSection.CreationDate = [datetime]::MinValue;
				$CriticalSection.HostInstanceId = [guid]::Empty;
			} else {
				$CriticalSection.Name = $Matches.Name;
				$CriticalSection.NameHash = $a.Name;
				$CriticalSection.Description = $Matches.Description;
				$CriticalSection.CreationDate = $a.LastUpdate;
				$CriticalSection.HostInstanceId = ($Matches.HostInstanceId -as [guid]);
			} # if
		} # if
		$OutputParameter = $CriticalSection;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String); 
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception.InnerException -And ($_.Exception.InnerException -is [System.Data.Services.Client.DataServiceRequestException])) {
			Log-Critical $fn ("[DataServiceRequestException] Request FAILED as lock '{0}' already exists'. [{1}]." -f $Name, $_.Exception.InnerException.InnerException.Message);
			Log-Debug $fn $ErrorText -fac 3;
			$m.DeleteObject($a);
			$r = $m.SaveChanges();
		}
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
	} # if
	if($sw) {
		if($sw.IsRunning) { $sw.Reset(); }
		Remove-Variable sw;
	} # if
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END

} # function
Export-ModuleMember -Function Enter-VcacCriticalSection;

function Exit-VcacCriticalSection {
[CmdletBinding(
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Exit-VcacCriticalSection/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'name')]
	[switch] $Wait = $false
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'clear')]
	[Alias('RemoveAll')]
	[Alias('All')]
	[switch] $Clear = $false
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'clear')]
	[switch] $WhatIf = $false
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'ListAvailable')]
	[alias("Registered")]
	[switch] $ListAvailable = $false
	,
	[Parameter(Mandatory = $false)]
	[ValidateRange(-1,[double]::MaxValue)]
	[double] $WaitTimeoutMillisecond = 0
	,
	[Parameter(Mandatory = $false)]
	[Guid] $HostInstanceId
	,
	[Parameter(Mandatory = $false)]
	[double] $SpinTimeoutMillisecond = 1000
	,
	[Parameter(Mandatory = $false)]
	[alias("MgmtContext")]
	[Object] $m = $biz_dfch_PS_vCAC_Utilities.MgmtContext
) # Param

BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. Name '{1}'." -f ($m -is [Object]), $Name) -fac 1;
} # BEGIN

PROCESS {
# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	
	# Check if mgmtContext is set
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "mgmtContext: Parameter check FAILED. Parameter is not set. Aborting ...";
		$e = New-CustomErrorRecord -m $msg -cat InvalidType -o $m;
		Log-Error $fn $msg;
		throw($gotoError);
	} # if

	if($ListAvailable) { $OutputParameter = @(); }
	if( ($PSCmdlet.ParameterSetName -eq 'clear') -Or ($PSCmdlet.ParameterSetName -eq 'ListAvailable') ) {
		if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }
		
		$aa = $m.Announcements | select Name, Message, LastUpdate;
		foreach($a in $aa) { 
			# find all critical sections and extract name
			# $fReturn = $a.Message -match "^VcacCriticalSection;\ '(?<Name>[^']+)':\ "; 
			$fReturn = $a.Message -match $regexVcacCriticalSection;
			if(!$fReturn) { continue; }; 
			if($ListAvailable) {
				Log-Info $fn ("Found critical section '{0}' [{1}]. '{2}'" -f $Matches.Name, $a.Name, $a.Message);
				$OutputParameter += $Matches.Name;
			} elseif($WhatIf) {
				Log-Info $fn ("What if: Performing operation '{0}' on Target '{1}'. CreationDate '{2}'" -f $fn, $Matches.Name, $a.LastUpdate.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -v;
				$OutputParameter = $null;
			} else {
				$null = Exit-VcacCriticalSection $Matches.Name;
				$OutputParameter = $null;
			} # if
		} # foreach
		
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
		$fReturn = $true;
		throw($gotoSuccess);
	} # if

	$sha1 = New-Object System.Security.Cryptography.SHA1Managed;
	$sha1.Initialize();
	$ab = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Name));
	$NameHash = [System.BitConverter]::ToString($ab).Replace('-','');
	$sha1.Dispose();

	# backward compatibility, handle -1
	if($WaitTimeoutMillisecond -eq -1) { $WaitTimeoutMillisecond = [double]::MaxValue; }
	if($Wait -And !$PSBoundParameters.ContainsKey('WaitTimeoutMillisecond')) { $WaitTimeoutMillisecond = [double]::MaxValue; }
	$SpinTimeoutMillisecond = [Math]::Min($SpinTimeoutMillisecond, $WaitTimeoutMillisecond);
	$sw = [System.Diagnostics.Stopwatch]::StartNew();

	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }
	$SpinTimeoutMillisecondLocal = 0;
	do {
		Start-Sleep -Milliseconds $SpinTimeoutMillisecondLocal;
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
		if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }
		Log-Debug $fn ("Deleting lock '{0}' [{1}] ..." -f $Name, $NameHash);
		$a = $m.Announcements |? Name -eq $NameHash;
		if(!$a) {
			Log-Warning $fn ("Deleting lock '{0}' [{1}] FAILED as it does not exist." -f $Name, $NameHash);
			$fReturn = $false;
			$OutputParameter = $fReturn;
		} else {
			$m.DeleteObject($a);
			$r = $m.SaveChanges();
			if($r) { 
				$fReturn = $true;
				Log-Debug $fn ("Deleting lock '{0}' [{1}] SUCCEEDED." -f $Name, $NameHash);
				$OutputParameter = $r;
				break;
			} else {
				$fReturn = $false;
				Log-Debug $fn ("Deleting lock '{0}' [{1}] FAILED." -f $Name, $NameHash);
				$OutputParameter = $fReturn;
			} # if
		} # if
		$SpinTimeoutMillisecondLocal = $SpinTimeoutMillisecond;
	} while($WaitTimeoutMillisecond -gt $sw.ElapsedMilliseconds);

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String); 
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception.InnerException -And ($_.Exception.InnerException -is [System.Data.Services.Client.DataServiceRequestException])) {
			Log-Critical $fn ("[DataServiceRequestException] Request FAILED for lock '{0}'. [{1}]." -f $Name, $_.Exception.InnerException.InnerException.Message);
			Log-Debug $fn $ErrorText -fac 3;
			$m.DeleteObject($a);
			$r = $m.SaveChanges();
		}
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
	} # if
	if($sw) {
		if($sw.IsRunning) { $sw.Reset(); }
		Remove-Variable sw;
	} # if
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END

} # function
Export-ModuleMember -Function Exit-VcacCriticalSection;

function New-VcacNetworkProfile {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacNetworkProfile/'
)]
[OutputType([DynamicOps.ManagementModel.StaticIPv4NetworkProfile])]
Param (
	[Parameter(Mandatory = $false, Position = 0)]
	[Alias('Name')]
	[string] $StaticIPv4NetworkProfileName
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[IPAddress] $NetworkAddressIPv4
	,
	[Parameter(Mandatory = $true, Position = 2)]
	[Alias('SubnetMask')]
	[IPAddress] $SubnetMaskIPv4
	,
	[Parameter(Mandatory = $false)]
	[Alias('Description')]
	[string] $ProfileDescription
	,
	[Parameter(Mandatory = $false)]
	[Alias('Gateway')]
	[IPAddress] $GatewayIPv4Address
	,
	[Parameter(Mandatory = $false)]
	[Alias('DNS1')]
	[IPAddress] $PrimaryDNSIPv4Address
	,
	[Parameter(Mandatory = $false)]
	[Alias('DNS2')]
	[IPAddress] $SecondaryDNSIPv4Address
	,
	[Parameter(Mandatory = $false)]
	[Alias('Suffix')]
	[string] $DnsSuffix
	,
	[Parameter(Mandatory = $false)]
	[Alias('SearchSuffix')]
	[string] $DnsSearchSuffix
	,
	[Parameter(Mandatory = $false)]
	[Alias('WINS1')]
	[IPAddress] $PrimaryWinsIPv4Address
	,
	[Parameter(Mandatory = $false)]
	[Alias('WINS2')]
	[IPAddress] $SecondaryWinsIPv4Address
	,
	[Parameter(Mandatory = $false)]
	[alias("MgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param

BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. Name '{0}'." -f ($StaticIPv4NetworkProfileName)) -fac 1;
} # BEGIN

PROCESS {
# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	# N/A

	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }

	if(!$PSBoundParameters.ContainsKey('StaticIPv4NetworkProfileName')) { 
        $NetworkAddressIPv4Split = $NetworkAddressIPv4.IPAddressToString.Split('.');
        $NetworkAddressIPv4String = '{0}.{1}.{2}.{3}' -f ($NetworkAddressIPv4Split[0] -as [int]).ToString('000'), ($NetworkAddressIPv4Split[1] -as [int]).ToString('000'), ($NetworkAddressIPv4Split[2] -as [int]).ToString('000'), ($NetworkAddressIPv4Split[3] -as [int]).ToString('000');
        $SubnetMaskIPv4Split = $SubnetMaskIPv4.IPAddressToString.Split('.');
        $SubnetMaskIPv4String = '{0}.{1}.{2}.{3}' -f ($SubnetMaskIPv4Split[0] -as [int]).ToString('000'), ($SubnetMaskIPv4Split[1] -as [int]).ToString('000'), ($SubnetMaskIPv4Split[2] -as [int]).ToString('000'), ($SubnetMaskIPv4Split[3] -as [int]).ToString('000');
		$StaticIPv4NetworkProfileName = 'IPv4Network {0} / {1}' -f $NetworkAddressIPv4String, $SubnetMaskIPv4String;
	} # if

	$np = $m.StaticIPv4NetworkProfiles |? StaticIPv4NetworkProfileName -eq $StaticIPv4NetworkProfileName;
	if($np) {
		$msg = "StaticIPv4NetworkProfileName: Parameter check FAILED. '{0}' does already exist. Aborting ..." -f $StaticIPv4NetworkProfileName;
		Log-Critical $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat InvalidData -o $StaticIPv4NetworkProfileName;
		throw($gotoError);
	} # if

	$np = New-Object DynamicOps.ManagementModel.StaticIPv4NetworkProfile;
	$np.ID = [guid]::NewGuid();
	$np.StaticIPv4NetworkProfileName = $StaticIPv4NetworkProfileName;
	$np.SubnetMaskIPv4 = $SubnetMaskIPv4.IPAddressToString;
	$np.CreatedDate = [datetime]::UtcNow;
	$np.LastModifiedDate = [datetime]::UtcNow;
	if($PSBoundParameters.ContainsKey('ProfileDescription')) { $np.ProfileDescription = $ProfileDescription; };
	if($PSBoundParameters.ContainsKey('GatewayIPv4Address')) { $np.GatewayIPv4Address = $GatewayIPv4Address.IPAddressToString; };
	if($PSBoundParameters.ContainsKey('PrimaryDNSIPv4Address')) { $np.PrimaryDNSIPv4Address = $PrimaryDNSIPv4Address.IPAddressToString; };
	if($PSBoundParameters.ContainsKey('SecondaryDNSIPv4Address')) { $np.SecondaryDNSIPv4Address = $SecondaryDNSIPv4Address.IPAddressToString; };
	if($PSBoundParameters.ContainsKey('DnsSuffix')) { $np.DnsSuffix = $DnsSuffix; };
	if($PSBoundParameters.ContainsKey('DnsSearchSuffix')) { $np.DnsSearchSuffix = $DnsSearchSuffix; };
	if($PSBoundParameters.ContainsKey('PrimaryWinsIPv4Address')) { $np.PrimaryWinsIPv4Address = $PrimaryWinsIPv4Address.IPAddressToString; };
	if($PSBoundParameters.ContainsKey('SecondaryWinsIPv4Address')) { $np.SecondaryWinsIPv4Address = $SecondaryWinsIPv4Address.IPAddressToString; };
	if($PSCmdlet.ShouldProcess($StaticIPv4NetworkProfileName)) {
		$m.AddToStaticIPv4NetworkProfiles($np);
		# Save repository
		$r = $m.SaveChanges();
	} # if
	if($r) {
		switch($As) {
		'xml' { $OutputParameter += (ConvertTo-Xml -InputObject $r).OuterXml; }
		'xml-pretty' { $OutputParameter += Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
		'json' { $OutputParameter += ConvertTo-Json -InputObject $r -Compress; }
		'json-pretty' { $OutputParameter += ConvertTo-Json -InputObject $r; }
		Default { if(!$OutputParameter) { $OutputParameter = $r; } else { $OutputParameter = @($OutputParameter); $OutputParameter += $r; } }
		} # switch
		$fReturn = $true;
	} # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String); 
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception.InnerException -And ($_.Exception.InnerException -is [System.Data.Services.Client.DataServiceRequestException])) {
			Log-Critical $fn ("[DataServiceRequestException] Request FAILED. [{0}]." -f $_.Exception.InnerException.InnerException.Message);
			Log-Debug $fn $ErrorText -fac 3;
		} else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
	} # if
	if($np) { Remove-Variable np; }
} # finally
return $OutputParameter;
} # PROCESS

END {
$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # END

} # function
Export-ModuleMember -Function New-VcacNetworkProfile;

function Get-VcacIPv4AddressRangeAddresses {
[CmdletBinding(
    SupportsShouldProcess=$true,
    ConfirmImpact="Low",
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/Get-VcacIPv4AddressRangeAddresses/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'address')]
	[IPAddress] $StartAddress
	,
	[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'address')]
	[IPAddress] $EndAddress
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'range')]
	[alias("Range")]
	[DynamicOps.ManagementModel.StaticIPv4Range] $AddressRange
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty', 'IPAddress', 'StaticIPv4Address')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
)
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'." -f ($PSCmdlet.ParameterSetName)) -fac 1;
} # BEGIN

PROCESS {
try {

	# Default test variable for checking function response codes.
	[Boolean] $fReturn = $false;
	# Return values are always and only returned via OutputParameter.
	$OutputParameter = @();

	# Parameter validation
	if($PSCmdlet.ParameterSetName -eq 'range') {
		$StartAddress = $AddressRange.BeginIPv4Address;
		$EndAddress = $AddressRange.EndIPv4Address;
	} # if

	$abStartAddressReverse = $StartAddress.GetAddressBytes();
	[Array]::Reverse($abStartAddressReverse);
	[IPAddress] $StartAddressReverse = $abStartAddressReverse;
	$abEndAddressReverse = $EndAddress.GetAddressBytes();
	[Array]::Reverse($abEndAddressReverse);
	[IPAddress] $EndAddressReverse = $abEndAddressReverse;

	$aIPAddress = New-Object System.Collections.ArrayList;
	[IPAddress] $CurrentAddressReverse = $abStartAddressReverse;
	$Count = 0;
	while($CurrentAddressReverse.Address -le $EndAddressReverse.Address) {
		$abCurrentAddress = $CurrentAddressReverse.GetAddressBytes();
		[Array]::Reverse($abCurrentAddress);
		[IPAddress] $CurrentAddress = $abCurrentAddress;
		$null = $aIPAddress.Add($CurrentAddress);
		$CurrentAddressReverse.Address++;
		$Count++;
		if( !($Count % 1048576) ) { Log-Debug $fn ("IP range '{0}' - '{1}' [{2}]." -f $StartAddress, $EndAddress, $Count); }
	} # while
	if($aIPAddress.Count -gt 0) {
		if($PSCmdlet.ShouldProcess(("IP range '{0}' - '{1}' [{2}]." -f $StartAddress, $EndAddress, $Count))) {
			switch($As) {
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $aIPAddress).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $aIPAddress).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $aIPAddress -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $aIPAddress; }
			'StaticIPv4Address' { 
				$aStaticIPv4Address = New-Object System.Collections.ArrayList;
				foreach($ip in $aIPAddress) {
					$StaticIPv4Address = New-Object DynamicOps.ManagementModel.StaticIPv4Address;
					$StaticIPv4Address.ID = [guid]::NewGuid();
					$StaticIPv4Address.IPv4Address = $ip.IPAddressToString;
					$StaticIPv4Address.IPSortValue = $ip.Address;
					$StaticIPv4Address.StaticIPv4AddressState = [DynamicOps.ManagementModel.Common.Enums.StaticIPv4AddressState]::Unallocated.value__;
					$StaticIPv4Address.CreatedDate = [datetime]::UtcNow;
					$StaticIPv4Address.LastModifiedDate = [datetime]::UtcNow;
					$null = $aStaticIPv4Address.Add($StaticIPv4Address);
				} # foreach
				$OutputParameter = $aStaticIPv4Address;
			} # 'StaticIPv4Address'
			'IPAddress' { $OutputParameter = $aIPAddress; }
			Default { $OutputParameter = $aIPAddress; }
			} # switch
			$fReturn = $true;
		} # if
	} else {
		Log-Warning $fn ("Empty or invalid range specified: {0} - {1}" -f $StartAddress.IPAddressToString, $EndAddress.IPAddressToString);
	} # if
} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($aIPAddress) { Remove-Variable aIPAddress -WhatIf:$false -Confirm:$false; }
	if($CurrentAddress) { Remove-Variable CurrentAddress -WhatIf:$false -Confirm:$false; }
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]. Addresses returned: '{3}'." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz'), $OutputParameter.Count) -fac 2;

} # END

} # function
Export-ModuleMember -Function Get-VcacIPv4AddressRangeAddresses;

function Get-VcacCredential {

[CmdletBinding(
    SupportsShouldProcess = $false
	,
    ConfirmImpact = "Low"
	,
	HelpURI='http://dfch.biz/PS/Vcac/Utilities/Get-VcacCredential/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[string] $Name
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'o')]
	[alias("ConnectionCredential")]
	[DynamicOps.ManagementModel.ConnectionCredential] $cc
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'scrambled')]
	[alias("Password")]
	[string] $ScrambledPassword
	,
	[Parameter(Mandatory = $false)]
	[alias("MgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.MgmtContext
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[alias("Registered")]
	[switch] $ListAvailable = $false
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'o')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name')]
	[alias("Decrypt")]
	[switch] $UnScramble = $false
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty', 'PSCredential', 'Clear')]
	[Parameter(Mandatory = $false, ParameterSetName = 'o')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name')]
	[Parameter(Mandatory = $false, ParameterSetName = 'scrambled')]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param

BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. Name '{1}'." -f ($m -is [Object]), $Name) -fac 1;

if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		$msg = "MgmtContext: Parameter validation FAILED.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $m;
		throw($gotoError);
	} # if

	if($ListAvailable) {
		$OutputParameter = $m.ConnectionCredentials.CredentialName;
		$fReturn = $true;
		throw($gotoSuccess);
	} # if

	if($PSCmdlet.ParameterSetName -eq 'scrambled') {
		$Password = [DynamicOps.Common.Utils.ScramblerHelpers]::Unscramble($ScrambledPassword);
		$Cred = New-Object System.Management.Automation.PSCredential($ScrambledPassword, (ConvertTo-SecureString -String $Password -AsPlainText -Force));
		$r = $Password;
	} else {

		if($PSCmdlet.ParameterSetName -eq 'name') {
			# Load credentials of management endpoint
			$cc = $m.ConnectionCredentials |? CredentialName -eq $Name
			if(!$cc) {
				$msg = "Name: Parameter validation FAILED: '{0}'" -f $Name;
				$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Name;
				throw($gotoError);
			} # if
		} # if
		if(!$cc -Or ($cc -isnot [DynamicOps.ManagementModel.ConnectionCredential])) {
			$msg = "ConnectionCredentials: Parameter validation FAILED." -f $cc;
			$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $cc;
			throw($gotoError);
		} # if

		# Unscramble password
		$Password = [DynamicOps.Common.Utils.ScramblerHelpers]::Unscramble($cc.Password);
		$UserName = $cc.Username;
		$Cred = New-Object System.Management.Automation.PSCredential($cc.Username, (ConvertTo-SecureString -String $Password -AsPlainText -Force));

		# Update with unscrambled password if specified
		if($UnScramble) {
			$cc.Password = $Password;
		} # if

		$r = $cc;
	} # if

	switch($As) {
	'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
	'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
	'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
	'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
	'PSCredential' { $OutputParameter = $Cred; }
	'Clear' { $OutputParameter = @{'UserName' = $UserName; 'Password' = $Password; }}
	Default { $OutputParameter = $r; }
	} # switch
	$fReturn = $true;

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
	} # if
} # finally

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # END

} # Get-VcacCredential
Export-ModuleMember -Function Get-VcacCredential;

function Get-VcacVCenterVirtualMachine {
[CmdletBinding(
    SupportsShouldProcess = $true
	,
    ConfirmImpact = "Low"
	,
	HelpURI='http://dfch.biz/PS/Vcac/Utilities/Get-VcacVCenterVirtualMachine/'
)]
Param (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[alias("id")]
	[alias("idMachine")]
	[alias("MachineId")]
	[Guid] $VirtualMachineID
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'o')]
	[alias("vm")]
	[alias("VirtualMachine")]
	[DynamicOps.ManagementModel.VirtualMachine] $Machine
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'name')]
	[alias("Name")]
	[string] $VirtualMachineName
	,
	[Parameter(Mandatory = $false)]
	[alias("ReturnVIServerInformation")]
	[switch] $ReturnVCenterInformation = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("MgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.MgmtContext
) # Param

BEGIN {

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. VirtualMachineID '{0}'. ParameterSetName '{1}'." -f $VirtualMachineID, $PSCmdlet.ParameterSetName) -fac 1;

if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	# Parameter validation
	if($m -isnot [DynamicOps.ManagementModel.ManagementModelEntities]) {
		# TODO: load module if called from vCO
		$msg = "MgmtContext: Parameter validation FAILED. No ManagementModelEntities context specified.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $m;
		throw($gotoError);
	} # if
	if($PSCmdlet.ParameterSetName -eq 'id') {
		$Machine = $m.VirtualMachines |? VirtualMachineId -eq $VirtualMachineID;
		if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
			$msg = "VirtualMachineID: Parameter validation FAILED. No machine with id '{0}' found." -f $VirtualMachineID;
			$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $VirtualMachineID;
			throw($gotoError);
		} # if
	} elseif($PSCmdlet.ParameterSetName -eq 'name') {
		$Machine = $m.VirtualMachines |? VirtualMachineName -eq $VirtualMachineName;
		if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
			$msg = "VirtualMachineName: Parameter validation FAILED. No machine with name '{0}' found." -f $VirtualMachineName;
			$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $VirtualMachineName;
			throw($gotoError);
		} # if
	} # if
	if($Machine -isnot [DynamicOps.ManagementModel.VirtualMachine]) {
		$msg = "Machine: Parameter validation FAILED. No machine object specified.";
		$e = New-CustomErrorRecord -m $msg -cat InvalidData -o $null;
		throw($gotoError);
	} # if
	$VirtualMachineName = $Machine.VirtualMachineName;
	$VirtualMachineID = $Machine.VirtualMachineID;
	Log-Info $fn ("Processing: VirtualMachineID '{0}'. VirtualMachineName '{1}'. VirtualMachineState '{2}'. Target VirtualMachineState '{3}'." -f $Machine.VirtualMachineID, $Machine.VirtualMachineName, $Machine.VirtualMachineState, $VirtualMachineState);

	$PSSnapinName = 'VMware.VimAutomation.Core';
	$PSSnapin = Get-PSSnapin -Name $PSSnapinName -ErrorAction:SilentlyContinue;
	if(!$PSSnapin) {
		$msg = "{0}: Parameter validation FAILED. PSSnapin not loaded. Invoke 'Add-PSSnapin VMware.VimAutomation.Core' and try again." -f $PSSnapin;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $PSSnapinName;
		throw($gotoError);
	} # if

	$null = $m.LoadProperty($Machine, 'Host');
	$h = $Machine.Host;
	if(!$h) {
		$RelatedObject = 'Machine.Host';
		$msg = "{0}: Parameter validation FAILED. Object could not be loaded." -f $RelatedObject;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $RelatedObject;
		throw($gotoError);
	} # if
	$null = $m.LoadProperty($h, 'ManagementEndpoint');
	$me = $h.ManagementEndpoint;
	if(!$me) {
		$RelatedObject = 'Machine.Host.ManagementEndpoint';
		$msg = "{0}: Parameter validation FAILED. Object could not be loaded." -f $RelatedObject;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $RelatedObject;
		throw($gotoError);
	} # if
	$null = $m.LoadProperty($me, 'Credential');
	$cc = $me.Credential;
	if(!$cc) {
		$RelatedObject = 'Machine.Host.ManagementEndpoint.Credential';
		$msg = "{0}: Parameter validation FAILED. Object could not be loaded." -f $RelatedObject;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $RelatedObject;
		throw($gotoError);
	} # if
	$Cred = Get-VcacCredential -cc $cc -As PSCredential;
	if(!$Cred) {
		$RelatedObject = 'Machine.Host.ManagementEndpoint.Credential/ConnectionCredential';
		$msg = "{0}: Parameter validation FAILED. Object could not be loaded." -f $RelatedObject;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $RelatedObject;
		throw($gotoError);
	} # if

	# Login to vCenter
	[Uri] $UriMe = $me.ManagementUri;
	$s = Connect-ViServer -Server $UriMe.Host -Credential $Cred;

	$vm = Get-Vm -Name $Machine.VirtualMachineName;
	if(!$vm) {
		$RelatedObject = 'Machine.Host.ManagementEndpoint.Credential/ConnectionCredential';
		$msg = "{0}: Parameter validation FAILED. Virtual machine could not be found on vCenter Host '{1}'." -f $Machine.VirtualMachineName, $UriMe.Host;
		$e = New-CustomErrorRecord -m $msg -cat ObjectNotFound -o $Machine.VirtualMachineName;
		throw($gotoError);
	} # if

	$ht = @{};
	if($ReturnVCenterInformation) {
		$ht.VIServer = $UriMe.Host;
		$ht.ViServerSession = $s;
		$ht.ViServerCredential = $Cred;
		$ht.ViServerVirtualMachine = $vm;
		$ht.VcacManagementEndpoint = $me;
		$ht.VcacHost = $h;
		$ht.VcacVirtualMachine = $Machine;
		$OutputParameter = $ht;
	} else {
		$OutputParameter = $vm;
	} # if
	$fReturn = $true;

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext;
	} # if
} # finally

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # END

} # function
Set-Alias -Name Get-VcacVCenterMachine -Value Get-VcacVCenterVirtualMachine;
Set-Alias -Name Get-VcacVIMachine -Value Get-VcacVCenterVirtualMachine;
Export-ModuleMember -Function Get-VcacVCenterVirtualMachine -Alias Get-VcacVIMachine, Get-VcacVCenterMachine;

function New-VcacIPv4AddressRange {
[CmdletBinding(
    SupportsShouldProcess=$true
	,
    ConfirmImpact="Low"
	,
	HelpURI='http://dfch.biz/PS/vCAC/Utilities/New-VcacIPv4AddressRange/'
)]
Param (
	[Parameter(Mandatory = $false, Position = 0)]
	[alias("Name")]
	[String] $StaticIPv4RangeName
	,
	[Parameter(Mandatory = $false, Position = 1)]
	[alias("Description")]
	[String] $IPv4RangeDescription
	,
	[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 2)]
	[IPAddress] $StartAddress
	,
	[Parameter(Mandatory = $false, Position = 3)]
	[IPAddress] $EndAddress
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'object')]
	[alias("Profile")]
	[alias("NetworkProfile")]
	[DynamicOps.ManagementModel.StaticIPv4NetworkProfile] $StaticIPv4NetworkProfile
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'name')]
	[String] $StaticIPv4NetworkProfileName
	,
	[Parameter(Mandatory = $false)]
	[switch] $AddIpAddressesToRange = $true
	,
	[Parameter(Mandatory = $false)]
	[switch] $SkipIPInUseCheck = $false
	,
	[Parameter(Mandatory = $false)]
	[switch] $SingleIpPerRange = $false
	,
	[Parameter(Mandatory = $false)]
	[alias("mgmtContext")]
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty')]
	[Parameter(Mandatory = $false)]
	[alias("ReturnFormat")]
	[string] $As = 'default'
) # Param
BEGIN {
$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
$IsRecursion = Test-Recursion;
Log-Debug -fn $fn -msg ("CALL. ParameterSetName '{0}'. SingleIpPerRange '{1}'. SkipIPInUseCheck '{2}'. IsRecursion '{3}'. " -f $PSCmdlet.ParameterSetName, $SingleIpPerRange, $SkipIPInUseCheck, $IsRecursion) -fac 1;
} # BEGIN

PROCESS {
try {

	# Default test variable for checking function response codes.
	[Boolean] $fReturn = $false;
	# Return values are always and only returned via OutputParameter.
	$OutputParameter = @();
	
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And !$IsRecursion) { $DataContext = Backup-VcacDataContext; }
	
	# Parameter validation
    if(!$PSBoundParameters.ContainsKey('EndAddress')) { $EndAddress = $StartAddress; }
    if(!$PSBoundParameters.ContainsKey('StaticIPv4RangeName')) { 
        $StartAddressSplit = $StartAddress.IPAddressToString.Split('.');
        $StartAddressString = '{0}.{1}.{2}.{3}' -f ($StartAddressSplit[0] -as [int]).ToString('000'), ($StartAddressSplit[1] -as [int]).ToString('000'), ($StartAddressSplit[2] -as [int]).ToString('000'), ($StartAddressSplit[3] -as [int]).ToString('000');
        $EndAddressSplit = $EndAddress.IPAddressToString.Split('.');
        $EndAddressString = '{0}.{1}.{2}.{3}' -f ($EndAddressSplit[0] -as [int]).ToString('000'), ($EndAddressSplit[1] -as [int]).ToString('000'), ($EndAddressSplit[2] -as [int]).ToString('000'), ($EndAddressSplit[3] -as [int]).ToString('000');
        $StaticIPv4RangeName = 'IPv4Range {0} - {1}' -f $StartAddressString, $EndAddressString; 
    } # if

	# Check if IP range name is not yet defined
	if(!$SkipIPInUseCheck) {
		$ipr = $m.StaticIPv4Ranges |? StaticIPv4RangeName -eq $StaticIPv4RangeName;
		if($ipr) {
			$msg = "StaticIPv4RangeName: Parameter check FAILED. '{0}' does already exist. Aborting ..." -f $StaticIPv4RangeName;
			Log-Critical $fn $msg;
			$e = New-CustomErrorRecord -msg $msg -cat InvalidData -o $StaticIPv4RangeName;
			throw($gotoError);
		} # if
	} # if
	if($PSCmdlet.ParameterSetName -eq 'name') {
		$StaticIPv4NetworkProfile = $m.StaticIPv4NetworkProfiles |? StaticIPv4NetworkProfileName -eq $StaticIPv4NetworkProfileName;
		if(!$StaticIPv4NetworkProfile) {
			$msg = "StaticIPv4NetworkProfileName: Parameter check FAILED. '{0}' does not exist. Aborting ..." -f $StaticIPv4NetworkProfileName;
			Log-Critical $fn $msg;
			$e = New-CustomErrorRecord -msg $msg -cat ObjectNotFound -o $StaticIPv4NetworkProfileName;
			throw($gotoError);
		} # if
	} elseif($PSCmdlet.ParameterSetName -eq 'object') {
		$StaticIPv4NetworkProfileName = $StaticIPv4NetworkProfile.StaticIPv4NetworkProfileName;
	} else {
		$msg = "Unexpected ParameterSetName '{0}. Aborting ..." -f $PSCmdlet.ParameterSetName;
		Log-Critical $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat InvalidData -o $PSCmdlet.ParameterSetName;
		throw($gotoError);
	} # if

	# Get all IP addresses for range
	$aip = Get-VcacIPv4AddressRangeAddresses -StartAddress $StartAddress -EndAddress $EndAddress -As 'StaticIPv4Address';
	if(!$aip) {
		$msg = "Empty or invalid range specified: {0} - {1}" -f $StartAddress.IPAddressToString, $EndAddress.IPAddressToString
		Log-Critical $fn $msg;
		$e = New-CustomErrorRecord -msg $msg -cat InvalidData -o ('{0} - {1}' -f $StartAddress.IPAddressToString, $EndAddress.IPAddressToString);
		throw($gotoError);
	} # if
	# Check if IP addresses are not yet allocated
	if(!$SkipIPInUseCheck) {
		foreach($StaticIPv4Address in $m.StaticIPv4Addresses) {
			foreach($ip in $aip) {
				if($StaticIPv4Address.IPSortValue -eq $ip.IPSortValue) {
					$fAbort = $true;
					$null = $m.LoadProperty($StaticIPv4Address, 'StaticIPv4NetworkProfile');
					$null = $m.LoadProperty($StaticIPv4Address, 'StaticIPv4Range');
					$msg = "IP range conflicts with existing IP range. '{0}' is in use by network profile '{1}' [{2}] in network range '{3}' [{4}]." -f $ip.IPv4Address, $StaticIPv4Address.StaticIPv4NetworkProfile.StaticIPv4NetworkProfileName, $StaticIPv4Address.StaticIPv4NetworkProfile.ID, $StaticIPv4Address.StaticIPv4Range.StaticIPv4RangeName, $StaticIPv4Address.StaticIPv4Range.ID;
					Log-Critical $fn $msg;
					throw($gotoFailure);
				} # if
			} # foreach
		} # foreach
	} # if

	if($SingleIpPerRange) {
		$BackupDataContext = $biz_dfch_PS_vCAC_Utilities.BackupDataContext;
		$biz_dfch_PS_vCAC_Utilities.BackupDataContext = $false;
		$aRangeReturn = New-Object System.Collections.ArrayList;
		foreach($ip in $aip) {
			$RangeReturn = New-VcacIPv4AddressRange -StartAddress $ip.IPv4Address -StaticIPv4NetworkProfile $StaticIPv4NetworkProfile -SkipIPInUseCheck $true -SingleIpPerRange $false -As $As;
			if(!$RangeReturn) { throw($gotoFailure); }
			$null = $aRangeReturn.Add($RangeReturn);
		} # foreach
		$biz_dfch_PS_vCAC_Utilities.BackupDataContext = $BackupDataContext;
		$OutputParameter = $aRangeReturn;
		throw($gotoSuccess);
	} # if

	$ipr = New-Object DynamicOps.ManagementModel.StaticIPv4Range;
	$ipr.ID = [guid]::NewGuid();
	$ipr.StaticIPv4RangeName = $StaticIPv4RangeName;
	$ipr.IPv4RangeDescription = $IPv4RangeDescription;
	$ipr.BeginIPv4Address = $StartAddress.IPAddressToString;
	$ipr.EndIPv4Address = $EndAddress.IPAddressToString;
	$ipr.CreatedDate = [datetime]::UtcNow;
	$ipr.LastModifiedDate = [datetime]::UtcNow;
	
	if($PSCmdlet.ShouldProcess( ("Adding IP range '{0}' with IP addresses '{1}' - '{2}' to profile '{3}'" -f $StaticIPv4RangeName, $StartAddress, $EndAddress, $StaticIPv4NetworkProfile.StaticIPv4NetworkProfileName))) {
		$m.AddToStaticIPv4Ranges($ipr);
        if($AddIpAddressesToRange) {
			foreach($ip in $aip) {
				$m.AddToStaticIPv4Addresses($ip);
			    $m.SetLink($ip, 'StaticIPv4NetworkProfile', $StaticIPv4NetworkProfile);
			    $m.SetLink($ip, 'StaticIPv4Range', $ipr);
			    $m.UpdateObject($ip);
			} # foreach
		} # if
		$m.SetLink($ipr, 'StaticIPv4NetworkProfile', $StaticIPv4NetworkProfile);
		$m.UpdateObject($ipr);
		$m.UpdateObject($StaticIPv4NetworkProfile);
		# if(!$IsRecursion) { Log-Warning $fn ("IsRecursion '{0}'" -f $IsRecursion); $ar = $m.SaveChanges(); }
		$ar = $m.SaveChanges();
        $sDescriptor = '';
        foreach($r in $ar) {
            $sDescriptor = [string]::Concat($sDescriptor, "`n", $r.StatusCode, ": ", $r.Descriptor.Identity);
        } # foreach
        if($sDescriptor) { Log-Debug $fn $sDescriptor; }

		switch($As) {
		'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $ipr).OuterXml; }
		'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $ipr).OuterXml; }
		'json' { $OutputParameter = ConvertTo-Json -InputObject $ipr -Compress; }
		'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $ipr; }
		Default { $OutputParameter = $ipr; }
		} # switch
		$fReturn = $true;
    } # if

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [{0}]" -f $_.FullyQualifiedErrorId;
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception.GetBaseException() -is [System.Data.Services.Client.DataServiceClientException]) {
			Log-Critical $fn ("[DataServiceRequestException] An error occurred with status '{0}'.`n{1}." -f 
				$_.Exception.GetBaseException().StatusCode, 
				$_.Exception.GetBaseException().Message);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		elseif($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext -And !$IsRecursion) {
		$null = Restore-VcacDataContext;
		Remove-Variable DataContext -Confirm:$false -WhatIf:$false;
	} # if
} # finally

# Return values are always and only returned via OutputParameter.
return $OutputParameter;

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

} # END

} # function
Export-ModuleMember -Function New-VcacIPv4AddressRange;

function Get-VcacEntity {
[CmdletBinding(
    SupportsShouldProcess = $false
	,
    ConfirmImpact = 'Low'
	,
	DefaultParameterSetName = 'guid'
	,
	HelpURI='http://dfch.biz/PS/Vcac/Utilities/Get-VcacEntity/'
)]
PARAM (
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'guid')]
	[guid] $Guid
	,
	[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'id')]
	[int] $id
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'filter')]
	[string] $FilterProperty
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'filter')]
	[Alias('Name')]
	[string] $FilterValue
	,
	[ValidateSet('eq', 'ne', 'gt', 'ge', 'lt', 'le', 'startswith', 'endswith', 'not startswith', 'not endswith')]
	[Parameter(Mandatory = $false, ParameterSetName = 'filter')]
	[string] $FilterOperand = 'eq'
	,
	[Parameter(Mandatory = $false)]
	[String] $Type = 'DynamicOps.ManagementModel.VirtualMachine'
	,
	[Parameter(Mandatory = $false)]
	[Alias('Top')]
	[int] $First = [int]::MaxValue
	,
	[Parameter(Mandatory = $false)]
	[Switch] $ReturnExistingEntity = $true
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'list')]
	[Switch] $ListAvailable = $true
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'ListEntityType')]
	[String] $ListEntityType = 'DynamicOps.ManagementModel.VirtualMachine'
	,
	[DynamicOps.ManagementModel.ManagementModelEntities] $m = $biz_dfch_PS_vCAC_Utilities.mgmtContext
)

BEGIN {

	Set-Variable gotoSuccess -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoSuccess' -Confirm:$false -WhatIf:$false;
	Set-Variable gotoError -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoError' -Confirm:$false -WhatIf:$false;
	Set-Variable gotoFailure -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoFailure' -Confirm:$false -WhatIf:$false;
	Set-Variable gotoNotFound -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoNotFound' -Confirm:$false -WhatIf:$false;

	$datBegin = [datetime]::Now;
	[string] $fn = $MyInvocation.MyCommand.Name;
	Log-Debug -fn $fn -msg ("CALL. MgmtContext '{0}'. Guid '{1}'. id '{2}'. FilterProperty '{3}'. FilterValue '{4}'. Type '{5}'. ParameterSetName: '{6}'." -f ($m -is [Object]), $Guid, $id, $FilterProperty, $FilterValue, $Type, $PsCmdlet.ParameterSetName) -fac 1;

} # BEGIN
PROCESS {

# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try {

	if($PSCmdlet.ParameterSetName -eq 'list') {
		$aDefinition = ($m | gm -Type Properties).Definition;
		foreach($Definition in $aDefinition) {
			$fReturn = $Definition -match 'DynamicOps\.Repository\.RepositoryServiceQuery\[(?<Type>[^\]]+)\]';
			if(!$fReturn) { continue; }
			$OutputParameter += ("{0}`n" -f $Matches.Type);
			$OutputParameter = $OutputParameter | Sort;
		} # foreach
		throw($gotoSuccess);
	} elseif($PSCmdlet.ParameterSetName -eq 'ListEntityType') {
		$entity = New-Object $ListEntityType;
		$fReturn = $true;
		$OutputParameter = $entity;
		throw($gotoSuccess);
	} # if

	# Create new entity
	$NewVcacEntity = New-Object $Type;
	if(!$NewVcacEntity) { Write-Error ("Invalid object type: '{0}'." -f $Type) }
	# Define default property name if not specified
	if(!$FilterProperty) { $FilterProperty = '{0}Name' -f $NewVcacEntity.GetType().Name; }
	Remove-Variable NewVcacEntity;
	# Construct Uri
	$ServerUri = $biz_dfch_PS_vCAC_Utilities.ServerUri;
	if($PSBoundParameters.ContainsKey('First')) {
		$FilterTop = '?$top={0}&' -f $First;
	} else {
		$FilterTop = '?';
	} # if
	switch($PSCmdlet.ParameterSetName) {
		# 'id' { [Uri] $Uri = "{0}/{1}({2})" -f $ServerUri, $m.GetEntitySetFromType($Type), $id; }
		'id' { [Uri] $Uri = "{0}/{1}({2}){3}" -f $ServerUri, $m.GetEntitySetFromType($Type), $id, $FilterTop; }
		'guid' { [Uri] $Uri = "{0}/{1}(guid'{2}')" -f $ServerUri, $m.GetEntitySetFromType($Type), $Guid; }
		'guid' { [Uri] $Uri = "{0}/{1}(guid'{2}'){3}" -f $ServerUri, $m.GetEntitySetFromType($Type), $Guid, $FilterTop; }
		'filter' { 
			switch($FilterOperand) {
				'startswith' { [Uri] $Uri = "{0}/{1}{5}`$filter={2}({3}, '{4}')" -f $ServerUri, $m.GetEntitySetFromType($Type), $FilterOperand, $FilterProperty, $FilterValue, $FilterTop; }
				'not startswith' { [Uri] $Uri = "{0}/{1}{5}`$filter={2}({3}, '{4}')" -f $ServerUri, $m.GetEntitySetFromType($Type), $FilterOperand, $FilterProperty, $FilterValue, $FilterTop; }
				'endswith' { [Uri] $Uri = "{0}/{1}{5}`$filter={2}({3}, '{4}')" -f $ServerUri, $m.GetEntitySetFromType($Type), $FilterOperand, $FilterProperty, $FilterValue, $FilterTop; }
				'not endswith' { [Uri] $Uri = "{0}/{1}{5}`$filter={2}({3}, '{4}')" -f $ServerUri, $m.GetEntitySetFromType($Type), $FilterOperand, $FilterProperty, $FilterValue, $FilterTop; }
				default { [Uri] $Uri = "{0}/{1}{5}`$filter={2} {3} '{4}'" -f $ServerUri, $m.GetEntitySetFromType($Type), $FilterProperty, $FilterOperand, $FilterValue, $FilterTop; }
			} # switch
		} # 'filter'
		default { Write-Error 'Invalid ParameterSetName.' }
	} # switch

	Log-Debug $fn ("Invoking Uri '{0}' ..." -f $Uri);
	if($m.Credentials.UserName) {
		$wr = Invoke-RestMethod $Uri -Credential $m.Credentials;
	} else {
		$wr = Invoke-RestMethod $Uri -UseDefaultCredentials;
	} # if

	if($wr.Count -gt 1) {
		$OutputParameter = New-Object System.Collections.ArrayList;
	} # if
	foreach($r in $wr) {
		# Convert from XmlDocument or XmlLinkedNode
		if($r.entry) { $x = $r.entry; } else { $x = $r; }

		$NewVcacEntity = New-Object $Type;
		foreach($Entity in $m.Entities) {
			if($x.id -ne $Entity.Identity) { continue; }
			if($ReturnExistingEntity) {
				Log-Debug $fn ("Entity '{0}' [{1}] found in entity tracker. Returning existing entity ..." -f $Entity.Identity, $NewVcacEntity.GetType().Name);
				$NewVcacEntity = $Entity.Entity;
				$m.AttachIfNeeded($m.GetEntitySetFromType($NewVcacEntity.GetType()), $NewVcacEntity);
				$OutputParameter = $NewVcacEntity;
				throw($gotoSuccess);
			} else {
				Log-Debug $fn ("Entity '{0}' [{1}] found in entity tracker. Removing existing entity ..." -f $Entity.Identity, $NewVcacEntity.GetType().Name);
				$fReturn = $m.Detach($Entity.Entity);
				break;
			} # if
		} # foreach

		# Convert returned EF xml entities to .NET data types
		foreach($p in $x.content.properties.GetEnumerator()) { 
			if($p.localname -eq '#whitespace') { continue; }
			switch($p.type) {
			'Edm.Int32' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			'Edm.Int64' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			'Edm.Decimal' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			'Edm.Boolean' { if($p.null -ne 'true') { if($p.'#text' -eq 'true') { $NewVcacEntity.($p.localname) = $true; } else { $NewVcacEntity.($p.localname) = $false; } } }
			'Edm.Guid' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			'Edm.DateTime' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			'Edm.Byte' { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			default { if($p.null -ne 'true') { $NewVcacEntity.($p.localname) = $p.'#text'; } }
			} # switch
		} # foreach

		# Attach object to entity tracker
		$m.AttachIfNeeded($m.GetEntitySetFromType($NewVcacEntity.GetType()), $NewVcacEntity);
		# Optional: if you had used an expand expression you could also load the returned links to that entity
		# foreach($l in $r.entry.link.GetEnumerator()) { 
			# if(!$l.inline) { continue; }
			# $null = $m.LoadProperty($NewVcacEntity, $l.title);
		# } # foreach

		if($wr.Count -gt 1) {
			$null = $OutputParameter.Add($NewVcacEntity);
		} else {
			$OutputParameter = $NewVcacEntity;
		} # if
	} # foreach
	$fReturn = $true;

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -ne $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				# N/A
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
} # finally

} # PROCESS

END {

$datEnd = [datetime]::Now;
Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;

return $OutputParameter;
} # END

} # function
Export-ModuleMember -Function Get-VcacEntity;

<#
2014-07-25; rrink; ADD: Signed module file
2014-02-24; rrink; CHG: New-VcacUserLog; Default value for 'Date' parameter changed from [datetime]::Now to [datetime]::UtcNow
2014-02-21; rrink; CHG: Get-VcacEntity; fixed break on ReturnExisting with multiple results
2014-02-17; rrink; CHG: Get-VcacEntity; fixed catch handler on gotoSuccess
2014-02-12; rrink; ADD: Module load; load metadata
2014-02-12; rrink; CHG: Get-VcacEntity; added support for (not)startswith/(not)endswith, added First switch
2014-02-12; rrink; CHG: Exit-VcacCriticalSection; implemented [StopWatch] for WaitTimer
2014-02-12; rrink; CHG: Enter-VcacCriticalSection; implemented [StopWatch] for WaitTimer
2014-02-12; rrink; CHG: Exit-VcacCriticalSection; implemented '-WaitTimeoutMillisecond' switch for -Wait' to specify a maximum wait time
2014-02-10; rrink; CHG: Module load; try/catch with more error information
2014-02-10; rrink; ADD: Get-VcacEntity
2014-02-10; rrink; CHG: Get-VcacVCenterVirtualMachine; added -ReturnVCenterInformation for returning full vCenter information associated with machine
2014-02-02; rrink; CHG: Set-VcacMachineStatus; added -Clear switch to remove CurrentTask
2014-02-02; rrink; CHG: Initialisation; changed init routine to guard Add-Type with try/catch and SilentlyContinue to prevent error messages on DEM workers without WF
2014-01-29; rrink; CHG: Enter-VcacCriticalSection; removed cache clearing for 'TryOnce' calls
2014-01-29; rrink; CHG: Get-VcacCredential; added -Scambled parameter to decrypt scrambled properties and password strings
2014-01-29; rrink; DEL: Get-CumulusProperty; moved to com.ebay.PS.Cumulus.Utilities.psm1
2014-01-29; rrink; DEL: Remove-CumulusProperty; moved to com.ebay.PS.Cumulus.Utilities.psm1
2014-01-29; rrink; ADD: Remove-CumulusProperty
2014-01-28; rrink; ADD: Get-CumulusProperty
2014-01-27; rrink; ADD: New-VcacIPv4AddressRange
2014-01-24; rrink; CHG: New-VcacUserLog; set default parameterset
2014-01-23; rrink; CHG: Exit-VcacCriticalSection; cleared cache when using 'ReturnExisting' switch parameter
2014-01-23; rrink; CHG: Enter-VcacCriticalSection; Exit-VcacCriticalSection; regex changed to global var.
2014-01-23; rrink; CHG: Global: added Alias "Encrypted" for switch Parameter "IsEncrypted"
2014-01-23; rrink; CHG: Global: added Alias "PromptUser" for switch Parameter "IsRuntime"
2014-01-22; rrink; CHG: Enter-VcacCriticalSection; added switch ReturnExisting to return lock information when TryOnce fails to enter because of an existing lock
2014-01-22; rrink; CHG: Get-VcacVCenterVirtualMachine; added more detailed help text for not loaded PowerCLI PSSnapin
2014-01-22; rrink; CHG: Get-VcacVCenterVirtualMachine; added Alias to Cmdlet
2014-01-22; rrink: ADD: Global; added 'Registered' as an alias to 'ListAvailable' switch parameters
2014-01-21; rrink; ADD: Get-VcacVCenterVirtualMachine
2014-01-10; rrink; CHG: globally change '$DataContext = Backup-VcacDataContext;' to 'if($biz_dfch_PS_vCAC_Utilities.BackupDataContext) { $DataContext = Backup-VcacDataContext; }'
2014-01-10; rrink; CHG: globally change 'if($DataContext)' to 'if($biz_dfch_PS_vCAC_Utilities.BackupDataContext -And $DataContext)'
2014-01-08; rrink; CHG: New-VcacNetworkProfile; BUG: subnet mask setting not processes correctly
2014-01-08; rrink; CHG: Get-VcacIPv4AddressRangeAddresses; added -As options to return addresses as vCAC objects or IPAddress objects (default)
2013-12-31; rrink; ADD: Get-VcacIPv4AddressRangeAddresses
2013-12-31; rrink; ADD: New-VcacNetworkProfile
2013-12-30; rrink; ADD: Restore-VcacDataContext; added Exclude parameter; initial log statement more verbose and compact
2013-12-30; rrink; CHG: Backup-VcacDataContext; added ListAvailable switch to only display Entities and Links; initial log statement more verbose and compact
2013-12-29; rrink; CHG: Exit-VcacCriticalSection; added Clear and ListAvailable switch
2013-12-29; rrink; CHG: Enter-VcacCriticalSection; added Signal switch to create and delete a section at the same time
2013-12-29; rrink; CHG: Enter-VcacCriticalSection; moved dispose code nearer to object use
2013-12-29; rrink; CHG: Restore-VcacDataContext; changed ValidateScript ($var to $_)
2013-12-24; rrink; CHG: Restore-VcacDataContext; added ValidateScript to prevent Pop from empty stacks
2013-12-21; rrink; CHG: Restore-VcacDataContext; added switch Clear
2013-12-18; rrink; ADD: Exit-VcacCriticalSection
2013-12-18; rrink; ADD: Enter-VcacCriticalSection
2013-12-08; rrink; ADD: Restore-VcacDataContext
2013-12-08; rrink; ADD: Backup-VcacDataContext
2013-11-21; rrink; ADD: Remove-VcacControlInstance
2013-11-21; rrink; ADD: New-VcacControlInstance
2013-11-20; rrink; ADD: Remove-VcacControlLayout
2013-11-20; rrink; ADD: New-VcacControlLayout
2013-11-17; rrink; DEL: Prologue: Removed 'Set-SslSecurityPolicy -TrustAllCertificates -Confirm:$false;' as it crashed the DEM worker
2013-11-17; rrink: CHG: New-VcacPropertyDefinition; set default value 'TextBox' for 'Type' parameter
2013-11-11; rrink; ADD: New-VcacUserLog
2013-11-11; rrink; ADD: Set-VcacMachineStatus
2013-11-11; rrink; CHG: TYPO [[3]] to [{3}]
2013-11-11; rrink; CHG: HelpUri changed from Infoblox/Api to Vcac/Utilities
2013-11-11; rrink; ADD: Set-VcacVirtualMachineLinkedProperty: New alias Set-VcacVirtualMachineCustomProperty
2013-11-07; rrink; DEL: Removed .Detach() call on machine entity
2013-10-30; rrink; CHG: ConvertTo-VcacArrayOfProperties; if 'FilterName' does not relate to a field in the InputObject the actual name of the parameter is taken as the FilterName
2013-10-30; rrink; CHG: ConvertTo-VcacArrayOfProperties; corrected XML tags and namespace
2013-10-27; rrink; ADD: Module prologue for initialisation of MgmtContext
2013-10-27; rrink; ADD: Set-VcacVirtualMachineLinkedProperty
2013-10-27; rrink; ADD: New-VcacPropertyDefinitionAttribute
2013-10-27; rrink; ADD: Remove-VcacPropertyDefinitionAttribute
2013-10-27; rrink; ADD: Set-VcacPropertyDefinition
2013-10-27; rrink; ADD: Get-VcacPropertyDefinition
2013-10-27; rrink; ADD: Remove-VcacPropertyDefinition
2013-10-27; rrink; ADD: New-VcacPropertyDefinition
2013-10-27; rrink; ADD: ConvertTo-VcacArrayOfProperties
2013-10-26; rrink; ADD: Set-VcacVirtualMachineProperty
2013-10-20; rrink; CHG: reorg module and only include Cmdlets that use the .NET assembly
2013-10-16; rrink; ADD: Remove-VcacGlobalProfileProperty
2013-10-16; rrink; ADD: Get-VcacGlobalProfileProperty
2013-10-16; rrink; ADD: Set-VcacGlobalProfileProperty
2013-10-16; rrink; ADD: New-VcacGlobalProfileProperty
2013-10-16; rrink; ADD: Get-VcacGlobalProfile
2013-10-16; rrink; ADD: Set-VcacGlobalProfile
2013-10-16; rrink; ADD: Remove-VcacGlobalProfile
2013-10-16; rrink; ADD: New-VcacGlobalProfile
2013-10-11; rrink; ADD: Get-VcacPropertyDefinition
2013-10-11; rrink; ADD: Set-VcacPropertyDefinition
2013-10-11; rrink; CHG: Get-VcacData; Improved error handling
2013-10-11; rrink; CHG: CreateFullUrl; Added check for AbsoluteUri
#>

# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiihpRpMe/5HHbUXo84mWyGju
# PbagghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCgwggMQoAMCAQICCwQAAAAAAS9O4TVcMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290
# IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAw
# WhcNMTkwNDEzMTAwMDAwWjBRMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEnMCUGA1UEAxMeR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsk8U5xC+1yZyqzaX
# 71O/QoReWNGKKPxDRm9+KERQC3VdANc8CkSeIGqk90VKN2Cjbj8S+m36tkbDaqO4
# DCcoAlco0VD3YTlVuMPhJYZSPL8FHdezmviaJDFJ1aKp4tORqz48c+/2KfHINdAw
# e39OkqUGj4fizvXBY2asGGkqwV67Wuhulf87gGKdmcfHL2bV/WIaglVaxvpAd47J
# MDwb8PI1uGxZnP3p1sq0QB73BMrRZ6l046UIVNmDNTuOjCMMdbbehkqeGj4KUEk4
# nNKokL+Y+siMKycRfir7zt6prjiTIvqm7PtcYXbDRNbMDH4vbQaAonRAu7cf9DvX
# c1Qf8wIDAQABo4H6MIH3MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBQIbti2nIq/7T7Xw3RdzIAfqC9QejBHBgNVHSAEQDA+MDwG
# BFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20v
# cmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9yb290LmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAIlzF3T30
# C3DY4/XnxY4JAbuxljZcWgetx6hESVEleq4NpBk7kpzPuUImuztsl+fHzhFtaJHa
# jW3xU01UOIxh88iCdmm+gTILMcNsyZ4gClgv8Ej+fkgHqtdDWJRzVAQxqXgNO4yw
# cME9fte9LyrD4vWPDJDca6XIvmheXW34eNK+SZUeFXgIkfs0yL6Erbzgxt0Y2/PK
# 8HvCFDwYuAO6lT4hHj9gaXp/agOejUr58CgsMIRe7CZyQrFty2TDEozWhEtnQXyx
# Axd4CeOtqLaWLaR+gANPiPfBa1pGFc0sGYvYcJzlLUmIYHKopBlScENe2tZGA7Bo
# DiTvSvYLJSTvJDCCBJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkq
# hkiG9w0BAQUFADBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAe
# Fw0xMzA4MjMwMDAwMDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8w
# HQYDVQQKExZHTU8gR2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxT
# aWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal
# +oTDYUDFRrVZUjtCoi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1A
# cjzyCXenSZKX1GyQoHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFF
# WbIub2Jd4NkZrItXnKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7sp
# Tj1Tk7Om+o/SWJMVTLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5
# crCpGTkqUPqp0Dw6yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAO
# BgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEF
# BQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYD
# VR0TBAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAz
# hjFodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5n
# bG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0O
# BBYEFNSihEo4Whh/uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0
# hZuw3WrWFKnBMA0GCSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17s
# LOmhPPW6qlMdudEpY9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjq
# IRaczpCmLvumytmU30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1tx
# KWGRGBprevL9DdHNfV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJET
# iwRdK8S5FhvMVcUM6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126Y
# PKacOwuDvsu4uyomjFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIE
# rTCCA5WgAwIBAgISESFgd9/aXcgt4FtCBtsrp6UyMA0GCSqGSIb3DQEBBQUAMFEx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQD
# Ex5HbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gRzIwHhcNMTIwNjA4MDcyNDEx
# WhcNMTUwNzEyMTAzNDA0WjB6MQswCQYDVQQGEwJERTEbMBkGA1UECBMSU2NobGVz
# d2lnLUhvbHN0ZWluMRAwDgYDVQQHEwdJdHplaG9lMR0wGwYDVQQKDBRkLWZlbnMg
# R21iSCAmIENvLiBLRzEdMBsGA1UEAwwUZC1mZW5zIEdtYkggJiBDby4gS0cwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTG4okWyOURuYYwTbGGokj+lvB
# go0dwNYJe7HZ9wrDUUB+MsPTTZL82O2INMHpQ8/QEMs87aalzHz2wtYN1dUIBUae
# dV7TZVme4ycjCfi5rlL+p44/vhNVnd1IbF/pxu7yOwkAwn/iR+FWbfAyFoCThJYk
# 9agPV0CzzFFBLcEtErPJIvrHq94tbRJTqH9sypQfrEToe5kBWkDYfid7U0rUkH/m
# bff/Tv87fd0mJkCfOL6H7/qCiYF20R23Kyw7D2f2hy9zTcdgzKVSPw41WTsQtB3i
# 05qwEZ3QCgunKfDSCtldL7HTdW+cfXQ2IHItN6zHpUAYxWwoyWLOcWcS69InAgMB
# AAGjggFUMIIBUDAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAy
# ATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVw
# b3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzA+BgNVHR8E
# NzA1MDOgMaAvhi1odHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzY29kZXNp
# Z25nMi5jcmwwUAYIKwYBBQUHAQEERDBCMEAGCCsGAQUFBzAChjRodHRwOi8vc2Vj
# dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduZzIuY3J0MB0GA1Ud
# DgQWBBTwJ4K6WNfB5ea1nIQDH5+tzfFAujAfBgNVHSMEGDAWgBQIbti2nIq/7T7X
# w3RdzIAfqC9QejANBgkqhkiG9w0BAQUFAAOCAQEAB3ZotjKh87o7xxzmXjgiYxHl
# +L9tmF9nuj/SSXfDEXmnhGzkl1fHREpyXSVgBHZAXqPKnlmAMAWj0+Tm5yATKvV6
# 82HlCQi+nZjG3tIhuTUbLdu35bss50U44zNDqr+4wEPwzuFMUnYF2hFbYzxZMEAX
# Vlnaj+CqtMF6P/SZNxFvaAgnEY1QvIXI2pYVz3RhD4VdDPmMFv0P9iQ+npC1pmNL
# mCaG7zpffUFvZDuX6xUlzvOi0nrTo9M5F2w7LbWSzZXedam6DMG0nR1Xcx0qy9wY
# nq4NsytwPbUy+apmZVSalSvldiNDAfmdKP0SCjyVwk92xgNxYFwITJuNQIto4zGC
# BK4wggSqAgEBMGcwUTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExJzAlBgNVBAMTHkdsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBHMgIS
# ESFgd9/aXcgt4FtCBtsrp6UyMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQqESqInIB/ddifgpZz
# a8OLYmZNPjANBgkqhkiG9w0BAQEFAASCAQA+rgGClGj5kpNDzZudtjODzmhZgt5x
# KbgmZsxuQiLYaqK+HaEBRhp6PBOZCK10Qsyjb/Qd6vYD19htORPIXfgBMIueDbIB
# g4fosu2hHLBBPvuzJBjZKiDUlfZT+MA4p62mkC6q9/x/SgLLaCBU1F1HFHuGA8WV
# JC++YtCisww71g5xnAGgDSvUw+dDtiLNqlYUl0PMWlB60HMS7i+xFoSbufDEZQrH
# T+jfcbImEaeh6wCiV2XWS3hF++TZGJHqDc3A8uRrsMmxvgcaEvgSEpHMY83tXpIf
# aWmE3ysIri7/LYf6YKtJ7G8LM15MxKhO8YoNRpf0P999H+s36VYpBWeUoYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhQFwfDtJYiCvlTYaGuhHqRTAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE0MTEy
# NjA3Mzg1NFowIwYJKoZIhvcNAQkEMRYEFBTvI41mori1MYmU1VpCfSU4G7aGMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUjOafUBLh0aj7OV4uMeK0K947NDsw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhQFwf
# DtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQEFAASCAQB0NBjCBH1cH7iKeC6k5FJD
# 9Fa+k4tUPSOQ8D4z0Pg3j3/i+aqnPiqt4PasCrvTZhrVJIZHrwTtK/3q0xH6kn2z
# iYouCadxu8VLXRMRor24lnIwughukNgwGNOxvaepWetIQ02Nm7R+rVqP1Y0uqA+C
# fE81VmkOCZA8JqNZu/SAir/pGw3h03WLG/TpC7PqLV3lFWoFL1LBkN8Km7YSfH9u
# 9eVDRBGjC6Xs9JVyJ4GQ5JmevgpXmFycHLlFja+Ui+zdRGLy6WxV9cQebhY5RFSP
# w7BZoKxTP/M1iLIzefZSErj+eGj1QZ+dTpCP3dh0EaNndH2f95uCMISC0GtBdBqt
# SIG # End signature block
