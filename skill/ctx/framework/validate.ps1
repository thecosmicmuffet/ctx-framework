#!/usr/bin/env pwsh
# Validation script for ctx framework integrity
# Run from anywhere — script locates itself via $PSScriptRoot

$ErrorActionPreference = 'Stop'

Write-Host "=== ctx Validation ===" -ForegroundColor Cyan
Write-Host ""

$frameworkPath = $PSScriptRoot
$testContextPath = Join-Path $PSScriptRoot ".validation-test-context"
$allPassed = $true

function Test-Condition {
    param(
        [string]$Description,
        [bool]$Condition
    )
    
    if ($Condition) {
        Write-Host "  ✅ $Description" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $Description" -ForegroundColor Red
        $script:allPassed = $false
    }
}

# Test 1: File Existence
Write-Host "Test 1: Required Files Exist" -ForegroundColor Yellow
$requiredFiles = @(
    "README.md",
    "TODOS.md",
    "bootstrap.sh",
    "bootstrap.ps1",
    "ctx",
    "ctx.ps1",
    "registry.json"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $frameworkPath $file
    Test-Condition "File exists: $file" (Test-Path $path)
}

Write-Host ""

# Test 2: Router Functionality
Write-Host "Test 2: Router Displays Commands" -ForegroundColor Yellow
try {
    $null = & "$frameworkPath\ctx.ps1" 2>&1
    Test-Condition "Router executes without error" ($LASTEXITCODE -eq 0)
} catch {
    Test-Condition "Router executes without error" $false
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""

# Test 3: Bootstrap Creates Structure
Write-Host "Test 3: Bootstrap Creates Valid Context" -ForegroundColor Yellow

# Clean up if test context exists
if (Test-Path $testContextPath) {
    Remove-Item $testContextPath -Recurse -Force
}

try {
    & "$frameworkPath\bootstrap.ps1" -ContextDir $testContextPath -ProjectName "validation-test" 2>&1 | Out-Null
    
    $expectedFiles = @(
        "state.json",
        "state.md",
        "decisions.json",
        "decisions.md",
        "todos.json",
        "history.md",
        "codebase.json",
        "codebase.md",
        "guide.md"
    )
    
    foreach ($file in $expectedFiles) {
        $path = Join-Path $testContextPath $file
        Test-Condition "Created: $file" (Test-Path $path)
    }
    
    Test-Condition "Created: handoffs directory" (Test-Path (Join-Path $testContextPath "handoffs"))
    
} catch {
    Test-Condition "Bootstrap executes without error" $false
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""

# Test 4: Content Validation
Write-Host "Test 4: Generated Content Quality" -ForegroundColor Yellow

try {
    $stateContent = Get-Content (Join-Path $testContextPath "state.md") -Raw
    Test-Condition "state.md contains project template" ($stateContent -like "*[Your Project Name]*")
    Test-Condition "state.md contains date" ($stateContent -match "\d{4}-\d{2}-\d{2}")
    Test-Condition "state.md has confidence section" ($stateContent -like "*Confidence Notes*")
    
    $decisionsContent = Get-Content (Join-Path $testContextPath "decisions.md") -Raw
    Test-Condition "decisions.md has template structure" ($decisionsContent -like "*Alternatives Considered*")
    
    $guideContent = Get-Content (Join-Path $testContextPath "guide.md") -Raw
    Test-Condition "guide.md has Quick Start section" ($guideContent -like "*Quick Start*")
    Test-Condition "guide.md references ctx CLI" ($guideContent -like "*ctx.ps1*")
    
} catch {
    Test-Condition "Content validation" $false
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""

# Test 5: Documentation Consistency
Write-Host "Test 5: Documentation Cross-References" -ForegroundColor Yellow

try {
    $readmeContent = Get-Content (Join-Path $frameworkPath "README.md") -Raw
    Test-Condition "README mentions bootstrap.ps1" ($readmeContent -like "*bootstrap.ps1*")
    Test-Condition "README has bootstrap instructions" ($readmeContent -like "*bootstrap*")
    Test-Condition "README examples call .ps1 files" ($readmeContent -like "*.ps1*")
    
    $todosContent = Get-Content (Join-Path $frameworkPath "TODOS.md") -Raw
    Test-Condition "TODOS.md tracks priorities" ($todosContent -like "*High Priority*")
    Test-Condition "TODOS.md has design goals" ($todosContent -like "*Design Goals*")
    
} catch {
    Test-Condition "Documentation validation" $false
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""

# Cleanup
Write-Host "Cleanup: Removing test context" -ForegroundColor Gray
if (Test-Path $testContextPath) {
    Remove-Item $testContextPath -Recurse -Force
    Write-Host "  Removed: $testContextPath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Validation Complete ===" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ctx is ready for code review." -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "❌ Some tests failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please review failures above before submitting for code review." -ForegroundColor Yellow
    exit 1
}
