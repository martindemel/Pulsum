Last login: Mon Nov 10 22:31:55 on ttys006
(base) martin.demel@Martins-MacBook-Pro ~ % cd desktop
(base) martin.demel@Martins-MacBook-Pro desktop % cd pulsum
(base) martin.demel@Martins-MacBook-Pro pulsum % cd pulsum
(base) martin.demel@Martins-MacBook-Pro pulsum % xcodebuild test \
  -project Pulsum.xcodeproj \
  -scheme Pulsum \
  -configuration Debug \
  -destination "id=E4A4F913-D2F4-47F1-A524-DD32C76D9DFD" \
  -derivedDataPath Build
Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild test -project Pulsum.xcodeproj -scheme Pulsum -configuration Debug -destination id=E4A4F913-D2F4-47F1-A524-DD32C76D9DFD -derivedDataPath Build

Resolve Package Graph


Resolved source packages:
  PulsumServices: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices @ local
  PulsumML: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML @ local
  PulsumData: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData @ local
  PulsumAgents: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents @ local
  PulsumUI: /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI @ local

ComputePackagePrebuildTargetDependencyGraph

Prepare packages

CreateBuildRequest

SendProjectDescription

CreateBuildOperation

ComputeTargetDependencyGraph
note: Building targets in dependency order
note: Target dependency graph (18 targets)
    Target 'PulsumUITests' in project 'Pulsum'
        ➜ Explicit dependency on target 'Pulsum' in project 'Pulsum'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
    Target 'PulsumTests' in project 'Pulsum'
        ➜ Explicit dependency on target 'Pulsum' in project 'Pulsum'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
    Target 'Pulsum' in project 'Pulsum'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
    Target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI_PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
    Target 'PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumUI_PulsumUI' in project 'PulsumUI'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
    Target 'PulsumUI_PulsumUI' in project 'PulsumUI' (no dependencies)
    Target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumAgents_PulsumAgents' in project 'PulsumAgents' (no dependencies)
    Target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices_PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumServices_PulsumServices' in project 'PulsumServices'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData_PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumData_PulsumData' in project 'PulsumData'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
    Target 'PulsumData_PulsumData' in project 'PulsumData' (no dependencies)
    Target 'PulsumServices_PulsumServices' in project 'PulsumServices' (no dependencies)
    Target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML_PulsumML' in project 'PulsumML'
    Target 'PulsumML' in project 'PulsumML'
        ➜ Explicit dependency on target 'PulsumML_PulsumML' in project 'PulsumML'
    Target 'PulsumML_PulsumML' in project 'PulsumML' (no dependencies)

GatherProvisioningInputs

CreateBuildDescription

ExecuteExternalTool /usr/bin/what -q /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc --version

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/momc --dry-run --action generate --swift-version 5.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --iphonesimulator-deployment-target 26.0 --module Pulsum /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.xcdatamodeld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/CoreDataGenerated/Pulsum

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -version_details

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -v -E -dM -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -x c -c /dev/null

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --print-asset-tag-combinations --output-format xml1 /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding --dry-run yes --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML --dry-run yes --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access

ExecuteExternalTool /Applications/Xcode.app/Contents/Developer/usr/bin/actool --version --output-format xml1

Build description signature: 92776547c5c08a01945e5cc54527febd
Build description path: /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/XCBuildData/92776547c5c08a01945e5cc54527febd.xcbuilddata
CreateBuildDirectory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-create-build-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator

CreateBuildDirectory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-create-build-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules

CreateBuildDirectory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/ExplicitPrecompiledModules
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-create-build-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/ExplicitPrecompiledModules

ClangStatCache /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-stat-cache /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache

CreateBuildDirectory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-create-build-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml

