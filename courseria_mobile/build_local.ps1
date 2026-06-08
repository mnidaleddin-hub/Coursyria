$env:PUB_CACHE="d:\Coursyria\local_pub_cache"
$env:PUB_HOSTED_URL="https://pub.dev"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.googleapis.com"
# Use default GRADLE_USER_HOME (C:\Users\EXCELLENT COMPUTER\.gradle)
$env:JAVA_HOME="D:\Program FilesAndroid\Android Studio\jbr"
$env:ANDROID_HOME="C:\Users\EXCELLENT COMPUTER\AppData\Local\Android\Sdk"
$env:GRADLE_OPTS="-Dhttp.proxyHost= -Dhttp.proxyPort= -Dhttps.proxyHost= -Dhttps.proxyPort="

flutter build apk --release --no-tree-shake-icons --no-pub --verbose > build_log_v3.txt 2>&1
