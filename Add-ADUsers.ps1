Function script:Format-Passwords {
  $CharSetRangeSymbol = @(32..47+58..64+91..96+123..126)
  $CharSetRangeUpper = @(65..90)
  $CharSetRangeLower = @(97..122)
  $RandomInputSymbol = ForEach ($Char in $CharSetRangeSymbol){[char]$Char}
  $RandomInputUpper = ForEach ($Char in $CharSetRangeUpper){[char]$Char}
  $RandomInputLower = ForEach ($Char in $CharSetRangeLower){[char]$Char}
  $PasswordArrSymbol = Get-Random -Input $RandomInputSymbol -count 2
  $PasswordArrUpper = Get-Random -Input $RandomInputUpper -count 5
  $PasswordArrLower = Get-Random -Input $RandomInputLower -count 5
  $PasswordArrComplete = $PasswordArrSymbol+$PasswordArrUpper+$PasswordArrLower
  $Random = New-Object Random
  Return $Password = [string]::join("",($PasswordArrComplete | sort {$Random.Next()}))
}

Function script:Add-ADUsers {

}

Function script:Add-LocalUsers {
  $PW = Format-Passwords2
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
#Thanks to Boe Prox - https://mcpmag.com/articles/2015/05/07/local-user-accounts-with-powershell.aspx
  $xml = '
  <QueryList>
  <Query  Id="0" Path="Security">
  <Select  Path="Security">*[System[(EventID=4720)]]</Select>
  </Query>
  </QueryList>
  '
Get-WinEvent -FilterXml $xml |  Select -Expand Message
}