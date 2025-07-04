#!/usr/bin/env python3
import os
import uuid

# Generate unique UUIDs for the project
project_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
target_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
build_config_list_project = str(uuid.uuid4()).replace('-', '').upper()[:24]
build_config_list_target = str(uuid.uuid4()).replace('-', '').upper()[:24]
build_phase_sources = str(uuid.uuid4()).replace('-', '').upper()[:24]
build_phase_frameworks = str(uuid.uuid4()).replace('-', '').upper()[:24]
build_phase_resources = str(uuid.uuid4()).replace('-', '').upper()[:24]
main_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
products_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
ace_rfid_group = str(uuid.uuid4()).replace('-', '').upper()[:24]

# File UUIDs
app_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
appdelegate_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
scenedelegate_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
mainvc_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
addeditvc_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
cell_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
filament_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
coredata_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
nfc_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
datamodel_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
launchscreen_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]
infoplist_ref = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Build file UUIDs
appdelegate_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
scenedelegate_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
mainvc_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
addeditvc_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
cell_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
filament_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
coredata_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
nfc_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
datamodel_build = str(uuid.uuid4()).replace('-', '').upper()[:24]
launchscreen_build = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Configuration UUIDs
debug_project = str(uuid.uuid4()).replace('-', '').upper()[:24]
release_project = str(uuid.uuid4()).replace('-', '').upper()[:24]
debug_target = str(uuid.uuid4()).replace('-', '').upper()[:24]
release_target = str(uuid.uuid4()).replace('-', '').upper()[:24]

# Group UUIDs
models_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
views_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
controllers_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
services_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
coredata_group = str(uuid.uuid4()).replace('-', '').upper()[:24]
resources_group = str(uuid.uuid4()).replace('-', '').upper()[:24]

