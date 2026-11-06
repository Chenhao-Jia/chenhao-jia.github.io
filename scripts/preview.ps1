# Run from any directory: powershell -File <path-to-academic-site>\scripts\preview.ps1
$ErrorActionPreference = 'Stop'
$siteRoot = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) {
    $localRuntime = Join-Path (Split-Path -Parent $siteRoot) '.local\use-ruby.ps1'
    if (Test-Path -LiteralPath $localRuntime) { . $localRuntime }
}
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    throw 'Ruby 3.3.13 / Bundler 2.5.22 is required. See README.md.'
}
Push-Location -LiteralPath $siteRoot
try {
    bundle check
    if ($LASTEXITCODE -ne 0) { throw 'Run bundle install first; see README.md.' }
    bundle exec ruby scripts/generate_bibtex.rb --check
    if ($LASTEXITCODE -ne 0) { throw 'BibTeX is stale. Run bundle exec ruby scripts/generate_bibtex.rb after editing publication data.' }
    bundle exec ruby scripts/validate_content.rb --mode preview
    if ($LASTEXITCODE -ne 0) { throw 'Content validation failed.' }
    bundle exec jekyll serve --config _config.yml,_config.preview.yml --host 127.0.0.1 --port 4000 --no-watch
    if ($LASTEXITCODE -ne 0) { throw 'Jekyll preview failed.' }
}
finally { Pop-Location }
