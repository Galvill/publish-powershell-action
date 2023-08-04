
if ($env:IMPORT_STRING) {
    Write-Host "Resource has dependencies, now importing them into the current session..."
    Invoke-Expression -Command $env:IMPORT_STRING
}

try {
    Write-Host "Registering NuGet repository..."
    Register-PSResourceRepository -Name "NuGet" -Uri $env:INPUT_NUGETURL -Trusted
}
catch {
    Write-Host "Registration failed, cleaning up and trying again..."
    Unregister-PSResourceRepository -Name "NuGet"
    Register-PSResourceRepository -Name "NuGet" -Uri $env:INPUT_NUGETURL -Trusted    
}

try {
    Write-Host "Publishing to NuGet repository...."
    write-host "Path: $env:RESOLVED_PATH"
    Get-Content $env:RESOLVED_PATH
    $PublishSplat = @{
        Path = $env:RESOLVED_PATH
        Repository = "NuGet"
        ApiKey = $env:INPUT_TOKEN
        SkipDependenciesCheck = $true
    }
    if ($env:RESOLVED_PATH -like "*.psd1") {
        $ManifestData = Import-PowerShellDataFile $env:RESOLVED_PATH
        if ($ManifestData.RequiredModules) {
            $PublishSplat += @{
                SkipModuleManifestValidate = $true
            }
        }
    }
    Publish-PSResource @PublishSplat
}
finally {
    Unregister-PSResourceRepository -Name "NuGet"
}


Write-Host "Done!"