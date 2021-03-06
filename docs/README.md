![SRG Data Provider logo](README-images/logo.png)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

## About

The SRG Data Provider library for iOS provides a simple way to retrieve metadata for all SRG SSRG business units in a common format.

The library provides:

* Requests to get the usual metadata associated with SRG SSR productions.
* A flat object model to easily access the data relevant to front-end users.
* A convenient way to perform requests, either in parallel or in cascade.

## Compatibility

The library is suitable for applications running on iOS 9 and above. The project is meant to be opened with the latest Xcode version (currently Xcode 10).

## Contributing

If you want to contribute to the project, have a look at our [contributing guide](CONTRIBUTING.md).

## Installation

The library can be added to a project using [Carthage](https://github.com/Carthage/Carthage) by adding the following dependency to your `Cartfile`:
    
```
github "SRGSSR/srgdataprovider-ios"
```

For more information about Carthage and its use, refer to the [official documentation](https://github.com/Carthage/Carthage).

### Dependencies

The library requires the following frameworks to be added to any target requiring it:

* `libextobjc`: A utility framework
* `MAKVONotificationCenter`: A safe KVO framework.
* `Mantle`: The framework used to parse the data.
* `SRGDataProvider`: The main library framework.
* `SRGLogger`: The framework used for internal logging.
* `SRGNetwork`: A networking framework.

### Dynamic framework integration

1. Run `carthage update` to update the dependencies (which is equivalent to `carthage update --configuration Release`). 
2. Add the frameworks listed above and generated in the `Carthage/Build/iOS` folder to your target _Embedded binaries_.

If your target is building an application, a few more steps are required:

1. Add a _Run script_ build phase to your target, with `/usr/local/bin/carthage copy-frameworks` as command.
2. Add each of the required frameworks above as input file `$(SRCROOT)/Carthage/Build/iOS/FrameworkName.framework`.

### Static framework integration

1. Run `carthage update --configuration Release-static` to update the dependencies. 
2. Add the frameworks listed above and generated in the `Carthage/Build/iOS/Static` folder to the _Linked frameworks and libraries_ list of your target.
3. Also add any resource bundle `.bundle` found within the `.framework` folders to your target directly.
4. Add the `-all_load` flag to your target _Other linker flags_.

## Usage

When you want to use classes or functions provided by the library in your code, you must import it from your source files first.

### Usage from Objective-C source files

Import the global header file using:

```objective-c
#import <SRGDataProvider/SRGDataProvider.h>
```

or directly import the module itself:

```objective-c
@import SRGDataProvider;
```

### Usage from Swift source files

Import the module where needed:

```swift
import SRGDataProvider
```

### Working with the library

To learn about how the library can be used, have a look at the [getting started guide](GETTING_STARTED.md).

### Logging

The library internally uses the [SRG Logger](https://github.com/SRGSSR/srglogger-ios) library for logging, within the `ch.srgssr.dataprovider` subsystem. This logger either automatically integrates with your own logger, or can be easily integrated with it. Refer to the SRG Logger documentation for more information.

## Building the project

A [Makefile](../Makefile) provides several targets to build and package the library. The available targets can be listed by running the following command from the project root folder:

```
make help
```

Alternatively, you can of course open the project with Xcode and use the available schemes.

## Supported requests

The supported requests vary depending on the business unit. A [compatibility matrix](SERVICE_AVAILABILITY.md) is provided for reference.

## Examples

To see examples of use, have a look a the unit test suite bundled with the project.

## Migration from versions previous versions

For information about changes introduced with major versions of the library, please read the [migration guide](MIGRATION_GUIDE.md).

## License

See the [LICENSE](../LICENSE) file for more information.