CreateBuildDirectory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-create-build-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-project-headers.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-project-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-own-target-headers.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-own-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-non-framework-target-headers.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyStaticMetadataFileList (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyMetadataFileList (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibPath-normal-arm64.txt (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibPath-normal-arm64.txt

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-target-headers.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-generated-files.hmap (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-generated-files.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/Entitlements-Simulated.plist (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/Entitlements-Simulated.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-OutputFileMap.json (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_const_extract_protocols.json (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/PulsumUI_PulsumUI.DependencyStaticMetadataFileList (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/PulsumUI_PulsumUI.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/PulsumUI_PulsumUI.DependencyMetadataFileList (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/PulsumUI_PulsumUI.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.DependencyMetadataFileList (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-project-headers.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-project-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.DependencyStaticMetadataFileList (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/empty-PulsumUITests.plist (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/empty-PulsumUITests.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-own-target-headers.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-own-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-generated-files.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-generated-files.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-target-headers.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-non-framework-target-headers.hmap (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/ProductTypeInfoPlistAdditions.plist (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/ProductTypeInfoPlistAdditions.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.LinkFileList (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-OutputFileMap.json (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftFileList (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests_const_extract_protocols.json (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftConstValuesFileList (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/Entitlements-Simulated.plist (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/Entitlements-Simulated.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.modulemap (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.modulemap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyStaticMetadataFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyMetadataFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_const_extract_protocols.json (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftConstValuesFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.LinkFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-OutputFileMap.json (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/resource_bundle_accessor.swift

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/PulsumUI_-352E04A98F4C2CD4_PackageProduct.DependencyStaticMetadataFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/PulsumUI_-352E04A98F4C2CD4_PackageProduct.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/PulsumUI_-352E04A98F4C2CD4_PackageProduct.DependencyMetadataFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/PulsumUI_-352E04A98F4C2CD4_PackageProduct.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyStaticMetadataFileList (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyStaticMetadataFileList

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumUI.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.modulemap (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyMetadataFileList (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-project-headers.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-project-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/Objects-normal/arm64/PulsumUI_-352E04A98F4C2CD4_PackageProduct.LinkFileList (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/Objects-normal/arm64/PulsumUI_-352E04A98F4C2CD4_PackageProduct.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-generated-files.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-generated-files.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-own-target-headers.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-own-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-target-headers.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-non-framework-target-headers.hmap (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-non-framework-target-headers.hmap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_const_extract_protocols.json (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftConstValuesFileList (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.LinkFileList (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-OutputFileMap.json (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/PulsumServices_PulsumServices.DependencyStaticMetadataFileList (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/PulsumServices_PulsumServices.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/PulsumServices_PulsumServices.DependencyMetadataFileList (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/PulsumServices_PulsumServices.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyStaticMetadataFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.modulemap (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.modulemap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyMetadataFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_const_extract_protocols.json (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.LinkFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftConstValuesFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-OutputFileMap.json (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/resource_bundle_accessor.swift

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.DependencyStaticMetadataFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.DependencyMetadataFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumML_PulsumML.DependencyStaticMetadataFileList (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumML_PulsumML.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumML_PulsumML.DependencyMetadataFileList (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumML_PulsumML.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/Objects-normal/arm64/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.LinkFileList (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/Objects-normal/arm64/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/39a63377b53c8b66e194146fb2de43a6.sb (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/39a63377b53c8b66e194146fb2de43a6.sb

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumServices.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.modulemap (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/079a4dfa7d3399f0918bb2529f5d001c.sb (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/079a4dfa7d3399f0918bb2529f5d001c.sb

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/cc933a43ebffd14ff88b1c5775d03947.sb (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/cc933a43ebffd14ff88b1c5775d03947.sb

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.modulemap (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.modulemap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/af497e3755155cc156c11c422bbcd42c.sb (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/af497e3755155cc156c11c422bbcd42c.sb

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyStaticMetadataFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyMetadataFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_const_extract_protocols.json (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftConstValuesFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.LinkFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-OutputFileMap.json (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/resource_bundle_accessor.swift

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/7331f322e34ae36ddd31dcb9e8c4245a.sb (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/7331f322e34ae36ddd31dcb9e8c4245a.sb

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/34b4e6741df757c2cd57e9f41a11bcae.sb (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/34b4e6741df757c2cd57e9f41a11bcae.sb

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/PulsumML_-352E04A98F5439D9_PackageProduct.DependencyMetadataFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/PulsumML_-352E04A98F5439D9_PackageProduct.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/PulsumML_-352E04A98F5439D9_PackageProduct.DependencyStaticMetadataFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/PulsumML_-352E04A98F5439D9_PackageProduct.DependencyStaticMetadataFileList

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumML.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.modulemap (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/Objects-normal/arm64/PulsumML_-352E04A98F5439D9_PackageProduct.LinkFileList (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/Objects-normal/arm64/PulsumML_-352E04A98F5439D9_PackageProduct.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.modulemap (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.modulemap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/PulsumData_PulsumData.DependencyStaticMetadataFileList (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/PulsumData_PulsumData.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/PulsumData_PulsumData.DependencyMetadataFileList (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/PulsumData_PulsumData.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyStaticMetadataFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyMetadataFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_const_extract_protocols.json (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftConstValuesFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.LinkFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-OutputFileMap.json (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/resource_bundle_accessor.swift

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/PulsumData_1B04D3771DDAAD0A_PackageProduct.DependencyStaticMetadataFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/PulsumData_1B04D3771DDAAD0A_PackageProduct.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/PulsumData_1B04D3771DDAAD0A_PackageProduct.DependencyMetadataFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/PulsumData_1B04D3771DDAAD0A_PackageProduct.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/PulsumAgents_PulsumAgents.DependencyMetadataFileList (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/PulsumAgents_PulsumAgents.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/Objects-normal/arm64/PulsumData_1B04D3771DDAAD0A_PackageProduct.LinkFileList (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/Objects-normal/arm64/PulsumData_1B04D3771DDAAD0A_PackageProduct.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/PulsumAgents_PulsumAgents.DependencyStaticMetadataFileList (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/PulsumAgents_PulsumAgents.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumData.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.modulemap (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.modulemap (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.modulemap

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyStaticMetadataFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyMetadataFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_const_extract_protocols.json (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_const_extract_protocols.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.LinkFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftConstValuesFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-OutputFileMap.json (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-OutputFileMap.json

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/resource_bundle_accessor.swift

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/PulsumAgents_68A450630B045BF4_PackageProduct.DependencyStaticMetadataFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/PulsumAgents_68A450630B045BF4_PackageProduct.DependencyStaticMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/PulsumAgents_68A450630B045BF4_PackageProduct.DependencyMetadataFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/PulsumAgents_68A450630B045BF4_PackageProduct.DependencyMetadataFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibInstallName-normal-arm64.txt (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibInstallName-normal-arm64.txt

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/Objects-normal/arm64/PulsumAgents_68A450630B045BF4_PackageProduct.LinkFileList (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/Objects-normal/arm64/PulsumAgents_68A450630B045BF4_PackageProduct.LinkFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumAgents.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.modulemap (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.modulemap /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftConstValuesFileList (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftConstValuesFileList

WriteAuxiliaryFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.LinkFileList (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    write-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.LinkFileList

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests-Runner.app/PlugIns/PulsumUITests.xctest (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests-Runner.app/PlugIns/PulsumUITests.xctest

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests-Runner.app/PlugIns/PulsumUITests.xctest/Frameworks (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests-Runner.app/PlugIns/PulsumUITests.xctest/Frameworks

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

CoreMLModelCompile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/ /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumSentimentCoreML.mlmodelc -D SCRIPT_OUTPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel -D SCRIPT_INPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/cc933a43ebffd14ff88b1c5775d03947.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/ --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist --container swift-package
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumSentimentCoreML.mlmodelc/coremldata.bin

CoreMLModelCompile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/ /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumFallbackEmbedding.mlmodelc -D SCRIPT_OUTPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel -D SCRIPT_INPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/af497e3755155cc156c11c422bbcd42c.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/ --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist --container swift-package
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumFallbackEmbedding.mlmodelc/coremldata.bin

CoreMLModelCodegen /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding/PulsumFallbackEmbedding.swift -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated -D SCRIPT_OUTPUT_ANCESTOR_14\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/7331f322e34ae36ddd31dcb9e8c4245a.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding/PulsumFallbackEmbedding.swift

CoreMLModelCodegen /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML/PulsumSentimentCoreML.swift -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated -D SCRIPT_OUTPUT_ANCESTOR_14\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/34b4e6741df757c2cd57e9f41a11bcae.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc generate /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist --container swift-package --language Swift --swift-version 6 --public-access
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML/PulsumSentimentCoreML.swift

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI_PulsumUI.build/empty-PulsumUI_PulsumUI.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle/Info.plist

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices_PulsumServices.build/empty-PulsumServices_PulsumServices.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle/Info.plist

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData_PulsumData.build/empty-PulsumData_PulsumData.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle/Info.plist

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle

CoreMLModelCompile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/ /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/PulsumSentimentCoreML.mlmodelc -D SCRIPT_OUTPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel -D SCRIPT_INPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_14\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/079a4dfa7d3399f0918bb2529f5d001c.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumSentimentCoreML.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/ --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist --container swift-package
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/PulsumSentimentCoreML.mlmodelc/coremldata.bin

CoreMLModelCompile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/ /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/sandbox-exec -D SCRIPT_OUTPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/PulsumFallbackEmbedding.mlmodelc -D SCRIPT_OUTPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist -D SCRIPT_INPUT_FILE_0\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel -D SCRIPT_INPUT_FILE_1\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel -D SCRIPT_INPUT_ANCESTOR_0\=/ -D SCRIPT_INPUT_ANCESTOR_1\=/Users -D SCRIPT_INPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_INPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_INPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_INPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_INPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages -D SCRIPT_INPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D SCRIPT_INPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources -D SCRIPT_INPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML -D SCRIPT_INPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources -D SCRIPT_OUTPUT_ANCESTOR_0\=/ -D SCRIPT_OUTPUT_ANCESTOR_1\=/Users -D SCRIPT_OUTPUT_ANCESTOR_2\=/Users/martin.demel -D SCRIPT_OUTPUT_ANCESTOR_3\=/Users/martin.demel/Desktop -D SCRIPT_OUTPUT_ANCESTOR_4\=/Users/martin.demel/Desktop/PULSUM -D SCRIPT_OUTPUT_ANCESTOR_5\=/Users/martin.demel/Desktop/PULSUM/Pulsum -D SCRIPT_OUTPUT_ANCESTOR_6\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build -D SCRIPT_OUTPUT_ANCESTOR_7\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build -D SCRIPT_OUTPUT_ANCESTOR_8\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SCRIPT_OUTPUT_ANCESTOR_9\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_10\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_11\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D SCRIPT_OUTPUT_ANCESTOR_12\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D SCRIPT_OUTPUT_ANCESTOR_13\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D SCRIPT_OUTPUT_ANCESTOR_14\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle -D SRCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D PROJECT_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D OBJROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex -D SYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products -D DSTROOT\=/tmp/PulsumML.dst -D SHARED_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PrecompiledHeaders -D CACHE_ROOT\=/var/folders/m_/nqk8g4cs5tz8t1yj2kglt8p80000gn/C/com.apple.DeveloperTools/26.1-17B55/Xcode -D CONFIGURATION_BUILD_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -D CONFIGURATION_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator -D LOCROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D LOCSYMROOT\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML -D INDEX_PRECOMPS_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/PrecompiledHeaders -D INDEX_DATA_STORE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -D TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D TARGET_TEMP_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build -D DERIVED_FILE_DIR\=/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/DerivedSources -f /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/39a63377b53c8b66e194146fb2de43a6.sb /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/coremlc compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Resources/PulsumFallbackEmbedding.mlmodel /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/ --deployment-target 26.0 --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --platform ios --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist --container swift-package
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/PulsumFallbackEmbedding.mlmodelc/coremldata.bin

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents_PulsumAgents.build/empty-PulsumAgents_PulsumAgents.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle/Info.plist

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumUI_PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumData_PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumServices_PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumAgents_PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/empty-PulsumML_PulsumML.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumFallbackEmbedding-CoreMLPartialInfo.plist -additionalcontentfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML_PulsumML.build/PulsumSentimentCoreML-CoreMLPartialInfo.plist -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle/Info.plist

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumML_PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle

SwiftDriver PulsumML normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumML -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumml -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_SwiftConcurrencyShims-3OVKLQ662NZ0BYP9EGMHASQ92.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftShims-2X592ERWUJ3992J17ZS3I302.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_float-2QTRYI2ZT4DDFNJAO5MFK51N7.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdbool-5RB0GQFTZ7OIHK0GDSI1X7P8N.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ptrcheck-1DZDMLFE4V2BKXO8T0ZASVUAY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_AvailabilityInternal-D6YLGETU9HHGD4DR5INYG7HR1.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ptrauth-3BEBUNFBHI9L0BSULB6YPR3N1.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stddef-3LSZFSABMOR9AZ3688Z9W0LK3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdarg-7D63LQ73GN14N9242DXXVYEQ3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation1-ECR7USM759MF4HKXZ06X7HIMH.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ExtensionFoundation-A5EE7LXI0CNSO41HMK33TMOO2.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation2-AU0HWZLTJS09SWOPC9O9HLS9U.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_limits-BN1J72OQWMTCO27D8PCY73OWJ.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdint-DG14DFWOIYLJVIHFR4CJKTZCD.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/sys_types-6LK4YHEAHA4K5NUVK7T15RWX1.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation3-BIQ50TS5W91QFQBCZ53VYMTF8.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdatomic-EA83KWIE7UBTIZO8ZXDI89DY8.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_inttypes-9SJ8CWZYT9QYZ5G23QPJBOVRV.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Darwin-3Q5SU92GILWFCBERUHS2X682W.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ObjectiveC-9D6G4L70LDTKU9TY4CW2EYACV.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/MachO-814NTI9BNNN76DCDOIG5D4A72.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os_object-BZMF5INQHF9SI2VIRI39ZLT1G.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os_workgroup-7A4AHY7QSOMZ7J3BENKJD7CCF.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Dispatch-7RGZ2ZLAAI0FHRTOK0XZXEED0.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreFoundation-47ULBE1FUNOI48E0S1ZFOX3FC.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/XPC-E9C000LKPNBWH9X25K05H7SX7.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/dnssd-C771EJP335OQZ7F8VD4DS135H.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os-ZJ1JLY11MLQ8U189BI04HRJ4.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CFNetwork-6KO6LK66F1UHUWSS2WI933T95.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Security-2GYZBSC63V6V15D9LUT6U6XGX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreGraphics-E3VVO6CBGIXIQC435F6J8DA04.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Foundation-2992D9R6AGDN0Y7I078NY906F.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ImageIO-43P6MSE7LBCPLWKLUBLAP9YPL.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Network-3XRF5HITZMEXSB24IKSDDG835.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/NaturalLanguage-4D80Z5A4SU5YYO2RDOJ4HGOLO.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/OpenGLES-CZSS0HBHJNORZ7BU9MN5FYEVR.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/BackgroundAssets-A21VSUK2CBTVU6RGERIV6AZSO.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/IOSurface-6ED7DYOAWFHQ707KIXMQ640J9.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/OSLog-2XSY6KBW61F8DNFNLXD6OOAKQ.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Metal-8J87938WHJ5QQLCALNI34D113.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreVideo-1WIPDY3BLBBOVU5FR4Y2FLY9C.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreML-4CECOB22CHNKQC6ZA8XNIGX28.pcm

SwiftCompile normal arm64 Compiling\ PulsumSentimentCoreML.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML/PulsumSentimentCoreML.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumSentimentCoreML/PulsumSentimentCoreML.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumML (in target 'PulsumML' from project 'PulsumML')

EmitSwiftModule normal arm64 (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ EmbeddingTopicGateProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/EmbeddingTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulsumFallbackEmbedding.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding/PulsumFallbackEmbedding.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/CoreMLGenerated/PulsumFallbackEmbedding/PulsumFallbackEmbedding.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ TopicGateProviding.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/TopicGateProviding.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CoreMLSentimentProvider.swift,\ FoundationModelsSentimentProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/CoreMLSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/FoundationModelsSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ StateEstimator.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/StateEstimator.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/StateEstimator.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ AFMTextEmbeddingProvider.swift,\ CoreMLEmbeddingFallbackProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift (in target 'PulsumML' from project 'PulsumML')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/AFMTextEmbeddingProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/CoreMLEmbeddingFallbackProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ EmbeddingError.swift,\ EmbeddingService.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingError.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingError.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/EmbeddingService.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SafetyLocal.swift,\ AFMSentimentProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/AFMSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/SafetyLocal.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/AFMSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ TextEmbeddingProviding.swift,\ Placeholder.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/TextEmbeddingProviding.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Placeholder.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Embedding/TextEmbeddingProviding.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Placeholder.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ resource_bundle_accessor.swift,\ FoundationModelsAvailability.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/resource_bundle_accessor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsAvailability.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ FoundationModelsStub.swift,\ BaselineMath.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/BaselineMath.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/AFM/FoundationModelsStub.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/BaselineMath.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ FoundationModelsTopicGateProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/TopicGate/FoundationModelsTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ NaturalLanguageSentimentProvider.swift,\ PIIRedactor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/NaturalLanguageSentimentProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/NaturalLanguageSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/PIIRedactor.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ RecRanker.swift,\ FoundationModelsSafetyProvider.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/RecRanker.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/RecRanker.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Safety/FoundationModelsSafetyProvider.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SentimentProviding.swift,\ SentimentService.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentProviding.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift (in target 'PulsumML' from project 'PulsumML')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentProviding.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML/Sources/PulsumML/Sentiment/SentimentService.swift (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumML (in target 'PulsumML' from project 'PulsumML')

SwiftDriver\ Compilation\ Requirements PulsumML normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumML -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumml -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling TextEmbeddingProviding.swift, Placeholder.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling TopicGateProviding.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling SentimentProviding.swift, SentimentService.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling FoundationModelsStub.swift, BaselineMath.swift (in target 'PulsumML' from project 'PulsumML')

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumML-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-Swift.h (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumML-Swift.h

SwiftDriverJobDiscovery normal arm64 Compiling EmbeddingError.swift, EmbeddingService.swift (in target 'PulsumML' from project 'PulsumML')

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.abi.json (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftdoc (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftsourceinfo (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftDriver PulsumData normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumData -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumdata -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling SafetyLocal.swift, AFMSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling StateEstimator.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling NaturalLanguageSentimentProvider.swift, PIIRedactor.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling EmbeddingTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling RecRanker.swift, FoundationModelsSafetyProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling resource_bundle_accessor.swift, FoundationModelsAvailability.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling CoreMLSentimentProvider.swift, FoundationModelsSentimentProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling PulsumFallbackEmbedding.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling PulsumSentimentCoreML.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling AFMTextEmbeddingProvider.swift, CoreMLEmbeddingFallbackProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriverJobDiscovery normal arm64 Compiling FoundationModelsTopicGateProvider.swift (in target 'PulsumML' from project 'PulsumML')

SwiftDriver\ Compilation PulsumML normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumML -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumml -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.o normal (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -r -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.LinkFileList -nostdlib -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-linker-args.resp -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.o

ExtractAppIntentsMetadata (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumML --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier pulsumml.PulsumML --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.appintents --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.o --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/PulsumML.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.SwiftConstValuesFileList --force --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:22.639 appintentsmetadataprocessor[8033:79077] Starting appintentsmetadataprocessor export
2025-11-10 22:39:22.717 appintentsmetadataprocessor[8033:79077] Extracted no relevant App Intents symbols, skipping writing output

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/LocalAuthentication-CNEGD5AW0AQ34KN0MRYL14GIY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreData-8OK03DCM4EE1TCHMB4QU3FJBW.pcm

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.o (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML.o

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/empty-PulsumML_-352E04A98F5439D9_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/Info.plist

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct normal (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/Objects-normal/arm64/PulsumML_-352E04A98F5439D9_PackageProduct.LinkFileList -install_name @rpath/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/Objects-normal/arm64/PulsumML_-352E04A98F5439D9_PackageProduct_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML\ product.build/Objects-normal/arm64/PulsumML_-352E04A98F5439D9_PackageProduct_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework Accelerate -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumML.build/Debug-iphonesimulator/PulsumML.build/Objects-normal/arm64/PulsumML-linker-args.resp

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumData (in target 'PulsumData' from project 'PulsumData')
EmitSwiftModule normal arm64 (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ VectorIndex.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/VectorIndex.swift (in target 'PulsumData' from project 'PulsumData')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/VectorIndex.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulsumData.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/PulsumData.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/PulsumData.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ LibraryImporter.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/LibraryImporter.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ ManagedObjects.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/Model/ManagedObjects.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ VectorIndexManager.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/VectorIndexManager.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ DataStack.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/DataStack.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/DataStack.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ EvidenceScorer.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData/Sources/PulsumData/EvidenceScorer.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ resource_bundle_accessor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumData' from project 'PulsumData')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftDriverJobDiscovery normal arm64 Compiling VectorIndexManager.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Compiling resource_bundle_accessor.swift (in target 'PulsumData' from project 'PulsumData')

GenerateTAPI /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct.tbd (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi stubify -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct.tbd

SwiftDriverJobDiscovery normal arm64 Compiling EvidenceScorer.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumData (in target 'PulsumData' from project 'PulsumData')

SwiftDriver\ Compilation\ Requirements PulsumData normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumData -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumdata -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumData-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-Swift.h (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumData-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftdoc (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.abi.json (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftsourceinfo (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework

SwiftDriver PulsumServices normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumServices -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumservices -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'PulsumML' from project 'PulsumML')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumML
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework

SwiftDriverJobDiscovery normal arm64 Compiling PulsumData.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Compiling ManagedObjects.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Compiling DataStack.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Compiling LibraryImporter.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriverJobDiscovery normal arm64 Compiling VectorIndex.swift (in target 'PulsumData' from project 'PulsumData')

SwiftDriver\ Compilation PulsumData normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumData -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumdata -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.o normal (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -r -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.LinkFileList -nostdlib -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-linker-args.resp -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.o

ExtractAppIntentsMetadata (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumData --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier pulsumdata.PulsumData --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.appintents --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.o --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/PulsumData.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.SwiftConstValuesFileList --force --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:23.124 appintentsmetadataprocessor[8051:79240] Starting appintentsmetadataprocessor export
2025-11-10 22:39:23.205 appintentsmetadataprocessor[8051:79240] Extracted no relevant App Intents symbols, skipping writing output

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.o (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData.o

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/empty-PulsumData_1B04D3771DDAAD0A_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/Info.plist

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct normal (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/Objects-normal/arm64/PulsumData_1B04D3771DDAAD0A_PackageProduct.LinkFileList -install_name @rpath/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/Objects-normal/arm64/PulsumData_1B04D3771DDAAD0A_PackageProduct_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData\ product.build/Objects-normal/arm64/PulsumData_1B04D3771DDAAD0A_PackageProduct_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework Accelerate /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumData.build/Debug-iphonesimulator/PulsumData.build/Objects-normal/arm64/PulsumData-linker-args.resp

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_intrinsics-D8I4NYNR84PZ01K2IBJI34KI5.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UniformTypeIdentifiers-3C8JKI6POQG5WEIB9U2XUP4DF.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreMIDI-61D3Q99GV5LO4C9YJVWUZIE3L.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/QuartzCore-C82CS3Y3GFGUVRRZP96Q2NJCF.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_LocationEssentials-5V77I5JCPPOTTQS71VFU0W7GS.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreImage-59W3V26MMIGYIMUTQ4YM24EYW.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreAudioTypes-CML7HQKYQ6YPQ33WT6GB9MLV3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_tgmath-YWZ21240LFG7TMBCUCRWJGB1.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVRouting-3S1U5SWO1ABTLSQ0WXNV022LG.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreLocation-A1V79Q0ZMG1Y1AH9E5Y52RWUL.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreAudio-5W5NFLK2KP1BG7E65GVSRRNN2.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/HealthKit-AWW0M34MVJ4EJGMTCYKJN3TXU.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AudioToolbox-2400VA9VUTP3YXJR4K7EG9DW5.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreMedia-BAEHXN7PQAACFYFRE29S2EQNT.pcm

GenerateTAPI /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct.tbd (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi stubify -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct.tbd

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'PulsumData' from project 'PulsumData')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumData
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/simd-7R3S5HC6YPJ5MEJTKHB4XHCQS.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVFAudio-CDDY5BI7UJ5OCGB637A7PDEZ3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/MediaToolbox-56KHQIZUE30D55QQVT4PC9OWX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVFoundation-B0H12NYQEFJBVT26IMGXZODBH.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Speech-ANECXRCWK81541IAKLHYI3E5J.pcm

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumServices (in target 'PulsumServices' from project 'PulsumServices')

EmitSwiftModule normal arm64 (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SpeechService.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift (in target 'PulsumServices' from project 'PulsumServices')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/SpeechService.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ HealthKitAnchorStore.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/HealthKitAnchorStore.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ DiagnosticsNotifications.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/DiagnosticsNotifications.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/DiagnosticsNotifications.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ KeychainService.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/KeychainService.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CoachPhrasingSchema.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/CoachPhrasingSchema.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ resource_bundle_accessor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ FoundationModelsCoachGenerator.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/FoundationModelsCoachGenerator.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ HealthKitService.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/HealthKitService.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ LLMGateway.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/LLMGateway.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ Placeholder.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/Placeholder.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/Placeholder.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ BuildFlags.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/BuildFlags.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices/Sources/PulsumServices/BuildFlags.swift (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftDriverJobDiscovery normal arm64 Compiling BuildFlags.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling Placeholder.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling DiagnosticsNotifications.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling CoachPhrasingSchema.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling resource_bundle_accessor.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling KeychainService.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumServices (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriver\ Compilation\ Requirements PulsumServices normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumServices -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumservices -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumServices-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-Swift.h (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumServices-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftdoc (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.abi.json (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftsourceinfo (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftDriver PulsumAgents normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumAgents -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumagents -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling FoundationModelsCoachGenerator.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling HealthKitAnchorStore.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling HealthKitService.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftCompile normal arm64 Compiling\ CoachAgent.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CoachAgent+Coverage.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CoachAgent+Coverage.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulsumAgents.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/PulsumAgents.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/PulsumAgents.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ AgentOrchestrator.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/AgentOrchestrator.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ DataAgent.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/DataAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CheerAgent.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/CheerAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SafetyAgent.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/SafetyAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ resource_bundle_accessor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumAgents (in target 'PulsumAgents' from project 'PulsumAgents')

EmitSwiftModule normal arm64 (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SentimentAgent.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents/Sources/PulsumAgents/SentimentAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftDriverJobDiscovery normal arm64 Compiling PulsumAgents.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling CheerAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling resource_bundle_accessor.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling SafetyAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling CoachAgent+Coverage.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumAgents (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriver\ Compilation\ Requirements PulsumAgents normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumAgents -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumagents -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumAgents-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-Swift.h (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumAgents-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftdoc (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.abi.json (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftsourceinfo (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftDriver PulsumUI normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUI -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumui -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling LLMGateway.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriverJobDiscovery normal arm64 Compiling SentimentAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling CoachAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling AgentOrchestrator.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriverJobDiscovery normal arm64 Compiling SpeechService.swift (in target 'PulsumServices' from project 'PulsumServices')

SwiftDriver\ Compilation PulsumServices normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumServices -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumservices -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.o normal (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -r -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.LinkFileList -nostdlib -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-linker-args.resp -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.o

ExtractAppIntentsMetadata (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumServices --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier pulsumservices.PulsumServices --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.appintents --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.o --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/PulsumServices.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.SwiftConstValuesFileList --force --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:24.769 appintentsmetadataprocessor[8099:79587] Starting appintentsmetadataprocessor export
2025-11-10 22:39:24.846 appintentsmetadataprocessor[8099:79587] Extracted no relevant App Intents symbols, skipping writing output

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.o (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices.o

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/DeveloperToolsSupport-ETSY4EK9G8MUW95FM0YVMG6XE.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreTransferable-9TR1XCJF6YZ8AMSKW697558LX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreText-11DOZJ5GUIHJTSGG6FKFR7EMU.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/DataDetection-20XUBIJU1DUDQVLC25SUGRCWI.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UserNotifications-B06SKQ2VUFIPYRCAV6UDDFDD0.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Accessibility-8VJUFXV2WHUML46T5BB92UKJV.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/FileProvider-488GNG11H55HOBRP6JD5DM7W1.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Spatial-29RQWV4QBCG62YFD9Y38T60F8.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Symbols-6KMK9Y5VFWROONLFJPZ7CV6U2.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UIUtilities-6IYMBUSX0JN96DL1PB65A8S25.pcm

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/empty-PulsumServices_3A6ABEAA64FB17D8_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/Info.plist

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct normal (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/Objects-normal/arm64/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.LinkFileList -install_name @rpath/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/Objects-normal/arm64/PulsumServices_3A6ABEAA64FB17D8_PackageProduct_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices\ product.build/Objects-normal/arm64/PulsumServices_3A6ABEAA64FB17D8_PackageProduct_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework FoundationModels -framework Accelerate /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumServices.build/Debug-iphonesimulator/PulsumServices.build/Objects-normal/arm64/PulsumServices-linker-args.resp

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UIKit-UT7WA2DVYQH77VTV1BVV9I9W.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftUICore-4IN4JOECTN34I2872PZBE860M.pcm

GenerateTAPI /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.tbd (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi stubify -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.tbd

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'PulsumServices' from project 'PulsumServices')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumServices
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework

SwiftDriverJobDiscovery normal arm64 Compiling DataAgent.swift (in target 'PulsumAgents' from project 'PulsumAgents')

SwiftDriver\ Compilation PulsumAgents normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumAgents -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumagents -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.o normal (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -r -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.LinkFileList -nostdlib -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-linker-args.resp -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.o

ExtractAppIntentsMetadata (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumAgents --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier pulsumagents.PulsumAgents --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.appintents --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.o --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/PulsumAgents.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.SwiftConstValuesFileList --force --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:25.067 appintentsmetadataprocessor[8118:79666] Starting appintentsmetadataprocessor export
2025-11-10 22:39:25.141 appintentsmetadataprocessor[8118:79666] Extracted no relevant App Intents symbols, skipping writing output

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.o (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents.o

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/empty-PulsumAgents_68A450630B045BF4_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/Info.plist

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct normal (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/Objects-normal/arm64/PulsumAgents_68A450630B045BF4_PackageProduct.LinkFileList -install_name @rpath/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/Objects-normal/arm64/PulsumAgents_68A450630B045BF4_PackageProduct_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents\ product.build/Objects-normal/arm64/PulsumAgents_68A450630B045BF4_PackageProduct_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework FoundationModels -framework Accelerate -framework FoundationModels /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumAgents.build/Debug-iphonesimulator/PulsumAgents.build/Objects-normal/arm64/PulsumAgents-linker-args.resp

GenerateTAPI /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct.tbd (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi stubify -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct.tbd

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'PulsumAgents' from project 'PulsumAgents')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumAgents
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftUI-9WGDHBRBWJFB818XPSL7QS6Q6.pcm

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumUI (in target 'PulsumUI' from project 'PulsumUI')

EmitSwiftModule normal arm64 (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SettingsViewModel.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SettingsViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ ScoreBreakdownView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift (in target 'PulsumUI' from project 'PulsumUI')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SettingsView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift (in target 'PulsumUI' from project 'PulsumUI')
SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SettingsView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ ScoreBreakdownViewModel.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ScoreBreakdownViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulseViewModel.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulseViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ SafetyCardView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/SafetyCardView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ OnboardingView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/OnboardingView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ LiquidGlassComponents.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/LiquidGlassComponents.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ GlassEffect.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/GlassEffect.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulsumRootView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulsumRootView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ resource_bundle_accessor.swift,\ AppViewModel.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/resource_bundle_accessor.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/resource_bundle_accessor.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/AppViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CoachViewModel.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/CoachViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ CoachView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/CoachView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/CoachView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulseView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulseView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulseView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ ConsentBannerView.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/ConsentBannerView.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftCompile normal arm64 Compiling\ PulsumDesignSystem.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI/Sources/PulsumUI/PulsumDesignSystem.swift (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    

SwiftDriverJobDiscovery normal arm64 Compiling ScoreBreakdownViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling PulseViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling CoachViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling SettingsViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumUI (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriver\ Compilation\ Requirements PulsumUI normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUI -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumui -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumUI-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-Swift.h (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/GeneratedModuleMaps-iphonesimulator/PulsumUI-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftdoc (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.abi.json (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftsourceinfo (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

ProcessProductPackaging /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.entitlements /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Entitlements:
    
    {
}
    
    builtin-productPackagingUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.entitlements -entitlements -format xml -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent

ProcessProductPackaging /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.entitlements /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Entitlements:
    
    {
    "application-identifier" = "X6FJFZCXY3.ai.pulsum.Pulsum";
    "com.apple.developer.healthkit" = 1;
    "com.apple.developer.healthkit.background-delivery" = 1;
    "com.apple.developer.speech" = 1;
}
    
    builtin-productPackagingUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.entitlements -entitlements -format xml -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent

ProcessProductPackagingDER /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent.der (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /usr/bin/derq query -f xml -i /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app.xcent.der --raw

ProcessProductPackagingDER /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent.der (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /usr/bin/derq query -f xml -i /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent.der --raw

SwiftDriverJobDiscovery normal arm64 Compiling resource_bundle_accessor.swift, AppViewModel.swift (in target 'PulsumUI' from project 'PulsumUI')

GenerateAssetSymbols /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets --compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app --output-format human-readable-text --notices --warnings --export-dependency-info /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_dependencies --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist --app-icon AppIcon --accent-color AccentColor --compress-pngs --enable-on-demand-resources YES --development-region en --target-device iphone --target-device ipad --minimum-deployment-target 26.0 --platform iphonesimulator --bundle-identifier ai.pulsum.Pulsum --generate-swift-asset-symbols /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.swift --generate-objc-asset-symbols /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.h --generate-asset-symbol-index /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/* com.apple.actool.compilation-results */
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols-Index.plist
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.h
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.swift


DataModelCompile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/ /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.xcdatamodeld (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/usr/bin/momc --sdkroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --iphonesimulator-deployment-target 26.0 --module Pulsum /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Pulsum.xcdatamodeld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/
Pulsum.xcdatamodel: note: Model Pulsum version checksum: EU42IuS6gGhcSqHfEnz/XchOLFn3zYrcaDcdH7w+s10=

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned

MkDir /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/unthinned (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /bin/mkdir -p /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/unthinned

CompileAssetCatalogVariant thinned /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/usr/bin/actool /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets --compile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned --output-format human-readable-text --notices --warnings --export-dependency-info /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_dependencies_thinned --output-partial-info-plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist_thinned --app-icon AppIcon --accent-color AccentColor --compress-pngs --enable-on-demand-resources YES --filter-for-thinning-device-configuration iPhone17,1 --filter-for-device-os-version 26.0 --development-region en --target-device iphone --target-device ipad --minimum-deployment-target 26.0 --platform iphonesimulator
/* com.apple.actool.compilation-results */
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist_thinned
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned/AppIcon60x60@2x.png
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned/AppIcon76x76@2x~ipad.png
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned/Assets.car


SwiftDriver Pulsum normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Pulsum -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -emit-localized-strings -emit-localized-strings-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64 -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling ConsentBannerView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/DeveloperToolsSupport-D23U49C3ITFS7U2LAA8L4QMFC.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdbool-EICJJHUJXJ55VVN00T9P09W6R.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdarg-8JMVFVO4NQRY0B2KJ7FMH57UX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_SwiftConcurrencyShims-68B3HD6COMOL7833WWY4VS6GX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stddef-6YYLTA561NR0SXB8DGW1JLJK5.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ptrauth-8HJTABDLCH13BHUVKZVF5H7P6.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ptrcheck-7U8MOBRFCDLB8P73M8P4W90JL.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_float-D3MCUHTR1DK6MSLOIJAWPRIQM.pcm

SwiftDriverJobDiscovery normal arm64 Compiling SafetyCardView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling GlassEffect.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling PulsumDesignSystem.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftShims-CHPVTYWOGULDN5ZTIVW8BPVWM.pcm

SwiftDriverJobDiscovery normal arm64 Compiling LiquidGlassComponents.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_AvailabilityInternal-4TJS1JE3CFINPKVMXBNJZVZAA.pcm

SwiftDriverJobDiscovery normal arm64 Compiling OnboardingView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation1-5ZCWEYNYYFL5EJ9SZEPVU7MU6.pcm

SwiftDriverJobDiscovery normal arm64 Compiling PulsumRootView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling CoachView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_limits-5ULD6M9NNV5DYDK7EZ76AJVUN.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ExtensionFoundation-718ZW9JND15NU4JBUIAV5Z6PF.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation2-9KOSLHK47AZMM0E2TRJVFHVP.pcm

SwiftDriverJobDiscovery normal arm64 Compiling ScoreBreakdownView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriverJobDiscovery normal arm64 Compiling PulseView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_tgmath-CMBAJH2D7192H2KB5HJPNHBXM.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdint-DZA3N9O9QH7V8ZEND55G7AVTD.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/sys_types-951798Q3MQIJA0HQF9V6JEZ8U.pcm

SwiftDriverJobDiscovery normal arm64 Compiling SettingsView.swift (in target 'PulsumUI' from project 'PulsumUI')

SwiftDriver\ Compilation PulsumUI normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUI -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList -DSWIFT_PACKAGE -DDEBUG -DSWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE -DXcode -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -suppress-warnings -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 6 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -package-name pulsumui -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_const_extract_protocols.json -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/DerivedSources -Xcc -DSWIFT_PACKAGE -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum.xcodeproj -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.o normal (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -r -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.LinkFileList -nostdlib -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_dependency_info.dat -fobjc-link-runtime -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-linker-args.resp -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.o

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_intrinsics-6GSM37K00QZWX7A2AM41ZN72E.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_DarwinFoundation3-51KZBS2LDG76NLR1UHX70RRYO.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_stdatomic-ELU2H60Y1U6CVMM8GKFKANBMU.pcm

ExtractAppIntentsMetadata (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumUI --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier pulsumui.PulsumUI --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.appintents --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.o --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/PulsumUI.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.SwiftConstValuesFileList --force --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:26.933 appintentsmetadataprocessor[8181:79987] Starting appintentsmetadataprocessor export
2025-11-10 22:39:27.007 appintentsmetadataprocessor[8181:79987] Extracted no relevant App Intents symbols, skipping writing output

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_Builtin_inttypes-B9DDYQQ88AQTISNTEK7BG8BMI.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Darwin-4DQEXEPX4A794ESW5V07G7MD6.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/simd-47ZLFYYYWIW18UXOF7RMWRA46.pcm

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.o (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI.o

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/empty-PulsumUI_-352E04A98F4C2CD4_PackageProduct.plist -producttype com.apple.product-type.framework -expandbuildsettings -format binary -platform iphonesimulator -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/Info.plist

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct normal (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -w -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/Objects-normal/arm64/PulsumUI_-352E04A98F4C2CD4_PackageProduct.LinkFileList -install_name @rpath/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/Objects-normal/arm64/PulsumUI_-352E04A98F4C2CD4_PackageProduct_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI\ product.build/Objects-normal/arm64/PulsumUI_-352E04A98F4C2CD4_PackageProduct_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework Accelerate -framework FoundationModels -framework FoundationModels /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/PulsumUI.build/Debug-iphonesimulator/PulsumUI.build/Objects-normal/arm64/PulsumUI-linker-args.resp

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ObjectiveC-1MND29ZK52N7LJ0GJPZXK65Z.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/MachO-AQQJVMD9FFRR6EL5OEEB19L94.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os_object-6ZJHJBV7PKQU4OD1520DUAYY7.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os_workgroup-X8DOQ4R5I1KDSS3Y4HESW1VR.pcm

GenerateTAPI /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct.tbd (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/tapi stubify -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct.tbd

RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    builtin-RegisterExecutionPolicyException /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework

Touch /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'PulsumUI' from project 'PulsumUI')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum/Packages/PulsumUI
    /usr/bin/touch -c /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/PrivacyInfo.xcprivacy (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/PrivacyInfo.xcprivacy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/__preview.dylib normal (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -install_name @rpath/Pulsum.debug.dylib -dead_strip -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_dependency_info.dat -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __entitlements -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __ents_der -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent.der -Xlinker -no_adhoc_codesign -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/__preview.dylib

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/streak_low_poly_copy.splineswift /Users/martin.demel/Desktop/PULSUM/Pulsum/streak_low_poly_copy.splineswift (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/streak_low_poly_copy.splineswift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

CpResource /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/podcastrecommendations\ 2.json /Users/martin.demel/Desktop/PULSUM/Pulsum/podcastrecommendations\ 2.json (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/podcastrecommendations\ 2.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/libXCTestSwiftSupport.dylib /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/libXCTestBundleInject.dylib /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libXCTestBundleInject.dylib (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libXCTestBundleInject.dylib /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCUnit.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCUnit.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCUnit.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCUIAutomation.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCTestSupport.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTestSupport.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTestSupport.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCTestCore.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTestCore.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTestCore.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCTest.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCTest.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/XCTAutomationSupport.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTAutomationSupport.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/XCTAutomationSupport.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/Testing.framework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/Testing.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -exclude Headers -exclude PrivateHeaders -exclude Modules -exclude \*.tbd -resolve-src-symlinks /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/Testing.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Spatial-83MA3R5E7WRLODF6XMV8VIRHY.pcm

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework: replacing existing signature

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Dispatch-D23KMNFDFSSTB1SQ2U9SDAQOP.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/XPC-KW5LFGXECWU48OPPIVD3PG3N.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/dnssd-9H1K8K19ZGSNY04QNFF3XWC1S.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreFoundation-CIL9F697D0U41P0KLEQNLNNYU.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/os-6CGY2JTCJ1CLROKHEUFPE50GR.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Security-5YUZ6UZ4MQXWCOOKBHDWBFTPM.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreAudioTypes-6APHV5BTXBIC7VLSGY7T0KX3K.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CFNetwork-D1086J7KJVZAU3LTNN40VZWGQ.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreGraphics-9CRVCLREMG99PSDPH6Z58QKM.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreAudio-8ANCCEJ76FSNJS3RE6OPCD2B.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Foundation-5C870964SI8QW7W3AQFCUH5BB.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreText-1E4HOZFSMR18CUGMAJ0DRQF9J.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/ImageIO-4HFG3NREH1E22BZVANOCE6F9E.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Accessibility-3O3BR9ZKPRVGBO9D0RML4WN00.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/NaturalLanguage-5S9W0VTTF9CCO3TCJNK13LWYX.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/FileProvider-3OFXLDDRUYCSEH2P4XBX3XKUE.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/OSLog-GGVT5AS9KTNNSFGDZX999LIM.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/OpenGLES-4AS0ICJQZ70UR91E3GHLPPLJH.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UserNotifications-3F8KRX21M05MSVBEPSRWLU7K4.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/DataDetection-58EDWRKFRZYQ7H2RDVCK2FU6X.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/LocalAuthentication-C32H561TAH6YLFWAH26SDVEYP.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/IOSurface-8IENQR2QS0T2U6QVO76COJER3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/BackgroundAssets-6KD78R1UO6HQZNWBM9IV8PO84.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreTransferable-7O40RLYD2G1PFRSTMRADFP2KY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreData-B3NLF7EGW8BVRJIL0IQ8BM95I.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UniformTypeIdentifiers-6BFQUPBEFHKOKW9EQIYSNBK6K.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreMIDI-48RU6HQQT3ZKXHQQXJ4FLZ4CW.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Symbols-DZEOI80LY4OO99WL3D10M4IBQ.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/_LocationEssentials-8V6D7MU55WBLLKSJV4QNYOPEG.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UIUtilities-3ICIC4YGCIDCHLXCIDMYMHUP4.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Network-OJC9KKT4V1QD9MWKKQKBQO7D.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Metal-7D3MECTNLSG9BXBDZZXEP3PLW.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/HealthKit-COTIKRU9R1NLXGDXDQISJ2NYO.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AudioToolbox-EBISB6QFM8VBHFPR3NCN1WBNG.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreLocation-4ZFCYGR2HEUHEPQ23RY3NW98J.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVRouting-79MQY1UGVSSEVW0EBLIQMESF5.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreVideo-CDJFM6XRZKF4COV4WE6M4BY2X.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreMedia-AYSBYX3M9LLXYK3HWNL2UWYSL.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreImage-BFUK829T3COU7LVJWWZZL86OT.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/CoreML-1XHEGBVWEJH7V3OR27JSPGSC3.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/QuartzCore-11P19M8KZYJKUHXTLGC0UZ6PZ.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftUICore-CRQLHSRPI785GC3LU1GWZZRF9.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/MediaToolbox-40UM0FRXPHOEJNG3Q9KXZREFS.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVFAudio-CCLBLQ4U2Y0S2SPU7JPI8LFIY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/UIKit-J7MOZDS3K20W9RXO64J5PJ2I.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/AVFoundation-17E9IBBAO3AOE30BB1K8YZTJ5.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Speech-4L1IJ99F0CEFJ92OU4U6AVC7W.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/SwiftUI-6329Y726BO2MZYJ2PKGPP0TAX.pcm

SwiftEmitModule normal arm64 Emitting\ module\ for\ Pulsum (in target 'Pulsum' from project 'Pulsum')

EmitSwiftModule normal arm64 (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ PulsumApp.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/PulsumApp.swift (in target 'Pulsum' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/PulsumApp.swift (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ GeneratedAssetSymbols.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.swift (in target 'Pulsum' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/GeneratedAssetSymbols.swift (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftDriverJobDiscovery normal arm64 Emitting module for Pulsum (in target 'Pulsum' from project 'Pulsum')

SwiftDriver\ Compilation\ Requirements Pulsum normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Pulsum -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -emit-localized-strings -emit-localized-strings-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64 -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/Pulsum-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-Swift.h (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/Pulsum-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftdoc (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.abi.json (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftsourceinfo (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

ProcessProductPackaging "" /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Entitlements:
    
    {
    "application-identifier" = "X6FJFZCXY3.ai.pulsum.PulsumUITests.xctrunner";
    "keychain-access-groups" =     (
        "X6FJFZCXY3.ai.pulsum.PulsumUITests.xctrunner"
    );
}
    
    builtin-productPackagingUtility -entitlements -format xml -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent

ProcessProductPackagingDER /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent.der (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /usr/bin/derq query -f xml -i /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests.xctest-Simulated.xcent.der --raw

SwiftDriver PulsumTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumTests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -parse-as-library -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftDriver PulsumUITests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-SwiftDriver -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUITests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftFileList -DDEBUG -module-alias Testing\=_Testing_Unavailable -D PULSUM_UITESTS -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Compiling PulsumApp.swift (in target 'Pulsum' from project 'Pulsum')

SwiftDriverJobDiscovery normal arm64 Compiling GeneratedAssetSymbols.swift (in target 'Pulsum' from project 'Pulsum')

SwiftDriver\ Compilation Pulsum normal arm64 com.apple.xcode.tools.swift.compiler (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name Pulsum -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList -DDEBUG -default-isolation\=MainActor -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -emit-localized-strings -emit-localized-strings-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64 -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib normal (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -dynamiclib -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.LinkFileList -install_name @rpath/Pulsum.debug.dylib -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -Xlinker -rpath -Xlinker @executable_path/Frameworks -dead_strip -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum-linker-args.resp -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework FoundationModels -framework FoundationModels -framework Accelerate -Xlinker -alias -Xlinker _main -Xlinker ___debug_main_executable_dylib_entry_point /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct -Xlinker -no_adhoc_codesign -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib

ConstructStubExecutorLinkFileList /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-ExecutorLinkFileList-normal-arm64.txt (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    construct-stub-executor-link-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libPreviewsJITStubExecutor_no_swift_entry_point.a /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libPreviewsJITStubExecutor.a --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-ExecutorLinkFileList-normal-arm64.txt
note: Using stub executor library with Swift entry point. (in target 'Pulsum' from project 'Pulsum')

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum normal (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Xlinker -rpath -Xlinker @executable_path -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -Xlinker -rpath -Xlinker @executable_path/Frameworks -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -e ___debug_blank_executor_main -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __debug_dylib -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibPath-normal-arm64.txt -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __debug_instlnm -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-DebugDylibInstallName-normal-arm64.txt -Xlinker -filelist -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum-ExecutorLinkFileList-normal-arm64.txt -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __entitlements -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __ents_der -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.app-Simulated.xcent.der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib -Xlinker -no_adhoc_codesign -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/XCUIAutomation-9BTZYBQ9GRR9YIYAETI7I3IX6.pcm

SwiftExplicitDependencyCompileModuleFromInterface arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/Testing-130QXA9L2Z3VP.swiftmodule

SwiftExplicitDependencyCompileModuleFromInterface arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/XCUIAutomation-1H4XEHVK5LC4X.swiftmodule

SwiftExplicitDependencyGeneratePcm arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/XCTest-8VHLMJ8FATU5D3EOE4HLOAWIF.pcm

SwiftExplicitDependencyCompileModuleFromInterface arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/XCTest-18GRBVI4TTQBB.swiftmodule

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumTests (in target 'PulsumTests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumTests/PulsumTests.swift (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ PulsumTests.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumTests/PulsumTests.swift (in target 'PulsumTests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumTests/PulsumTests.swift (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumTests (in target 'PulsumTests' from project 'Pulsum')

SwiftDriver\ Compilation\ Requirements PulsumTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumTests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -parse-as-library -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources/PulsumTests-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-Swift.h (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources/PulsumTests-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.abi.json (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftdoc (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftsourceinfo (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumTests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftEmitModule normal arm64 Emitting\ module\ for\ PulsumUITests (in target 'PulsumUITests' from project 'Pulsum')

EmitSwiftModule normal arm64 (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ PulsumUITestsLaunchTests.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/PulsumUITestsLaunchTests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/PulsumUITestsLaunchTests.swift (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ JournalFlowUITests.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/JournalFlowUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/JournalFlowUITests.swift (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ PulsumUITestCase.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/PulsumUITestCase.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/PulsumUITestCase.swift (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ FirstRunPermissionsUITests.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/FirstRunPermissionsUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/FirstRunPermissionsUITests.swift (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftCompile normal arm64 Compiling\ SettingsAndCoachUITests.swift /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/SettingsAndCoachUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftCompile normal arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/PulsumUITests/SettingsAndCoachUITests.swift (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    

SwiftDriverJobDiscovery normal arm64 Compiling PulsumTests.swift (in target 'PulsumTests' from project 'Pulsum')

SwiftDriver\ Compilation PulsumTests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumTests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList -DDEBUG -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -parse-as-library -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftDriverJobDiscovery normal arm64 Emitting module for PulsumUITests (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriver\ Compilation\ Requirements PulsumUITests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation-Requirements -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUITests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftFileList -DDEBUG -module-alias Testing\=_Testing_Unavailable -D PULSUM_UITESTS -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

SwiftMergeGeneratedHeaders /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/PulsumUITests-Swift.h /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-Swift.h (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftHeaderTool -arch arm64 /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-Swift.h -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/PulsumUITests-Swift.h

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftdoc (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftdoc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftmodule (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftmodule /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.swiftmodule

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.abi.json (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.abi.json /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftsourceinfo (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftsourceinfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUITests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftDriverJobDiscovery normal arm64 Compiling PulsumUITestsLaunchTests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriverJobDiscovery normal arm64 Compiling FirstRunPermissionsUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriverJobDiscovery normal arm64 Compiling JournalFlowUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriverJobDiscovery normal arm64 Compiling SettingsAndCoachUITests.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriverJobDiscovery normal arm64 Compiling PulsumUITestCase.swift (in target 'PulsumUITests' from project 'Pulsum')

SwiftDriver\ Compilation PulsumUITests normal arm64 com.apple.xcode.tools.swift.compiler (in target 'PulsumUITests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-Swift-Compilation -- /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -module-name PulsumUITests -Onone -enforce-exclusivity\=checked @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.SwiftFileList -DDEBUG -module-alias Testing\=_Testing_Unavailable -D PULSUM_UITESTS -plugin-path /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing -enable-bare-slash-regex -enable-upcoming-feature DisableOutwardActorInference -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault -enable-experimental-feature DebugDescriptionMacro -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -target arm64-apple-ios26.0-simulator -g -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -Xfrontend -serialize-debugging-options -profile-coverage-mapping -profile-generate -enable-testing -index-store-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Index.noindex/DataStore -Xcc -D_LIBCPP_HARDENING_MODE\=_LIBCPP_HARDENING_MODE_DEBUG -swift-version 5 -I /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -Isystem /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -F /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -c -j16 -enable-batch-mode -incremental -Xcc -ivfsstatcache -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/SDKStatCaches.noindex/iphonesimulator26.1-23B77-90cf18a4295e390e64c810bc6bd7acbc.sdkstatcache -output-file-map /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-OutputFileMap.json -use-frontend-parseable-output -save-temps -no-color-diagnostics -explicit-module-build -module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules -clang-scanner-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -sdk-module-cache-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex -serialize-diagnostics -emit-dependencies -emit-module -emit-module-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests.swiftmodule -validate-clang-modules-once -clang-build-session-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/ModuleCache.noindex/Session.modulevalidation -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/swift-overrides.hmap -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests_const_extract_protocols.json -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-generated-files.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-own-target-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-all-non-framework-target-headers.hmap -Xcc -ivfsoverlay -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum-8a2ebb52ff332eacb0b1d430ce5478d8-VFS-iphonesimulator/all-product-headers.yaml -Xcc -iquote -Xcc /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/PulsumUITests-project-headers.hmap -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/include -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources-normal/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources/arm64 -Xcc -I/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/DerivedSources -Xcc -DDEBUG\=1 -emit-objc-header -emit-objc-header-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumUITests.build/Objects-normal/arm64/PulsumUITests-Swift.h -working-directory /Users/martin.demel/Desktop/PULSUM/Pulsum -experimental-emit-module-separately -disable-cmo

LinkAssetCatalog /Users/martin.demel/Desktop/PULSUM/Pulsum/Pulsum/Assets.xcassets (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-linkAssetCatalog --thinned /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/thinned --thinned-dependencies /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_dependencies_thinned --thinned-info-plist-content /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist_thinned --unthinned /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_output/unthinned --unthinned-dependencies /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_dependencies_unthinned --unthinned-info-plist-content /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist_unthinned --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app --plist-output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist
note: Emplaced /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/AppIcon60x60@2x.png (in target 'Pulsum' from project 'Pulsum')
note: Emplaced /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Assets.car (in target 'Pulsum' from project 'Pulsum')
note: Emplaced /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/AppIcon76x76@2x~ipad.png (in target 'Pulsum' from project 'Pulsum')

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/empty-Pulsum.plist -producttype com.apple.product-type.application -genpkginfo /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PkgInfo -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumAgents_PulsumAgents.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumData_PulsumData.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumML_PulsumML.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumServices_PulsumServices.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PulsumUI_PulsumUI.bundle -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Info.plist

CopySwiftLibs /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/SystemExtensions --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Extensions --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework --platform iphonesimulator --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os

ExtractAppIntentsMetadata (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name Pulsum --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier ai.pulsum.Pulsum --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Objects-normal/arm64/Pulsum.SwiftConstValuesFileList --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:30.581 appintentsmetadataprocessor[8277:80589] Starting appintentsmetadataprocessor export
2025-11-10 22:39:30.582 appintentsmetadataprocessor[8277:80589] warning: Metadata extraction skipped. No AppIntents.framework dependency found.

AppIntentsSSUTraining (in target 'Pulsum' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Info.plist --temp-dir-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/ssu --bundle-id ai.pulsum.Pulsum --product-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app --extracted-metadata-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Metadata.appintents --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/Pulsum.build/Pulsum.DependencyMetadataFileList --archive-ssu-assets
2025-11-10 22:39:30.595 appintentsnltrainingprocessor[8278:80591] Parsing options for appintentsnltrainingprocessor
2025-11-10 22:39:30.595 appintentsnltrainingprocessor[8278:80591] No AppShortcuts found - Skipping.

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumUI_PulsumUI.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumServices_PulsumServices.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumML_PulsumML.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumData_PulsumData.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

Ld /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumTests normal (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang -Xlinker -reproducible -target arm64-apple-ios26.0-simulator -bundle -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk -O0 -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -L/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/EagerLinkingTBDs/Debug-iphonesimulator -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -F/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks -iframework /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk/Developer/Library/Frameworks -filelist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.LinkFileList -Xlinker -rpath -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks -Xlinker -rpath -Xlinker @loader_path/Frameworks -Xlinker -rpath -Xlinker @executable_path/Frameworks -dead_strip -bundle_loader /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum -Xlinker -object_path_lto -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_lto.o -rdynamic -Xlinker -no_deduplicate -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -debug_variant -Xlinker -dependency_info -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_dependency_info.dat -fobjc-link-runtime -fprofile-instr-generate -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphonesimulator -L/usr/lib/swift -Xlinker -add_ast_path -Xlinker /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.swiftmodule @/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests-linker-args.resp -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -Wl,-no_warn_duplicate_libraries -framework FoundationModels -framework Accelerate -framework FoundationModels -framework FoundationModels -framework FoundationModels -framework FoundationModels -framework FoundationModels -framework Accelerate -Xlinker -needed_framework -Xlinker XCTest -framework XCTest -Xlinker -needed-lXCTestSwiftSupport -lXCTestSwiftSupport /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework/PulsumServices_3A6ABEAA64FB17D8_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework/PulsumAgents_68A450630B045BF4_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework/PulsumUI_-352E04A98F4C2CD4_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework/PulsumML_-352E04A98F5439D9_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework/PulsumData_1B04D3771DDAAD0A_PackageProduct /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/Pulsum.debug.dylib -Xlinker -no_adhoc_codesign -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumTests

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PulsumAgents_PulsumAgents.bundle /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

Copy /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -remove-static-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework: replacing existing signature

ProcessInfoPlistFile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Info.plist /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-infoPlistUtility /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/empty-PulsumTests.plist -producttype com.apple.product-type.bundle.unit-test -expandbuildsettings -format binary -platform iphonesimulator -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumAgents_PulsumAgents.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumData_PulsumData.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumML_PulsumML.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumServices_PulsumServices.bundle -scanforprivacyfile /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumUI_PulsumUI.bundle -o /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Info.plist

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework: replacing existing signature

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --preserve-metadata\=identifier,entitlements,flags --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework: replacing existing signature

CopySwiftLibs /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumTests --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PlugIns --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/SystemExtensions --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Extensions --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumServices_3A6ABEAA64FB17D8_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumAgents_68A450630B045BF4_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumUI_-352E04A98F4C2CD4_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumML_-352E04A98F5439D9_PackageProduct.framework --scan-folder /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/PackageFrameworks/PulsumData_1B04D3771DDAAD0A_PackageProduct.framework --platform iphonesimulator --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Frameworks --strip-bitcode --scan-executable /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/lib/libXCTestSwiftSupport.dylib --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os

ExtractAppIntentsMetadata (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsmetadataprocessor --toolchain-dir /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --module-name PulsumTests --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator26.1.sdk --xcode-version 17B55 --platform-family iOS --deployment-target 26.0 --bundle-identifier ai.pulsum.PulsumTests --output /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest --target-triple arm64-apple-ios26.0-simulator --binary-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/PulsumTests --dependency-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests_dependency_info.dat --stringsdata-file /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/ExtractedAppShortcutsMetadata.stringsdata --source-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftFileList --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyMetadataFileList --static-metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyStaticMetadataFileList --swift-const-vals-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/Objects-normal/arm64/PulsumTests.SwiftConstValuesFileList --compile-time-extraction --deployment-aware-processing --validate-assistant-intents --no-app-shortcuts-localization
2025-11-10 22:39:30.797 appintentsmetadataprocessor[8286:80650] Starting appintentsmetadataprocessor export
2025-11-10 22:39:30.798 appintentsmetadataprocessor[8286:80650] warning: Metadata extraction skipped. No AppIntents.framework dependency found.

AppIntentsSSUTraining (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Info.plist --temp-dir-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/ssu --bundle-id ai.pulsum.PulsumTests --product-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest --extracted-metadata-path /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest/Metadata.appintents --metadata-file-list /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Intermediates.noindex/Pulsum.build/Debug-iphonesimulator/PulsumTests.build/PulsumTests.DependencyMetadataFileList --archive-ssu-assets
2025-11-10 22:39:30.811 appintentsnltrainingprocessor[8287:80651] Parsing options for appintentsnltrainingprocessor
2025-11-10 22:39:30.811 appintentsnltrainingprocessor[8287:80651] No AppShortcuts found - Skipping.

CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest (in target 'PulsumTests' from project 'Pulsum')
    cd /Users/martin.demel/Desktop/PULSUM/Pulsum
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest
/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest: resource fork, Finder information, or similar detritus not allowed
Command CodeSign failed with a nonzero exit code


Test session results, code coverage, and logs:
	/Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Logs/Test/Test-Pulsum-2025.11.10_22-39-17--0600.xcresult

Testing failed:
	Command CodeSign failed with a nonzero exit code
	Testing cancelled because the build failed.

** TEST FAILED **


The following build commands failed:
	CodeSign /Users/martin.demel/Desktop/PULSUM/Pulsum/Build/Build/Products/Debug-iphonesimulator/Pulsum.app/PlugIns/PulsumTests.xctest (in target 'PulsumTests' from project 'Pulsum')
	Testing project Pulsum with scheme Pulsum
(2 failures)
(base) martin.demel@Martins-MacBook-Pro pulsum % 
