Function script:Format-Passwords {
#Generate passwords to meet default Server 2012 R2 complexity requirements - https://technet.microsoft.com/en-us/library/cc786468(v=ws.10).aspx
  $RandomInputSymbol = $(ForEach ($Char in @(32..47+58..64+91..96+123..126)){[char]$Char}) | Get-Random -count 2
  $RandomInputNum = $(ForEach ($Char in @(48..57)){[char]$Char}) | Get-Random -count 2
  $RandomInputUpper = $(ForEach ($Char in @(65..90)){[char]$Char}) | Get-Random -count 4
  $RandomInputLower = $(ForEach ($Char in @(97..122)){[char]$Char}) | Get-Random -count 4
  $PasswordArrComplete = $RandomInputSymbol+$RandomInputNum+$RandomInputUpper+$RandomInputLower
  $Random = New-Object Random
  Return $Password = [string]::join("",($PasswordArrComplete | sort {$Random.Next()}))
}

Function script:Add-ADUsers {

}

Function script:Add-LocalUsers {
  $PW = Format-Passwords
  Write-Host $PW -ForegroundColor Green
  $Computername = $env:COMPUTERNAME
  $ADSIComp = [adsi]"WinNT://$Computername"
  $Username = 'TestDude97'
  $NewUser = $ADSIComp.Create('User',$Username)
  $NewUser.SetPassword($PW)
  $NewUser.SetInfo()
  $NewUser.Description = 'Test Account'
  $NewUser.SetInfo()
}

Function script:Test-LocalCredential {
#Thanks to Jaap Brasser - https://gallery.technet.microsoft.com/scriptcenter/Verify-the-Local-User-1e365545
    [CmdletBinding()]
    Param
    (
        [string]$UserName,
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$Password
    )
    if (!($UserName) -or !($Password)) {
        Write-Warning 'Test-LocalCredential: Please specify both user name and password'
    } else {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$ComputerName)
        $DS.ValidateCredentials($UserName, $Password)
    }
}

Function script:Validate-Users {
$Event = Get-WinEvent -ComputerName $env:computername -FilterHashtable @{Logname='Security';Id=4720} -MaxEvents 1
$EventXML = [xml]$Event.ToXml()
$script:TimeCreated = $Event.TimeCreated.DateTime
$script:SAMAccountName = $EventXML.Event.EventData.Data[8].'#text'
}
Invoke-Command -ScriptBlock {. Validate-Users}
