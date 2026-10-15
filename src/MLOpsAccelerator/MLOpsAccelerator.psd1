@{
    RootModule           = 'MLOpsAccelerator.psm1'
    ModuleVersion        = '0.2.0'
    GUID                 = '5d0c2f6e-8a49-4b5e-9f0e-3a7e2c1b6d41'
    Author               = 'MLOps v3 contributors'
    Description          = 'Generates a complete, parameter-driven MLOps repository (bootstrap, IaC, CI/CD and workload) for Azure Machine Learning.'
    PowerShellVersion    = '7.4'
    RequiredModules      = @(@{ ModuleName = 'powershell-yaml'; ModuleVersion = '0.4.7' })
    FunctionsToExport    = @('Test-MLOpsAcceleratorRequirement', 'Remove-MLOpsAccelerator', 'Grant-MLOpsStorageAccess', 'Get-MLOpsScenario', 'New-MLOpsInputFile', 'Deploy-MLOpsAccelerator', 'Test-MLOpsAcceleratorInput', 'Test-MLOpsAcceleratorVersion', 'Update-MLOpsAcceleratorVersion')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    CompanyName          = 'Microsoft Corporation'
    Copyright            = '(c) Microsoft Corporation. MIT License.'
    PrivateData          = @{ PSData = @{
            Tags         = @('mlops', 'azure', 'azureml', 'machine-learning', 'terraform', 'bicep', 'avm', 'github-actions', 'azure-devops', 'PSEdition_Core')
            LicenseUri   = 'https://github.com/pgabriel-01/mlops-v3/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/pgabriel-01/mlops-v3'
            ReleaseNotes = 'https://github.com/pgabriel-01/mlops-v3/releases'
        } }
}
