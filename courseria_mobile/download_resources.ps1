$urls = @(
    "https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.3.0/gradle-8.3.0.jar",
    "https://dl.google.com/dl/android/maven2/com/android/tools/build/builder/8.3.0/builder-8.3.0.jar",
    "https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/1.9.24/kotlin-gradle-plugin-1.9.24-gradle82.jar",
    "https://dl.google.com/dl/android/maven2/com/android/tools/build/bundletool/1.15.6/bundletool-1.15.6.jar",
    "https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-compiler-embeddable/1.9.24/kotlin-compiler-embeddable-1.9.24.jar"
)

$localDir = "d:\Coursyria\local_maven"
if (!(Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir
}

foreach ($url in $urls) {
    $fileName = [System.IO.Path]::GetFileName($url)
    $dest = Join-Path $localDir $fileName
    
    $success = $false
    $retries = 0
    while (!$success -and $retries -lt 20) {
        try {
            Write-Host "Downloading $fileName (Attempt $($retries + 1))..."
            # Use curl.exe with resume capability
            & curl.exe -L -C - -o $dest $url --retry 5 --retry-delay 2
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                Write-Host "Successfully downloaded $fileName"
            } else {
                throw "Curl exited with code $LASTEXITCODE"
            }
        } catch {
            Write-Warning "Failed to download $($fileName): $($_.Exception.Message)"
            $retries++
            Start-Sleep -Seconds 2
        }
    }
}
