param(
	[string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$reportDirectory = Join-Path $projectRoot "test-reports"
$consoleReport = Join-Path $reportDirectory "gut-console.txt"
$standardOutput = Join-Path $reportDirectory ".gut-stdout.tmp"
$standardError = Join-Path $reportDirectory ".gut-stderr.tmp"

if (-not $GodotPath) {
	$command = Get-Command godot4 -ErrorAction SilentlyContinue
	if (-not $command) {
		$command = Get-Command godot -ErrorAction SilentlyContinue
	}
	if ($command) {
		$GodotPath = $command.Source
	}
}

if (-not $GodotPath) {
	$steamGodot = "D:\Monono\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
	if (Test-Path -LiteralPath $steamGodot) {
		$GodotPath = $steamGodot
	}
}

if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
	throw "Godot executable not found. Pass it with -GodotPath <path>."
}

$godotVersion = (& $GodotPath --version | Out-String).Trim()
if ($godotVersion -notmatch "^4\.6(?:\.|$)") {
	throw "Godot 4.6 is required by GUT 9.6.1. Detected: $godotVersion"
}

New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
$quotedProjectRoot = '"{0}"' -f $projectRoot

Push-Location $projectRoot
try {
	$process = Start-Process -FilePath $GodotPath -ArgumentList @(
		"--headless",
		"--path", $quotedProjectRoot,
		"--script", "res://addons/gut/gut_cmdln.gd",
		"-gexit"
	) -Wait -PassThru -NoNewWindow -RedirectStandardOutput $standardOutput -RedirectStandardError $standardError

	$output = @()
	if (Test-Path -LiteralPath $standardOutput) {
		$output += Get-Content -LiteralPath $standardOutput -Encoding UTF8
	}
	if (Test-Path -LiteralPath $standardError) {
		$output += Get-Content -LiteralPath $standardError -Encoding UTF8
	}
	$output = $output | ForEach-Object { $_ -replace "$([char]27)\[[0-?]*[ -/]*[@-~]", "" }
	$output | Tee-Object -FilePath $consoleReport
	$exitCode = $process.ExitCode
}
finally {
	Remove-Item -LiteralPath $standardOutput, $standardError -Force -ErrorAction SilentlyContinue
	Pop-Location
}

exit $exitCode
