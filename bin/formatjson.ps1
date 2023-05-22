<<<<<<< HEAD
if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$formatjson = "$env:SCOOP_HOME/bin/formatjson.ps1"
$path = "$psscriptroot/../bucket" # checks the parent dir
Invoke-Expression -command "& '$formatjson' -dir '$path' $($args | ForEach-Object { "$_ " })"
=======
if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
$formatjson = "$env:SCOOP_HOME/bin/formatjson.ps1"
$path = "$PSScriptRoot/../bucket" # checks the parent dir
& $formatjson -Dir $path @Args
>>>>>>> template_origin/master
