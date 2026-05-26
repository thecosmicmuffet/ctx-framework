#!/usr/bin/env pwsh
param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
& (Join-Path $PSScriptRoot 'chart.ps1') -Dock @Args
