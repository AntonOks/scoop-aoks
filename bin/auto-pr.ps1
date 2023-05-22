param(
    # overwrite upstream param
<<<<<<< HEAD
    [String]$upstream = "AntonOks/scoop-aoks:master"
)

if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
Invoke-Expression -command "& '$autopr' -dir '$dir' -upstream $upstream $($args | ForEach-Object { "$_ " })"
=======
    [String]$upstream = "<username>/<bucketname>:main"
)

if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$PSScriptRoot/../bucket" # checks the parent dir
& $autopr -Dir $dir -Upstream $Upstream @Args
>>>>>>> template_origin/master
