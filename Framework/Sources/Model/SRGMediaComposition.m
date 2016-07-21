//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaComposition.h"

@interface SRGMediaComposition ()

@property (nonatomic, copy) NSString *chapterURN;
@property (nonatomic, copy) NSString *segmentURN;
@property (nonatomic) SRGEpisode *episode;
@property (nonatomic) SRGShow *show;
@property (nonatomic) SRGChannel *channel;
@property (nonatomic) NSArray<SRGChapter *> *chapters;
@property (nonatomic) NSArray<SRGEntry *> *analyticsEntries;
@property (nonatomic, copy) NSString *event;

@end

@implementation SRGMediaComposition

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @"chapterURN" : @"chapterUrn",
                       @"segmentURN" : @"segmentUrn",
                       @"episode" : @"episode",
                       @"show" : @"show",
                       @"channel" : @"channel",
                       @"chapters" : @"chapterList",
                       @"analyticsEntries" : @"analyticsList",
                       @"event" : @"eventData" };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)episodeJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGEpisode class]];
}

+ (NSValueTransformer *)showJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGShow class]];
}

+ (NSValueTransformer *)channelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGChannel class]];
}

+ (NSValueTransformer *)chaptersJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[SRGChapter class]];
}

+ (NSValueTransformer *)analyticsEntriesJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[SRGEntry class]];
}

#pragma mark Getters and setters

- (SRGChapter *)mainChapter
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"URN == %@", self.chapterURN];
    return [self.chapters filteredArrayUsingPredicate:predicate].firstObject;
}

- (SRGSegment *)mainSegment
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"URN == %@", self.segmentURN];
    return [self.mainChapter.segments filteredArrayUsingPredicate:predicate].firstObject;
}

@end

