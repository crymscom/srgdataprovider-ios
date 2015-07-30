//
//  SRGILMediaMetadata.h
//  SRGOfflineStorage
//
//  Copyright (c) 2015 SRG. All rights reserved.
//

#import <Realm/Realm.h>
#import "RTSBaseMetadata.h"
#import "SRGMetadatasProtocols.h"

@interface RTSMediaMetadata : RTSBaseMetadata <SRGMediaMetadataContainer>

@property NSString *parentTitle;
@property NSString *mediaDescription;

@property NSDate *publicationDate;

@property NSInteger type;
@property long durationInMs;
@property int viewCount;
@property BOOL isDownloadable;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RTSMediaMetadata>
RLM_ARRAY_TYPE(RTSMediaMetadata)
