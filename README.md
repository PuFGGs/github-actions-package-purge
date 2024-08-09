# GitHub Package Purge Script Documentation

## Purpose
This PowerShell script automates the process of purging older versions of GitHub Packages across all package types in a specified GitHub organization. It uses the GitHub CLI (gh) to interact with the GitHub API and perform the deletions, keeping only the latest version of each package.

## Requirements
- PowerShell 5.1 or later
- GitHub CLI (gh) installed and authenticated
- Appropriate permissions to access and modify packages in the target organization

## Installation
1. Ensure PowerShell is installed on your system.
2. Install the GitHub CLI by following the instructions at: https://cli.github.com/
3. Authenticate with GitHub CLI by running:
   ```
   gh auth login -s admin:org,write:packages,delete:packages
   ```
4. Save the script to a file with a .ps1 extension (e.g., `purge-packages.ps1`).

## Usage
1. Open the script in a text editor.
2. Replace the `$orgName` variable value with your GitHub organization name:
   ```powershell
   $orgName = "your-organization-name"
   ```
3. Open PowerShell.
4. Navigate to the directory containing the script.
5. Run the script:
   ```
   .\purge-packages.ps1
   ```

## What the Script Does
1. Enables TLS 1.2 for compatibility with GitHub's API.
2. Defines helper functions for API calls and error handling.
3. Retrieves all available package types in the organization (npm, maven, rubygems, docker, nuget, container).
4. For each package type:
   - Retrieves all packages of that type in the organization.
   - For each package:
     - Retrieves all versions of the package.
     - Sorts versions by creation date.
     - Deletes all versions except the latest one.

## Key Features
- Error handling and logging for API calls.
- Pagination support for handling large numbers of packages and versions.
- Preserves the latest version of each package.
- Supports multiple package types (npm, maven, rubygems, docker, nuget, container).

## Caution
- This script will delete ALL versions of packages except the latest one in the specified organization.
- Ensure you have the necessary permissions before running the script.
- Consider the potential impact on your team's workflows before deleting package versions.
- Always make sure you have backups or can recreate packages if needed.

## Customization
- To modify which versions are kept, adjust the logic in the main execution section:
  ```powershell
  $versionsToDelete = $versions | Sort-Object created_at -Descending | Select-Object -Skip 1
  ```
  For example, to keep the two latest versions, change `-Skip 1` to `-Skip 2`.

## Troubleshooting
- If you encounter permission errors, ensure your GitHub CLI is authenticated with an account that has the necessary permissions to manage packages in the organization.
- If the script fails to retrieve packages or versions, check your internet connection and GitHub's status page for any ongoing issues.

## Limitations
- The script processes packages in batches due to API pagination. For organizations with a very large number of packages, the script may take a considerable amount of time to complete.
