$env:HTTP_PROXY="http://10.90.216.56:7071"
$env:HTTPS_PROXY="http://10.90.216.56:7071"
$env:GRADLE_OPTS="-Dhttp.proxyHost=10.90.216.56 -Dhttp.proxyPort=7071 -Dhttps.proxyHost=10.90.216.56 -Dhttps.proxyPort=7071"
echo "Starting build..."
flutter build apk --release --split-per-abi --no-tree-shake-icons
