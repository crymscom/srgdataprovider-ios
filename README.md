![SRG IL Data Provider logo](README-images/logo.png)

## About

The SRG Integration Layer (IL) Data Provider library for iOS provides a simple way to communicate with the common service shared by SRG business units.
It has been developed along with the SRGMediaPlayer library. However, this dependency is optional, and must be activated as explained below,
if you want to use this provider with the media player.

## Quick Start

Create a property where you need it, and instanciate a IL Data provider like this:

```
#!objective-c
    self.ILDataProvider = [[SRGILDataProvider alloc] initWithBusinessUnit:[NSString businessUnitIdentifier]];
```

Then, to fetch a list of item:

```
#!objective-c
    [self.ILDataProvider fetchListOfIndex:<fetch list index>
                         withPathArgument:<a possible argument>
                                organised:<SRGILModelDataOrganisationTypeFlat or SRGILModelDataOrganisationTypeAlphabetical>
                               onProgress:<an optional progress block>
                             onCompletion:<a completion block>];
```

When you have a media to play, request its complete metadata with:

```
#!objective-c
    [self.ILDataProvider fetchMediaWithURNString:<a media URN string>
                                 completionBlock:<a completion block>];
```

## Compatibility

The library is suitable for applications running on iOS 7 and above.

## Installation

The library can be added to a project through [CocoaPods](http://cocoapods.org/). Create a `Podfile` with the following contents:

* The SRG specification repository:
    
```
#!ruby
    source 'ssh://git@bitbucket.org/rtsmb/srgpodspecs.git'
```
    
* The `SRGIntegrationLayerDataProvider` dependency:

```
#!ruby
    pod 'SRGIntegrationLayerDataProvider', '<version>'
```

* To add optional support for the [SRG Media Player library](https://bitbucket.org/rtsmb/srgmediaplayer-ios):

```
#!ruby
    pod 'SRGIntegrationLayerDataProvider/MediaPlayer'
```

It is preferable not to provide a version number for the `SRGMediaPlayer` subspec.

Then run `pod install` to update the dependencies.

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).

## License

See the [LICENSE](LICENSE) file for more information.