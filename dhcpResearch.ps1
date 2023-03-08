# Author: Andy Koop
# Script Title: DHCP Research
# quick script; useful when we need connection stats for security and debugging; deletes old records
# run daily 

clear-host
#store records locally, but pull from across network
$homebase = split-path -parent $MyInvocation.MyCommand.Definition
$todor = get-date
$today = get-date -f "yyyy-MM-dd"
$servers= @("localserver1", "localserver2", "etc")

foreach ( $s in $servers ) {
$filename = $homebase + '\' + $s + $today + '-list.csv'
write-host "we are going to list leases for $s"

$snare = Get-DhcpServerv4Scope -ComputerName $s | Get-DhcpServerv4Lease -ComputerName $s | Where-Object {$_.LeaseExpiryTime -gt $todor }
$snare | foreach-object {
$_.ClientID = $_.ClientID.replace("-","")
}

$snare | select "IPAddress","ScopeId","AddressState","ClientId", "DNSregistration", "DNSrr", "LeaseExpiryTime", "HostName", "ServerIP" | export-csv $filename -NoTypeInformation

foreach ( $l in $snare ) {
$leaseexp = $l.LeaseExpiryTime
$scope = $l.ScopeId
$mac = $l.ClientId
$hosty = $l.HostName
$state = $l.AddressState
$out = $hosty + ' | ' + $mac + ' | ' + $leaseexp
write-host $out
}

}
$archive = $homebase + '\archive\'
Get-ChildItem $homebase -Recurse | ? {
  -not $_.PSIsContainer -and $_.CreationTime -lt $today -and $_.Name -like '*.csv*'
} | Move-Item -destination $archive
write-host 'Password files cleared out. Exiting.'

$limit = (Get-Date).AddDays(-180)

Get-ChildItem $archive -Recurse | ? {
  -not $_.PSIsContainer -and $_.CreationTime -lt $limit
} | Remove-Item
write-host 'Password files cleared out. Exiting.' 
