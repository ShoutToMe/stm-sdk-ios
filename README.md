[![CocoaPods](https://img.shields.io/cocoapods/p/STM.svg)](https://cocoapods.org/pods/STM)
[![CocoaPods](https://img.shields.io/cocoapods/v/STM.svg)](https://cocoapods.org/pods/STM)
# Shout to Me iOS SDK

[Documenation](https://github.com/ShoutToMe/stm-sdk-ios/wiki)


##Release Workflow
```
$ cd ~/code/Pods/NAME
$ edit NAME.podspec
# set the new version to 0.0.1
# set the new tag to 0.0.1
$ pod lib lint

$ git add -A && git commit -m "Release 0.0.1."
$ git tag '0.0.1'
$ git push --tags
```
Once your tags are pushed you can use the command:
`pod trunk push NAME.podspec` to send your library to the Specs repo.
