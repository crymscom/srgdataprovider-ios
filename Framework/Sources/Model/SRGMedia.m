//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMedia.h"

#import "NSURL+SRGIntegrationLayerDataProvider.h"
#import "SRGJSONTransformers.h"

@interface SRGMedia ()

@property (nonatomic) SRGChannel *channel;
@property (nonatomic) SRGEpisode *episode;
@property (nonatomic) SRGShow *show;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *lead;
@property (nonatomic, copy) NSString *summary;

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *URN;
@property (nonatomic) SRGMediaType mediaType;
@property (nonatomic) SRGVendor vendor;

@property (nonatomic) NSURL *imageURL;
@property (nonatomic, copy) NSString *imageTitle;
@property (nonatomic, copy) NSString *imageCopyright;

@property (nonatomic) SRGContentType contentType;
@property (nonatomic) SRGSource source;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSURL *podcastStandardDefinitionURL;
@property (nonatomic) NSURL *podcastHighDefinitionURL;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) NSArray<SRGRelatedContent *> *relatedContents;
@property (nonatomic) NSArray<SRGSocialCount *> *socialCounts;

@end

@implementation SRGMedia

#pragma mark MTLJSONSerializing protocol

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    static NSDictionary *s_mapping;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_mapping = @{ @"channel" : @"channel",
                       @"episode" : @"episode",
                       @"show" : @"show",
                      
                       @"title" : @"title",
                       @"lead" : @"lead",
                       @"summary" : @"description",
                       
                       @"uid" : @"id",
                       @"URN" : @"urn",
                       @"mediaType" : @"mediaType",
                       @"vendor" : @"vendor",
                       
                       @"imageURL" : @"imageUrl",
                       @"imageTitle" : @"imageTitle",
                       @"imageCopyright" : @"imageCopyright",
                       
                       @"contentType" : @"type",
                       @"date" : @"date",
                       @"duration" : @"duration",
                       @"podcastStandardDefinitionURL" : @"podcastSdUrl",
                       @"podcastHighDefinitionURL" : @"podcastHdUrl",
                       @"startDate" : @"validFrom",
                       @"endDate" : @"validTo",
                       @"source" : @"assignedBy",
                       @"relatedContents" : @"relatedContentList",
                       @"socialCounts" : @"socialCountList" };
    });
    return s_mapping;
}

#pragma mark Transformers

+ (NSValueTransformer *)channelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGChannel class]];
}

+ (NSValueTransformer *)episodeJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGEpisode class]];
}

+ (NSValueTransformer *)showJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[SRGShow class]];
}

+ (NSValueTransformer *)mediaTypeJSONTransformer
{
    return SRGMediaTypeJSONTransformer();
}

+ (NSValueTransformer *)vendorJSONTransformer
{
    return SRGVendorJSONTransformer();
}

+ (NSValueTransformer *)imageURLJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)contentTypeJSONTransformer
{
    return SRGContentTypeJSONTransformer();
}

+ (NSValueTransformer *)dateJSONTransformer
{
    return SRGISO8601DateJSONTransformer();
}

+ (NSValueTransformer *)podcastStandardDefinitionURLJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)podcastHighDefinitionURLJSONTransformer
{
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)startDateJSONTransformer
{
    return SRGISO8601DateJSONTransformer();
}

+ (NSValueTransformer *)endDateJSONTransformer
{
    return SRGISO8601DateJSONTransformer();
}

+ (NSValueTransformer *)sourceJSONTransformer
{
    return SRGSourceJSONTransformer();
}

+ (NSValueTransformer *)relatedContentsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[SRGRelatedContent class]];
}

+ (NSValueTransformer *)socialCountsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:[SRGSocialCount class]];
}

#pragma mark SRGImageMetadata protocol

- (NSURL *)imageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value
{
    return [self.imageURL srg_URLForDimension:dimension withValue:value];
}

@end
