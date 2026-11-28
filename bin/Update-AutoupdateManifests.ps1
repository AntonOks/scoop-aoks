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
    [BOOL]$failed = $False

    IF ( -NOT $env:SCOOP_HOME ) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
    $checkverScript = "$env:SCOOP_HOME\bin\checkver.ps1"
    IF ( -NOT (Test-Path -Path $checkverScript) ) {
        Write-Host "  ERROR - `"$checkverScript`" is required but cannot be found."
        EXIT 1
    }

    $BucketDir = (Resolve-Path -Path $BucketDir).Path
}
#
process {
    $apps = IF ( $Manifests ) { $Manifests } ELSE { @('*') }
    [ARRAY]$manifestsStatus = @(
        FOREACH ( $app in $apps ) {
            & $checkverScript -App $app -Dir $BucketDir 6>&1
        }
    )

    FOR ( $i=0; $i -lt $manifestsStatus.length; ) {
        IF ( $Verbose ) { Write-Host "   INFO - Working on line NR $i" }

        IF ( $manifestsStatus[$i] -match "(?<TOOL>.+):" ) {
            $TOOL = $Matches.TOOL
            $VERSION = $manifestsStatus[$i + 1]
            IF ( $Verbose ) { Write-Host "   INFO - `$TOOL is `"$TOOL`", `$VERSION is `"$VERSION`"" }

            IF ( $manifestsStatus[$i + 3] -match " autoupdate available" ) {
                IF ( -NOT $GITPULLED ) {
                    & git pull --ff-only -q
                    IF ( $LASTEXITCODE -ne 0 ) {
                        Write-Host "  ERROR - 'git pull --ff-only' failed (exit code $LASTEXITCODE). Aborting."
                        EXIT 1
                    }
                    $GITPULLED = $True
                }

                $manifestFile = Join-Path $BucketDir "${TOOL}.json"
                $updateOk = $True
                TRY {
                    IF ( (Get-Content $manifestFile -Raw) -match '\$match' ) {
                        # autoupdate uses '$match*' variables, which only a full check populates
                        & $checkverScript -App $TOOL -Dir $BucketDir -Update -ThrowError
                    } ELSE {
                        # reuse the version from the initial check: no second request, no version drift
                        & $checkverScript -App $TOOL -Dir $BucketDir -Update -Version $VERSION -ThrowError
                    }
                } CATCH {
                    Write-Host "  ERROR - update failed for ${TOOL}: $($_.Exception.Message)"
                    $failed = $True
                    $updateOk = $False
                }

                IF ( $updateOk ) {
                    $VERSION = (Get-Content $manifestFile -Raw | ConvertFrom-Json).version

                    IF ( -NOT $env:I_AM_A_GITHUB_ACTION ) {
                      & git add $manifestFile
                      IF ( $LASTEXITCODE -ne 0 ) { $failed = $True }
                      & git commit -m "${TOOL}: Update to $VERSION"
                      IF ( $LASTEXITCODE -ne 0 ) { $failed = $True } ELSE { $GITDOPUSH = $True }
                    }
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

    IF ( $GITDOPUSH ) {
        & git push -q
        IF ( $LASTEXITCODE -ne 0 ) {
            Write-Host "  ERROR - 'git push' failed (exit code $LASTEXITCODE)."
            $failed = $True
        }
    }

    IF ( $failed ) { EXIT 1 } ELSE { EXIT 0 }
}