project_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
		{appdelegate_build} /* AppDelegate.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {appdelegate_ref} /* AppDelegate.swift */; }};
		{scenedelegate_build} /* SceneDelegate.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {scenedelegate_ref} /* SceneDelegate.swift */; }};
		{mainvc_build} /* MainViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {mainvc_ref} /* MainViewController.swift */; }};
		{addeditvc_build} /* AddEditFilamentViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {addeditvc_ref} /* AddEditFilamentViewController.swift */; }};
		{cell_build} /* FilamentTableViewCell.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {cell_ref} /* FilamentTableViewCell.swift */; }};
		{filament_build} /* Filament.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {filament_ref} /* Filament.swift */; }};
		{coredata_build} /* CoreDataManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {coredata_ref} /* CoreDataManager.swift */; }};
		{nfc_build} /* NFCService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {nfc_ref} /* NFCService.swift */; }};
		{datamodel_build} /* FilamentDataModel.xcdatamodeld in Sources */ = {{isa = PBXBuildFile; fileRef = {datamodel_ref} /* FilamentDataModel.xcdatamodeld */; }};
		{launchscreen_build} /* LaunchScreen.storyboard in Resources */ = {{isa = PBXBuildFile; fileRef = {launchscreen_ref} /* LaunchScreen.storyboard */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{app_ref} /* ACE-RFID.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "ACE-RFID.app"; sourceTree = BUILT_PRODUCTS_DIR; }};
		{appdelegate_ref} /* AppDelegate.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; }};
		{scenedelegate_ref} /* SceneDelegate.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SceneDelegate.swift; sourceTree = "<group>"; }};
		{mainvc_ref} /* MainViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MainViewController.swift; sourceTree = "<group>"; }};
		{addeditvc_ref} /* AddEditFilamentViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AddEditFilamentViewController.swift; sourceTree = "<group>"; }};
		{cell_ref} /* FilamentTableViewCell.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FilamentTableViewCell.swift; sourceTree = "<group>"; }};
		{filament_ref} /* Filament.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Filament.swift; sourceTree = "<group>"; }};
		{coredata_ref} /* CoreDataManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CoreDataManager.swift; sourceTree = "<group>"; }};
		{nfc_ref} /* NFCService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NFCService.swift; sourceTree = "<group>"; }};
		{datamodel_ref} /* FilamentDataModel.xcdatamodeld */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodel; path = FilamentDataModel.xcdatamodeld; sourceTree = "<group>"; }};
		{launchscreen_ref} /* LaunchScreen.storyboard */ = {{isa = PBXFileReference; lastKnownFileType = file.storyboard; path = LaunchScreen.storyboard; sourceTree = "<group>"; }};
		{infoplist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{build_phase_frameworks} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{ace_rfid_group} /* ACE-RFID */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{app_ref} /* ACE-RFID.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{ace_rfid_group} /* ACE-RFID */ = {{
			isa = PBXGroup;
			children = (
				{appdelegate_ref} /* AppDelegate.swift */,
				{scenedelegate_ref} /* SceneDelegate.swift */,
				{models_group} /* Models */,
				{views_group} /* Views */,
				{controllers_group} /* Controllers */,
				{services_group} /* Services */,
				{coredata_group} /* Core Data */,
				{resources_group} /* Resources */,
			);
			path = "ACE-RFID";
			sourceTree = "<group>";
		}};
		{models_group} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{filament_ref} /* Filament.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{views_group} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{cell_ref} /* FilamentTableViewCell.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{controllers_group} /* Controllers */ = {{
			isa = PBXGroup;
			children = (
				{mainvc_ref} /* MainViewController.swift */,
				{addeditvc_ref} /* AddEditFilamentViewController.swift */,
			);
			path = Controllers;
			sourceTree = "<group>";
		}};
		{services_group} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{nfc_ref} /* NFCService.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{coredata_group} /* Core Data */ = {{
			isa = PBXGroup;
			children = (
				{datamodel_ref} /* FilamentDataModel.xcdatamodeld */,
				{coredata_ref} /* CoreDataManager.swift */,
			);
			path = "Core Data";
			sourceTree = "<group>";
		}};
		{resources_group} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{launchscreen_ref} /* LaunchScreen.storyboard */,
				{infoplist_ref} /* Info.plist */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_uuid} /* ACE-RFID */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {build_config_list_target} /* Build configuration list for PBXNativeTarget "ACE-RFID" */;
			buildPhases = (
				{build_phase_sources} /* Sources */,
				{build_phase_frameworks} /* Frameworks */,
				{build_phase_resources} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = "ACE-RFID";
			productName = "ACE-RFID";
			productReference = {app_ref} /* ACE-RFID.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {build_config_list_project} /* Build configuration list for PBXProject "ACE-RFID" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_uuid} /* ACE-RFID */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{build_phase_resources} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{launchscreen_build} /* LaunchScreen.storyboard in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{build_phase_sources} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{appdelegate_build} /* AppDelegate.swift in Sources */,
				{scenedelegate_build} /* SceneDelegate.swift in Sources */,
				{mainvc_build} /* MainViewController.swift in Sources */,
				{addeditvc_build} /* AddEditFilamentViewController.swift in Sources */,
				{cell_build} /* FilamentTableViewCell.swift in Sources */,
				{filament_build} /* Filament.swift in Sources */,
				{coredata_build} /* CoreDataManager.swift in Sources */,
				{nfc_build} /* NFCService.swift in Sources */,
				{datamodel_build} /* FilamentDataModel.xcdatamodeld in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 13.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $$(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 13.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "ACE-RFID/Resources/Info.plist";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 13.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.yourcompany.ACE-RFID";
				PRODUCT_NAME = "$$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "ACE-RFID/Resources/Info.plist";
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = 13.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.yourcompany.ACE-RFID";
				PRODUCT_NAME = "$$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{build_config_list_project} /* Build configuration list for PBXProject "ACE-RFID" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{build_config_list_target} /* Build configuration list for PBXNativeTarget "ACE-RFID" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

/* Begin XCVersionGroup section */
		{datamodel_ref} /* FilamentDataModel.xcdatamodeld */ = {{
			isa = XCVersionGroup;
			children = (
			);
			currentVersion = "";
			path = FilamentDataModel.xcdatamodeld;
			sourceTree = "<group>";
			versionGroupType = wrapper.xcdatamodel;
		}};
/* End XCVersionGroup section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}"""

# Create project directory
os.makedirs("ACE-RFID.xcodeproj", exist_ok=True)

# Write project file
with open("ACE-RFID.xcodeproj/project.pbxproj", "w") as f:
    f.write(project_content)

# Create scheme
os.makedirs("ACE-RFID.xcodeproj/xcshareddata/xcschemes", exist_ok=True)
scheme_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_uuid}"
               BuildableName = "ACE-RFID.app"
               BlueprintName = "ACE-RFID"
               ReferencedContainer = "container:ACE-RFID.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uuid}"
            BuildableName = "ACE-RFID.app"
            BlueprintName = "ACE-RFID"
            ReferencedContainer = "container:ACE-RFID.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_uuid}"
            BuildableName = "ACE-RFID.app"
            BlueprintName = "ACE-RFID"
            ReferencedContainer = "container:ACE-RFID.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>'''

with open("ACE-RFID.xcodeproj/xcshareddata/xcschemes/ACE-RFID.xcscheme", "w") as f:
    f.write(scheme_content)

# Create workspace
os.makedirs("ACE-RFID.xcodeproj/project.xcworkspace", exist_ok=True)
workspace_content = '''<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:ACE-RFID.xcodeproj">
   </FileRef>
</Workspace>'''

with open("ACE-RFID.xcodeproj/project.xcworkspace/contents.xcworkspacedata", "w") as f:
    f.write(workspace_content)

print("✅ Project created successfully!")
