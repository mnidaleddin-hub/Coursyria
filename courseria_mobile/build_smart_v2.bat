@echo off
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set PUB_CACHE=d:\Coursyria\local_pub_cache
echo Starting Clean...
call flutter clean
echo Starting Build...
call flutter build apk --release --split-per-abi -v > build_final_smart.log 2>&1
echo Done.
