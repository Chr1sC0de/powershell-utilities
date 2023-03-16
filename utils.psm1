
function Invoke-FuzzySetLocation {
    param(
      [string]$path,
      [string]$arguments="-d '2' -H -I"
    )
    $base = "fd -t 'd' $arguments"

    Invoke-Expression $base `
    | ForEach-Object {"$_"} `
    | fzf --layout=reverse --preview "$env:SHELL -command . ""$PROFILE""; get-childitem {} | bat -f "`
    | Set-Location
}


function Invoke-FuzzyEditFile {
  param (
    [string]$path,
    [string]$a=""
  )
  $fd_command = "fd -t 'f' $a"

  Invoke-Expression $fd_command `
  | fzf --layout=reverse --preview "$env:SHELL -command . ""$PROFILE""; bat --color='always' """"{}""""" `
  | ForEach-Object {code -g "$_"}

}


function Invoke-RGFuzzyEditLine {
  param(
    [Parameter(Mandatory=$true)]
    [string] $p,
    [string] $a=""
  )

  $rg_command = "rg $p --path-separator '/' --field-match-separator ' :: ' -n $a"

  Invoke-Expression $rg_command `
  | ForEach-Object {$_ -replace """", "'"} `
  | ForEach-Object { $_ -replace '`', ''''} `
  | fzf --layout=reverse --preview "$env:SHELL -command . ""$PROFILE""; Invoke-BatPreview """"{}""""" `
  | select-string -Pattern "(.+?) \:+? (\d+?) \:+?" `
  | ForEach-Object {"$($_.Matches.Groups[1].Value):$($_.Matches.Groups[2].Value)"} `
  | ForEach-Object {code -g $_}

}


function Invoke-FuzzyEditLine {
  param(
    [Parameter(Mandatory=$true)]
    [string] $f,
    [string] $a=""
  )

  $counter = 0

  Get-Content $f `
  | ForEach-Object {$_ -replace """", "'"} `
  | ForEach-Object {$_ -replace '`', ''''} `
  | ForEach-Object {$counter += 1; "$counter :: $_"} `
  | fzf --layout=reverse --preview "$env:SHELL -command . ""$PROFILE"";  Invoke-BatPreview -s """"{}"""" -f """"$f""""" `
  | select-string -Pattern "(\d+?) \:+?" `
  | ForEach-Object {$_.Matches.Groups[1].Value} `
  | ForEach-Object {code -g "$f\:$_"}
}


function Invoke-BatPreview {
  param(
    [string]$s,
    [string]$f = ""
  )

    if (!($f -eq "")){
      $s = "$f :: $s"
    }

    $filename    = ($s | select-String -Pattern "(.+?) \:+?").Matches.Groups[1].Value
    $filename    = "$(Get-Item $filename|Resolve-Path -Relative)"
    $line_number = ($s | select-String -Pattern ".+? \:+? (\w+) \:+?").Matches.Groups[1].Value
    $lower_bound = (0, ($line_number-10) | Measure-Object -max).maximum
    $line_range  = "$($lower_bound):$($line_number+10)"

    bat --color 'always' $filename -r $line_range -H $line_number
}

function sclip {
  process {
    "$_" | Set-Clipboard
  }
}

Export-ModuleMember -Function `
  Invoke-FuzzySetLocation,
  Invoke-FuzzyEditFile,
  Invoke-RGFuzzyEditLine,
  Invoke-BatPreview,
  Invoke-FuzzyEditLine,
  sclip