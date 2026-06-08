$cacheBase = "C:\Users\EXCELLENT COMPUTER\.gradle\caches\modules-2\files-2.1"
$localMaven = "d:\Coursyria\local_maven"

$mappings = @(
    @{
        Group = "com.android.tools.build"; Name = "gradle"; Version = "8.3.0"; 
        Hash = "cb0cc4ee365545f762a0bae61b24c658e993921d"; FileName = "gradle-8.3.0.jar"
    },
    @{
        Group = "com.android.tools.build"; Name = "builder"; Version = "8.3.0"; 
        Hash = "8e1c898e72837e1e5c74f6f4bf7c37ce838b57a9"; FileName = "builder-8.3.0.jar"
    },
    @{
        Group = "com.android.tools.build"; Name = "bundletool"; Version = "1.15.6"; 
        Hash = "ec60643ef60e6a4d9436dce76f277f604f30c1c9"; FileName = "bundletool-1.15.6.jar"
    },
    @{
        Group = "org.jetbrains.kotlin"; Name = "kotlin-gradle-plugin"; Version = "1.9.24"; 
        Hash = "1605a44c973f2caf29ddd87d29cda7a37563820f"; FileName = "kotlin-gradle-plugin-1.9.24-gradle82.jar"
    },
    @{
        Group = "org.jetbrains.kotlin"; Name = "kotlin-compiler-embeddable"; Version = "1.9.24"; 
        Hash = "c73a9fbfd5ff3566cc6f2740d51d886b6960ce49"; FileName = "kotlin-compiler-embeddable-1.9.24.jar"
    }
)

foreach ($m in $mappings) {
    $destDir = Join-Path $cacheBase $m.Group
    $destDir = Join-Path $destDir $m.Name
    $destDir = Join-Path $destDir $m.Version
    $destDir = Join-Path $destDir $m.Hash
    
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force
    }
    
    $srcFile = Join-Path $localMaven $m.FileName
    $destFile = Join-Path $destDir $m.FileName
    
    Write-Host "Copying $($m.FileName) to $destDir..."
    Copy-Item -Path $srcFile -Destination $destFile -Force
}
