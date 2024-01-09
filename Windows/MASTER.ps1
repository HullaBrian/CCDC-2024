$hosts_path = ".\hosts.txt"
$scripts_path = ".\scripts\"

$hosts = Get-Content -Path "$hosts_path"
# Create output folder for script
foreach ($line in $lines) {
    $line_name = $line -replace '\.', '-'
    $_ = New-Item -ItemType Directory -Path ".\out\$line_name" -Force
}

$scripts = Get-ChildItem -Path "$scripts_path" -Filter *.ps1

foreach ($script in $scripts) {
    foreach($endpoint in $hosts) {
        Write-Host "Executing '$script' on all '$endpoint'"

        $out_name = $endpoint -replace '\.', '-'
        $script_name = $script -replace ".ps1", ""
        $output_file = ".\out\$out_name\$script_name.txt"
        $_ = New-Item -ItemType File -Path "$output_file" -Force

        $parameters = @{
            ComputerName = "$endpoint"
            FilePath     = "$scripts_path" + $script
            ArgumentList = 'Process', 'Service'
        }
        $result = Invoke-Command @parameters
        $result | Add-Content -Path "$output_file" -Encoding UTF8
    }
}