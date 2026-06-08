@echo off
set HTTP_PROXY=http://10.90.216.56:7071
set HTTPS_PROXY=http://10.90.216.56:7071
set ALL_PROXY=http://10.90.216.56:7071
set GRADLE_OPTS="-Dhttp.proxyHost=10.90.216.56 -Dhttp.proxyPort=7071 -Dhttps.proxyHost=10.90.216.56 -Dhttps.proxyPort=7071"
set JAVA_OPTS="-Dhttp.proxyHost=10.90.216.56 -Dhttp.proxyPort=7071 -Dhttps.proxyHost=10.90.216.56 -Dhttps.proxyPort=7071"

echo "Cleaning project..."
call flutter clean

echo "Getting packages..."
call flutter pub get

echo "Building APK..."
call flutter build apk --release --split-per-abi --no-tree-shake-icons
