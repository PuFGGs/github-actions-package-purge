# GitHub Package Purge Script - Using GitHub CLI

# Replace this variable with your organization name
$orgName = "change-me"

# Enable TLS 1.2 for compatibility with GitHub's API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to make API calls with error handling
function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Endpoint,
        [switch]$Paginate
    )
    try {
        if ($Method -eq "GET" -and $Paginate) {
            $result = gh api -X $Method $Endpoint --paginate
        } else {
            $result = gh api -X $Method $Endpoint
        }
        return $result | ConvertFrom-Json
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Error calling $Method $Endpoint. Error: $errorMessage" -ForegroundColor Red
        return $null
    }
}

# Function to get all package types available in the organization
function Get-PackageTypes {
    $types = @("npm", "maven", "rubygems", "docker", "nuget", "container")
    $availableTypes = @()
    foreach ($type in $types) {
        $result = Invoke-GitHubApi -Method GET -Endpoint "orgs/$orgName/packages?package_type=$type" -Paginate
        if ($null -ne $result -and $result.Count -gt 0) {
            $availableTypes += $type
        }
    }
    return $availableTypes
}

# Function to get all packages of a specific type in the organization
function Get-OrganizationPackages {
    param($packageType)
    $packages = Invoke-GitHubApi -Method GET -Endpoint "orgs/$orgName/packages?package_type=$packageType" -Paginate
    if ($null -eq $packages) {
        Write-Host "Failed to retrieve $packageType packages for organization $orgName. Please check your permissions." -ForegroundColor Yellow
    }
    return $packages
}

# Function to get all versions of a package
function Get-PackageVersions {
    param($packageName, $packageType)
    $versions = Invoke-GitHubApi -Method GET -Endpoint "orgs/$orgName/packages/$packageType/$packageName/versions" -Paginate
    if ($null -eq $versions) {
        Write-Host "Failed to retrieve versions for package $packageName. This package might not have any versions." -ForegroundColor Yellow
    }
    return $versions
}

# Function to delete a specific version of a package
function Remove-PackageVersion {
    param($packageName, $packageType, $versionId)
    $result = Invoke-GitHubApi -Method DELETE -Endpoint "orgs/$orgName/packages/$packageType/$packageName/versions/$versionId"
    if ($null -eq $result) {
	Write-Host "Successfully deleted version $versionId of package $packageName." -ForegroundColor Green
    }
    else {
        Write-Host "Failed to delete version $versionId of package $packageName." -ForegroundColor Yellow
    }
}

# Main script execution
Write-Host "Script started. Retrieving package types for organization: $orgName" -ForegroundColor Cyan

$packageTypes = Get-PackageTypes

if ($packageTypes.Count -eq 0) {
    Write-Host "No package types found or unable to access packages. Exiting script." -ForegroundColor Red
    exit
}

foreach ($packageType in $packageTypes) {
    Write-Host "Processing $packageType packages" -ForegroundColor Cyan
    $packages = Get-OrganizationPackages -packageType $packageType

    if ($null -eq $packages) {
        Write-Host "No $packageType packages found. Moving to next package type." -ForegroundColor Yellow
        continue
    }

    foreach ($package in $packages) {
        Write-Host "Processing package: $($package.name)" -ForegroundColor Cyan
        $versions = Get-PackageVersions -packageName $package.name -packageType $packageType
        
        if ($null -eq $versions) {
            Write-Host "No versions found for package $($package.name). Moving to next package." -ForegroundColor Yellow
            continue
        }

        # Sort versions by creation date (descending) and skip the first (latest) version
        $versionsToDelete = $versions | Sort-Object created_at -Descending | Select-Object -Skip 1
        
        foreach ($version in $versionsToDelete) {
            Write-Host "Attempting to delete version $($version.id) of package $($package.name)" -ForegroundColor Cyan
            Remove-PackageVersion -packageName $package.name -packageType $packageType -versionId $version.id
        }
    }
}

Write-Host "Package purge completed." -ForegroundColor Green
