[CmdletBinding()]
    param(
		[Parameter(mandatory=$true, HelpMessage="Specify the number of users to create")]
		[Alias("users")]
        [int]$NumUsers,
    [Parameter(HelpMessage="Specify the company name")]
    [Alias("co")]
        [string]$CompanyName = "Evil Corp",
    [Parameter(HelpMessage="Specify the users' nationalities")]
    [Alias("nat")]
        [string]$Nationalities = "US"
		)

Try {
  Import-Module ActiveDirectory -ErrorAction Stop
}
Catch [Exception] {
  Return $_.Exception.Message
}

$RandomUsersArr = New-Object System.Collections.ArrayList
$Date = Get-Date -format M.dd.yyyy
$DomainInfo = Get-ADDomain
$UsersOU=$DomainInfo.UsersContainer
$UPNSuffix = "@" + $DomainInfo.DNSRoot

Try {
  $RandomUsers = Invoke-RestMethod "https://www.randomuser.me/api/?results=$NumUsers&nat=$Nationalities" | select -ExpandProperty Results
}
Catch [Exception] {
  Return $_.Exception.Message
}

Function script:Format-Passwords {
#Generate passwords to meet default Server 2012 R2 complexity requirements - https://technet.microsoft.com/en-us/library/cc786468(v=ws.10).aspx
  $RandomInputSymbol = $(ForEach ($Char in @(32..47+58..64+91..96+123..126)){[char]$Char}) | Get-Random -count 2
  $RandomInputNum = $(ForEach ($Char in @(48..57)){[char]$Char}) | Get-Random -count 2
  $RandomInputUpper = $(ForEach ($Char in @(65..90)){[char]$Char}) | Get-Random -count 4
  $RandomInputLower = $(ForEach ($Char in @(97..122)){[char]$Char}) | Get-Random -count 4
  $PasswordArrComplete = $RandomInputSymbol+$RandomInputNum+$RandomInputUpper+$RandomInputLower
  $Random = New-Object Random
  $Password = [string]::join("",($PasswordArrComplete | sort {$Random.Next()}))
  $script:PlainTextPW = @{
    "PlainPW" = $Password
  }
  Return $Password | ConvertTo-SecureString -AsPlainText -Force
}

ForEach ($RandomUser in $RandomUsers) {
  $First = $RandomUser.Name.First.Substring(0,1).ToUpper()+$RandomUser.Name.First.Substring(1).ToLower()
  $Last = $RandomUser.Name.Last.Substring(0,1).ToUpper()+$RandomUser.Name.Last.Substring(1).ToLower()

  $UserProperties = @{
  "GivenName" = $First
  "Surname" = $Last
  "Name" = $First + " " + $Last
  "DisplayName" = $First + " " + $Last
  "OfficePhone" = $RandomUser.Phone
  "City" = $RandomUser.Location.City
  "State" = $RandomUser.Location.State
  "Country" = $Nationalities
  "Company" = $CompanyName
  "SAMAccountName" = $Last + $First[0]
  "UserPrincipalName" = $Last + $First[0] + $UPNSuffix
  "AccountPassword" = . Format-Passwords
  "Enabled" = $True
  "ChangePasswordAtLogon" = $False
  "Description" = "Test Account Generated $Date"
  "Path" = $UsersOU
  }

  New-ADUser @UserProperties
  $UserPropertiesObj = New-Object PSObject -Property $UserProperties
  $UserPropertiesObj | Add-Member $PlainTextPW
  $RandomUsersArr.Add($UserPropertiesObj) | Out-Null #Add the object to the array

} #End ForEach

$RandomUsersArr | Export-CSV $env:UserProfile\Desktop\UserCreation.csv -Append -NoTypeInformation
