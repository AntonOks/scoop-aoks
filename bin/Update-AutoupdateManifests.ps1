<#
.SYNOPSIS
    Updates one or more manifests and pushes them to your scoop GIT repo.
.DESCRIPTION
    Uses checkver.ps1 to find manifests, which have an "update available", updates them one after the other, commits them to your GIT repo and and pushes them to your ORIGIN.
.PARAMETER Manifests
    Specify manifest(s) to be updated.
.PARAMETER BucketDir
    Specify directory with manifests.
#>

param(
    [Alias('App', 'Name')]
    [String[]] $Manifests,
    [Alias('V')]
    [Switch] $Verbose,

    [Alias('BD')]
    [ValidateScript( { if ( Test-Path $_ -Type Container) { $true } else { $false } })]
    [String] $BucketDir = "$PSScriptRoot\..\bucket"
)
#
begin {
    [BOOL]$GITPULLED = $False
    [BOOL]$GITDOPUSH = $False

    IF ( $PSScriptRoot ) { $ScriptRoot = $PSScriptRoot} ELSE { $ScriptRoot = Get-Location }

    IF ( -NOT(Test-Path -Path $ScriptRoot\checkver.ps1) ) {
        Write-Host "  ERROR - `"$ScriptRoot\checkver.ps1`" is required but cannot be found."
        EXIT
    } ELSE {
        $checkverScript = "$ScriptRoot\checkver.ps1"
    }
}
#
process {
    [ARRAY]$manifestsStatus = @(& $checkverScript * 6>&1)

    FOR ( $i=0; $i -lt $manifestsStatus.length; ) {
        IF ( $Verbose ) { Write-Host "   INFO - Working on line NR $i" }

        IF ( $manifestsStatus[$i] -match "(?<TOOL>.+):" ) {
            $TOOL = $Matches.TOOL
            $VERSION = $manifestsStatus[$i + 1]
            IF ( $Verbose ) { Write-Host "   INFO - `$TOOL is `"$TOOL`", `$VERSION is `"$VERSION`"" }

            IF ( $manifestsStatus[$i + 3] -match " autoupdate available" ) {
                IF ( -NOT ($GITPULLED) | Out-Null ) { ( & git pull -q) -and ( $GITPULLED = $True ) }
                & $ScriptRoot\checkver.ps1 $TOOL -u

                IF ( -NOT $env:I_AM_A_GITHUB_ACTION ) {
                  & git add $ScriptRoot\..\bucket\${TOOL}.json
                  & git commit -m "${TOOL}: Update to $VERSION"
                  $GITDOPUSH = $True
                }
                $i = $i + 4
            } ELSE { $i = $i + 2 }
        } ELSE {
            $i++
        }
    }

<# IF ( $manifestsStatus[$i] -ne "DONE" ) {
    Write-Host " ERROR - Seems like parsing of the `$manifestsStatus ARRAY wasn't succesful, please check"
    Write-Host "         Last line was `"$manifestsStatus[$i]`""
} #>

    IF ( $GITDOPUSH ) { & git push -q}

    EXIT 0 #force $LastExitCode to be 0 :|
}
