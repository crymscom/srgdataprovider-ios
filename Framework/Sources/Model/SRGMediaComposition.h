//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Mantle/Mantle.h>

#import "SRGChapter.h"
#import "SRGEpisode.h"
#import "SRGShow.h"

@interface SRGMediaComposition : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *chapterURN;

@property (nonatomic, readonly) SRGShow *show;
@property (nonatomic, readonly) SRGEpisode *episode;
@property (nonatomic, readonly) NSArray<SRGChapter *> *chapters;

@property (nonatomic, readonly, copy) NSString *event;

@end
