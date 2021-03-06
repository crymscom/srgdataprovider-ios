//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGDataProvider.h"

#import "NSBundle+SRGDataProvider.h"
#import "SRGDataProviderLogger.h"
#import "SRGJSONTransformers.h"
#import "SRGSessionDelegate.h"

#import <libextobjc/libextobjc.h>
#import <Mantle/Mantle.h>

static SRGDataProvider *s_currentDataProvider;

static NSString *SRGDataProviderRequestDateString(NSDate *date);
static NSURLQueryItem *SRGDataProviderURLQueryItemForMaximumPublicationMonth(NSDate *maximumPublicationMonth);

NSURL *SRGIntegrationLayerProductionServiceURL(void)
{
    return [NSURL URLWithString:@"https://il.srgssr.ch/integrationlayer"];
}

NSURL *SRGIntegrationLayerStagingServiceURL(void)
{
    return [NSURL URLWithString:@"https://il-stage.srgssr.ch/integrationlayer"];
}

NSURL *SRGIntegrationLayerTestServiceURL(void)
{
    return [NSURL URLWithString:@"https://il-test.srgssr.ch/integrationlayer"];
}

NSString *SRGPathComponentForVendor(SRGVendor vendor)
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_pathComponents;
    dispatch_once(&s_onceToken, ^{
        s_pathComponents = @{ @(SRGVendorRSI) : @"rsi",
                              @(SRGVendorRTR) : @"rtr",
                              @(SRGVendorRTS) : @"rts",
                              @(SRGVendorSRF) : @"srf",
                              @(SRGVendorSWI) : @"swi" };
    });
    return s_pathComponents[@(vendor)] ?: @"not_supported";
}

@interface SRGDataProvider ()

@property (nonatomic) NSURL *serviceURL;
@property (nonatomic) NSURLSession *session;

@end

@implementation SRGDataProvider

#pragma mark Class methods

+ (SRGDataProvider *)currentDataProvider
{
    return s_currentDataProvider;
}

+ (void)setCurrentDataProvider:(SRGDataProvider *)currentDataProvider
{
    s_currentDataProvider = currentDataProvider;
}

// Attempt to split a request with a urns query parameter, returning the request for the URNs for the specified page.
// Returns `nil` if the request cannot be split. The original request is cloned to preserve its headers, most notably.
+ (NSURLRequest *)URLRequestForURNsPageWithSize:(NSUInteger)size number:(NSUInteger)number URLRequest:(NSURLRequest *)URLRequest
{
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URLRequest.URL resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [URLComponents.queryItems mutableCopy] ?: [NSMutableArray array];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(NSURLQueryItem.new, name), @"urns"];
    NSURLQueryItem *URNsQueryItem = [URLComponents.queryItems filteredArrayUsingPredicate:predicate].firstObject;
    
    if (! URNsQueryItem.value) {
        return nil;
    }
    
    static NSString * const kURNsSeparator = @",";
    NSArray<NSString *> *URNs = [URNsQueryItem.value componentsSeparatedByString:kURNsSeparator];
    if (number == 0 && URNs.count < 2) {
        return URLRequest;
    }
    
    NSUInteger location = number * size;
    if (location >= URNs.count) {
        return nil;
    }
    
    NSRange range = NSMakeRange(location, MIN(size, URNs.count - location));
    NSArray<NSString *> *pageURNs = [URNs subarrayWithRange:range];
    NSURLQueryItem *pageURNsQueryItem = [NSURLQueryItem queryItemWithName:@"urns" value:[pageURNs componentsJoinedByString:kURNsSeparator]];
    [queryItems replaceObjectAtIndex:[queryItems indexOfObject:URNsQueryItem] withObject:pageURNsQueryItem];
    
    URLComponents.queryItems = [queryItems copy];
    
    NSMutableURLRequest *URNsURLRequest = [URLRequest mutableCopy];
    URNsURLRequest.URL = URLComponents.URL;
    return [URNsURLRequest copy];              // Not an immutable copy ;(
}

#pragma mark Object lifecycle

- (instancetype)initWithServiceURL:(NSURL *)serviceURL
{
    if (self = [super init]) {
        self.serviceURL = serviceURL;
        
        // The session delegate is retained. We could have self be the delegate, but we would need a way to invalidate
        // the session (e.g. by calling -invalidateAndCancel) so that the delegate is released, and thus a data provider
        // public invalidation method to be called for proper release. To avoid having this error-prone needs, we add
        // another object as delegate and use dealloc to invalidate the session
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        SRGSessionDelegate *sessionDelegate = [[SRGSessionDelegate alloc] init];
        self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:sessionDelegate delegateQueue:nil];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

- (void)dealloc
{
    [self.session invalidateAndCancel];
}

#pragma mark TV services

- (SRGRequest *)tvChannelsForVendor:(SRGVendor)vendor
                withCompletionBlock:(SRGChannelListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/channelList/tv.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGChannel.class rootKey:@"channelList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGRequest *)tvChannelForVendor:(SRGVendor)vendor
                           withUid:(NSString *)channelUid
                   completionBlock:(SRGChannelCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/channel/%@/tv/nowAndNext.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGChannel.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGRequest *)tvLivestreamsForVendor:(SRGVendor)vendor
                   withCompletionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/livestreams.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvScheduledLivestreamsForVendor:(SRGVendor)vendor
                                     withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/scheduledLivestreams.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvEditorialMediasForVendor:(SRGVendor)vendor
                                withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/editorial.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvLatestMediasForVendor:(SRGVendor)vendor
                             withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/latestEpisodes.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvMostPopularMediasForVendor:(SRGVendor)vendor
                                  withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/mostClicked.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvSoonExpiringMediasForVendor:(SRGVendor)vendor
                                   withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/soonExpiring.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGRequest *)tvTrendingMediasForVendor:(SRGVendor)vendor withLimit:(NSNumber *)limit completionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    return [self tvTrendingMediasForVendor:vendor withLimit:limit editorialLimit:nil episodesOnly:NO completionBlock:completionBlock];
}

- (SRGRequest *)tvTrendingMediasForVendor:(SRGVendor)vendor withLimit:(NSNumber *)limit editorialLimit:(NSNumber *)editorialLimit episodesOnly:(BOOL)episodesOnly completionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/trending.json", SRGPathComponentForVendor(vendor)];
    
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray array];
    
    // This request does not support pagination, but a maximum number of results, specified via a pageSize parameter.
    // The name is sadly misleading, see https://srfmmz.atlassian.net/browse/AIS-15970. Maximum page size is 50.
    if (limit) {
        limit = @(MIN(MAX(0, limit.integerValue), 50));
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"pageSize" value:limit.stringValue]];
    }
    if (editorialLimit) {
        editorialLimit = @(MAX(0, editorialLimit.integerValue));
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"maxCountEditorPicks" value:editorialLimit.stringValue]];
    }
    if (episodesOnly) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"onlyEpisodes" value:@"true"]];
    }
    
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvLatestEpisodesForVendor:(SRGVendor)vendor
                               withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/latestEpisodes.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvEpisodesForVendor:(SRGVendor)vendor
                                        date:(NSDate *)date
                         withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    if (! date) {
        date = NSDate.date;
    }
    
    NSString *dateString = SRGDataProviderRequestDateString(date);
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/episodesByDate/%@.json", SRGPathComponentForVendor(vendor), dateString];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGRequest *)tvTopicsForVendor:(SRGVendor)vendor
              withCompletionBlock:(SRGTopicListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/topicList/tv.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGTopic.class rootKey:@"topicList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvShowsForVendor:(SRGVendor)vendor
                      withCompletionBlock:(SRGPaginatedShowListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/showList/tv/alphabetical.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGShow.class rootKey:@"showList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)tvShowsForVendor:(SRGVendor)vendor matchingQuery:(NSString *)query withCompletionBlock:(SRGPaginatedSearchResultShowListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/searchResultListShow/tv.json", SRGPathComponentForVendor(vendor)];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"q" value:query] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGSearchResultShow.class rootKey:@"searchResultListShow" completionBlock:completionBlock];
}

#pragma mark Radio services

- (SRGRequest *)radioChannelsForVendor:(SRGVendor)vendor withCompletionBlock:(SRGChannelListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/channelList/radio.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGChannel.class rootKey:@"channelList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGRequest *)radioChannelForVendor:(SRGVendor)vendor
                              withUid:(NSString *)channelUid
                        livestreamUid:(NSString *)livestreamUid
                      completionBlock:(SRGChannelCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/channel/%@/radio/nowAndNext.json", SRGPathComponentForVendor(vendor), channelUid];
    
    NSArray<NSURLQueryItem *> *queryItems = nil;
    if (livestreamUid) {
        queryItems = @[ [NSURLQueryItem queryItemWithName:@"livestreamId" value:livestreamUid] ];
    }
    
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGChannel.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGRequest *)radioLivestreamsForVendor:(SRGVendor)vendor
                               channelUid:(NSString *)channelUid
                      withCompletionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/livestreamsByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGRequest *)radioLivestreamsForVendor:(SRGVendor)vendor
                         contentProviders:(SRGContentProviders)contentProviders
                      withCompletionBlock:(SRGMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/livestreams.json", SRGPathComponentForVendor(vendor)];
    NSArray<NSURLQueryItem *> *queryItems = nil;
    
    switch (contentProviders) {
        case SRGContentProvidersAll: {
            queryItems = @[ [NSURLQueryItem queryItemWithName:@"includeThirdPartyStreams" value:@"true" ] ];
            break;
        }
            
        case SRGContentProvidersSwissSatelliteRadio: {
            queryItems = @[ [NSURLQueryItem queryItemWithName:@"onlyThirdPartyContentProvider" value:@"ssatr" ] ];
            break;
        }
            
        default: {
            break;
        }
    }
    
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:queryItems];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioLatestMediasForVendor:(SRGVendor)vendor
                                         channelUid:(NSString *)channelUid
                                withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/latestByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioMostPopularMediasForVendor:(SRGVendor)vendor
                                              channelUid:(NSString *)channelUid
                                     withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/mostClickedByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioLatestEpisodesForVendor:(SRGVendor)vendor
                                           channelUid:(NSString *)channelUid
                                  withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/latestEpisodesByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioLatestVideosForVendor:(SRGVendor)vendor
                                         channelUid:(NSString *)channelUid
                                withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/latestByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioEpisodesForVendor:(SRGVendor)vendor
                                           date:(NSDate *)date
                                     channelUid:(NSString *)channelUid
                            withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    if (! date) {
        date = NSDate.date;
    }
    
    NSString *dateString = SRGDataProviderRequestDateString(date);
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/audio/episodesByDateAndChannel/%@/%@.json", SRGPathComponentForVendor(vendor), dateString, channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioShowsForVendor:(SRGVendor)vendor
                                  channelUid:(NSString *)channelUid
                         withCompletionBlock:(SRGPaginatedShowListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/showList/radio/alphabeticalByChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGShow.class rootKey:@"showList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)radioShowsForVendor:(SRGVendor)vendor
                               matchingQuery:(NSString *)query
                         withCompletionBlock:(SRGPaginatedSearchResultShowListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/searchResultListShow/radio.json", SRGPathComponentForVendor(vendor)];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"q" value:query] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGSearchResultShow.class rootKey:@"searchResultListShow" completionBlock:completionBlock];
}

#pragma mark Song services

- (SRGFirstPageRequest *)radioSongsForVendor:(SRGVendor)vendor
                                  channelUid:(NSString *)channelUid
                         withCompletionBlock:(SRGPaginatedSongListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/songList/radio/byChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGSong.class rootKey:@"songList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGRequest *)radioCurrentSongForVendor:(SRGVendor)vendor
                               channelUid:(NSString *)channelUid
                      withCompletionBlock:(SRGSongCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/songList/radio/byChannel/%@.json", SRGPathComponentForVendor(vendor), channelUid];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:@[ [NSURLQueryItem queryItemWithName:@"onlyCurrentSong" value:@"true"] ]];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGSong.class rootKey:@"songList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects.firstObject, HTTPResponse, error);
    }];
}

#pragma mark Live center services

- (SRGFirstPageRequest *)liveCenterVideosForVendor:(SRGVendor)vendor
                               withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/scheduledLivestreams/livecenter.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

#pragma mark Media search services

- (SRGFirstPageRequest *)videosForVendor:(SRGVendor)vendor
                           matchingQuery:(NSString *)query
                     withCompletionBlock:(SRGPaginatedSearchResultMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/searchResultListMedia/video.json", SRGPathComponentForVendor(vendor)];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"q" value:query] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGSearchResultMedia.class rootKey:@"searchResultListMedia" completionBlock:completionBlock];
}

- (SRGFirstPageRequest *)videosForVendor:(SRGVendor)vendor
                                withTags:(NSArray<NSString *> *)tags
                            excludedTags:(NSArray<NSString *> *)excludedTags
                      fullLengthExcluded:(BOOL)fullLengthExcluded
                         completionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = nil;
    if (fullLengthExcluded) {
        resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/latestByTags/excludeFullLength.json", SRGPathComponentForVendor(vendor)];
    }
    else {
        resourcePath = [NSString stringWithFormat:@"2.0/%@/mediaList/video/latestByTags.json", SRGPathComponentForVendor(vendor)];
    }
    
    NSString *includesString = [tags componentsJoinedByString:@","];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"includes" value:includesString] ];
    if (excludedTags) {
        NSString *excludesString = [tags componentsJoinedByString:@","];
        queryItems = [queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"excludes" value:excludesString]];
    }
    
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)audiosForVendor:(SRGVendor)vendor
                           matchingQuery:(NSString *)query
                     withCompletionBlock:(SRGPaginatedSearchResultMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/searchResultListMedia/audio.json", SRGPathComponentForVendor(vendor)];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"q" value:query] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:[queryItems copy]];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGSearchResultMedia.class rootKey:@"searchResultListMedia" completionBlock:completionBlock];
}

#pragma mark Recommendation services

- (SRGFirstPageRequest *)recommendedMediasForURN:(NSString *)URN
                                          userId:(NSString *)userId
                             withCompletionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = nil;
    if (userId) {
        resourcePath = [NSString stringWithFormat:@"2.0/mediaList/recommendedByUserId/byUrn/%@/%@.json", URN, userId];
    }
    else {
        resourcePath = [NSString stringWithFormat:@"2.0/mediaList/recommended/byUrn/%@.json", URN];
    }
    
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

#pragma mark Module services

- (SRGRequest *)modulesForVendor:(SRGVendor)vendor
                            type:(SRGModuleType)moduleType
             withCompletionBlock:(SRGModuleListCompletionBlock)completionBlock
{
    NSString *moduleTypeString = [SRGModuleTypeJSONTransformer() reverseTransformedValue:@(moduleType)];
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/moduleConfigList/%@.json", SRGPathComponentForVendor(vendor), moduleTypeString.lowercaseString];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listObjectsWithURLRequest:URLRequest modelClass:SRGModule.class rootKey:@"moduleConfigList" completionBlock:^(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, HTTPResponse, error);
    }];
}

#pragma mark General services

- (SRGRequest *)serviceMessageForVendor:(SRGVendor)vendor withCompletionBlock:(SRGServiceMessageCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/%@/general/information.json", SRGPathComponentForVendor(vendor)];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGServiceMessage.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

#pragma mark Popularity services

- (SRGRequest *)increaseSocialCountForType:(SRGSocialCountType)type
                               subdivision:(SRGSubdivision *)subdivision
                       withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock
{
    NSParameterAssert(subdivision);
    
    // Won't crash in release builds, but the request will most likely fail
    NSAssert(subdivision.event, @"Expect event information");
    
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_endpoints;
    dispatch_once(&s_onceToken, ^{
        s_endpoints = @{ @(SRGSocialCountTypeSRGView) : @"clicked",
                         @(SRGSocialCountTypeSRGLike) : @"liked",
                         @(SRGSocialCountTypeFacebookShare) : @"shared/facebook",
                         @(SRGSocialCountTypeTwitterShare) : @"shared/twitter",
                         @(SRGSocialCountTypeGooglePlusShare) : @"shared/google",
                         @(SRGSocialCountTypeWhatsAppShare) : @"shared/whatsapp" };
    });
    NSString *endpoint = s_endpoints[@(type)];
    NSAssert(endpoint, @"A supported social count type must be provided");
    
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaStatistic/byUrn/%@/%@.json", subdivision.URN, endpoint];
    
    NSMutableURLRequest *URLRequest = [[self URLRequestForResourcePath:resourcePath withQueryItems:nil] mutableCopy];
    URLRequest.HTTPMethod = @"POST";
    [URLRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *bodyJSONDictionary = subdivision.event ? @{ @"eventData" : subdivision.event } : @{};
    URLRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyJSONDictionary options:0 error:NULL];
    
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGSocialCountOverview.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGRequest *)increaseSocialCountForType:(SRGSocialCountType)type
                          mediaComposition:(SRGMediaComposition *)mediaComposition
                       withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock
{
    return [self increaseSocialCountForType:type subdivision:mediaComposition.mainSegment ?: mediaComposition.mainChapter withCompletionBlock:completionBlock];
}

#pragma mark URN services

- (SRGRequest *)mediaWithURN:(NSString *)mediaURN completionBlock:(SRGMediaCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/media/byUrn/%@.json", mediaURN];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGMedia.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)mediasWithURNs:(NSArray<NSString *> *)mediaURNs completionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaList/byUrns.json"];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"urns" value:[mediaURNs componentsJoinedByString: @","]] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:queryItems];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)latestMediasForTopicWithURN:(NSString *)topicURN completionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaList/latest/byTopicUrn/%@.json", topicURN];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)mostPopularMediasForTopicWithURN:(NSString *)topicURN completionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaList/mostClicked/byTopicUrn/%@.json", topicURN];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGRequest *)mediaCompositionForURN:(NSString *)mediaURN standalone:(BOOL)standalone withCompletionBlock:(SRGMediaCompositionCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaComposition/byUrn/%@.json", mediaURN];
    NSArray<NSURLQueryItem *> *queryItems = standalone ? @[ [NSURLQueryItem queryItemWithName:@"onlyChapters" value:@"true"] ] : nil;
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:queryItems];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGMediaComposition.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGRequest *)showWithURN:(NSString *)showURN completionBlock:(SRGShowCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/show/byUrn/%@.json", showURN];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self fetchObjectWithURLRequest:URLRequest modelClass:SRGShow.class completionBlock:^(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)showsWithURNs:(NSArray<NSString *> *)showURNs completionBlock:(SRGPaginatedShowListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/showList/byUrns.json"];
    NSArray<NSURLQueryItem *> *queryItems = @[ [NSURLQueryItem queryItemWithName:@"urns" value:[showURNs componentsJoinedByString: @","]] ];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:queryItems];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGShow.class rootKey:@"showList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)latestEpisodesForShowWithURN:(NSString *)showURN maximumPublicationMonth:(NSDate *)maximumPublicationMonth completionBlock:(SRGPaginatedEpisodeCompositionCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/episodeComposition/latestByShow/byUrn/%@.json", showURN];
    NSArray<NSURLQueryItem *> *queryItems = maximumPublicationMonth ? @[ SRGDataProviderURLQueryItemForMaximumPublicationMonth(maximumPublicationMonth) ] : nil;
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:queryItems];
    return [self fetchPaginatedObjectWithURLRequest:URLRequest modelClass:SRGEpisodeComposition.class completionBlock:^(id  _Nullable object, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(object, page, nextPage, HTTPResponse, error);
    }];
}

- (SRGFirstPageRequest *)latestMediasForModuleWithURN:(NSString *)moduleURN completionBlock:(SRGPaginatedMediaListCompletionBlock)completionBlock
{
    NSString *resourcePath = [NSString stringWithFormat:@"2.0/mediaList/latestByModuleConfigUrn/%@.json", moduleURN];
    NSURLRequest *URLRequest = [self URLRequestForResourcePath:resourcePath withQueryItems:nil];
    return [self listPaginatedObjectsWithURLRequest:URLRequest modelClass:SRGMedia.class rootKey:@"mediaList" completionBlock:^(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        completionBlock(objects, page, nextPage, HTTPResponse, error);
    }];
}

#pragma mark Common implementation

- (NSURLRequest *)URLRequestForResourcePath:(NSString *)resourcePath withQueryItems:(NSArray<NSURLQueryItem *> *)queryItems
{
    NSURL *URL = [self.serviceURL URLByAppendingPathComponent:resourcePath];
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    
    NSMutableArray<NSURLQueryItem *> *fullQueryItems = [NSMutableArray array];
    [self.globalParameters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull name, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [fullQueryItems addObject:[NSURLQueryItem queryItemWithName:name value:value]];
    }];
    if (queryItems) {
        [fullQueryItems addObjectsFromArray:queryItems];
    }
    [fullQueryItems addObject:[NSURLQueryItem queryItemWithName:@"vector" value:@"appplay"]];
    URLComponents.queryItems = [fullQueryItems copy];
    
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URLComponents.URL];
    [self.globalHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull headerField, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        [URLRequest setValue:value forHTTPHeaderField:headerField];
    }];
    return [URLRequest copy];              // Not an immutable copy ;(
}

- (SRGRequest *)fetchObjectWithURLRequest:(NSURLRequest *)URLRequest
                               modelClass:(Class)modelClass
                          completionBlock:(void (^)(id _Nullable object, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(URLRequest);
    NSParameterAssert(modelClass);
    NSParameterAssert(completionBlock);
    
    return [SRGRequest objectRequestWithURLRequest:URLRequest session:self.session parser:^id _Nullable(NSData *data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        NSDictionary *JSONDictionary = SRGNetworkJSONDictionaryParser(data, pError);
        if (! JSONDictionary) {
            return nil;
        }
        
        return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:pError];
    } completionBlock:^(id  _Nullable object, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *HTTPResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        completionBlock(object, HTTPResponse, error);
    }];
}

- (SRGRequest *)listObjectsWithURLRequest:(NSURLRequest *)URLRequest
                               modelClass:(Class)modelClass
                                  rootKey:(NSString *)rootKey
                          completionBlock:(void (^)(NSArray * _Nullable objects, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(URLRequest);
    NSParameterAssert(modelClass);
    NSParameterAssert(rootKey);
    NSParameterAssert(completionBlock);
    
    return [SRGRequest objectRequestWithURLRequest:URLRequest session:self.session parser:^id _Nullable(NSData * _Nonnull data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        NSDictionary *JSONDictionary = SRGNetworkJSONDictionaryParser(data, pError);
        if (! JSONDictionary) {
            return nil;
        }
        
        id JSONArray = JSONDictionary[rootKey];
        if (JSONArray && [JSONArray isKindOfClass:NSArray.class]) {
            return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:pError];
        }
        else {
            // Remark: When the result count is equal to a multiple of the page size, the last link returns an empty list array.
            // See https://srfmmz.atlassian.net/wiki/display/SRGPLAY/Developer+Meeting+2016-10-05
            return @[];
        }
    } completionBlock:^(id  _Nullable object, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *HTTPResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        completionBlock(object, HTTPResponse, error);
    }];
}

// Helper for common paginated request implementation. Extract common values from the JSON dictionary of IL responses,
// while letting the parser still be customised.
- (SRGFirstPageRequest *)pageRequestWithURLRequest:(NSURLRequest *)URLRequest
                                            parser:(id (^)(NSDictionary *JSONDictionary, NSError * __autoreleasing *pError))parser
                                   completionBlock:(void (^)(id _Nullable object, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(URLRequest);
    NSParameterAssert(parser);
    NSParameterAssert(completionBlock);
    
    __block NSURL *nextURL = nil;
    __block NSNumber *total = nil;
    
    return [[SRGFirstPageRequest objectRequestWithURLRequest:URLRequest session:self.session parser:^id _Nullable(NSData * _Nonnull data, NSError * _Nullable __autoreleasing * _Nullable pError) {
        NSDictionary *JSONDictionary = SRGNetworkJSONDictionaryParser(data, pError);
        
        // Extract standard paginated request information values as well. Note that `next` is a dictionary in now & next requests,
        // we therefore must ensure we are looking at a link.
        id nextObject = JSONDictionary[@"next"];
        nextURL = [nextObject isKindOfClass:NSString.class] ? [NSURL URLWithString:nextObject] : nil;
        total = JSONDictionary[@"total"];
        
        return JSONDictionary ? parser(JSONDictionary, pError) : nil;
    } sizer:^NSURLRequest *(NSURLRequest * _Nonnull URLRequest, NSUInteger size) {
        NSURLRequest *URNsRequest = [SRGDataProvider URLRequestForURNsPageWithSize:size number:0 URLRequest:URLRequest];
        if (URNsRequest) {
            return URNsRequest;
        }
        
        if (size > SRGDataProviderMaximumPageSize && size != SRGDataProviderUnlimitedPageSize) {
            size = SRGDataProviderMaximumPageSize;
        }
        
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URLRequest.URL resolvingAgainstBaseURL:NO];
        NSMutableArray<NSURLQueryItem *> *queryItems = [URLComponents.queryItems mutableCopy] ?: [NSMutableArray array];
        NSString *pageSize = (size != SRGDataProviderUnlimitedPageSize) ? @(size).stringValue : @"unlimited";
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"pageSize" value:pageSize]];
        URLComponents.queryItems = [queryItems copy];
        
        NSMutableURLRequest *sizedURLRequest = [URLRequest mutableCopy];
        sizedURLRequest.URL = URLComponents.URL;
        return [sizedURLRequest copy];              // Not an immutable copy ;(
    } paginator:^NSURLRequest * _Nullable(NSURLRequest * _Nonnull URLRequest, id _Nullable object, NSURLResponse * _Nullable response, NSUInteger size, NSUInteger number) {
        NSURLRequest *URNsRequest = [SRGDataProvider URLRequestForURNsPageWithSize:size number:number URLRequest:URLRequest];
        if (URNsRequest) {
            return URNsRequest;
        }
        
        if (nextURL) {
            NSMutableURLRequest *pageURLRequest = [URLRequest mutableCopy];
            pageURLRequest.URL = nextURL;
            return [pageURLRequest copy];              // Not an immutable copy ;(
        }
        else {
            return nil;
        }
    } completionBlock:^(id  _Nullable object, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *HTTPResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        completionBlock(object, total, page, nextPage, HTTPResponse, error);
    }] requestWithPageSize:SRGDataProviderDefaultPageSize];
}

- (SRGFirstPageRequest *)listPaginatedObjectsWithURLRequest:(NSURLRequest *)URLRequest
                                                 modelClass:(Class)modelClass
                                                    rootKey:(NSString *)rootKey
                                            completionBlock:(void (^)(NSArray * _Nullable objects, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(URLRequest);
    NSParameterAssert(modelClass);
    NSParameterAssert(rootKey);
    NSParameterAssert(completionBlock);
    
    return [self pageRequestWithURLRequest:URLRequest parser:^id(NSDictionary *JSONDictionary, NSError *__autoreleasing *pError) {
        id JSONArray = JSONDictionary[rootKey];
        if (JSONArray && [JSONArray isKindOfClass:NSArray.class]) {
            return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray error:pError];
        }
        else {
            // Remark: When the result count is equal to a multiple of the page size, the last link returns an empty list array.
            // See https://srfmmz.atlassian.net/wiki/display/SRGPLAY/Developer+Meeting+2016-10-05
            return @[];
        }
    } completionBlock:completionBlock];
}

- (SRGFirstPageRequest *)fetchPaginatedObjectWithURLRequest:(NSURLRequest *)URLRequest
                                                 modelClass:(Class)modelClass
                                            completionBlock:(void (^)(id _Nullable object, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error))completionBlock
{
    NSParameterAssert(URLRequest);
    NSParameterAssert(modelClass);
    NSParameterAssert(completionBlock);
    
    return [self pageRequestWithURLRequest:URLRequest parser:^id(NSDictionary *JSONDictionary, NSError *__autoreleasing *pError) {
        return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:pError];
    } completionBlock:completionBlock];
}

#pragma mark Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; serviceURL = %@>",
            self.class,
            self,
            self.serviceURL];
}

@end

#pragma mark Functions

NSString *SRGDataProviderMarketingVersion(void)
{
    return [NSBundle srg_dataProviderBundle].infoDictionary[@"CFBundleShortVersionString"];
}

static NSString *SRGDataProviderRequestDateString(NSDate *date)
{
    NSCParameterAssert(date);
    
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateFormat = @"yyyy-MM-dd";
    });
    return [s_dateFormatter stringFromDate:date];
}

static NSURLQueryItem *SRGDataProviderURLQueryItemForMaximumPublicationMonth(NSDate *maximumPublicationMonth)
{
    NSCParameterAssert(maximumPublicationMonth);
    
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateFormat = @"yyyy-MM";
    });
    
    return [NSURLQueryItem queryItemWithName:@"maxPublishedDate" value:[s_dateFormatter stringFromDate:maximumPublicationMonth]];
}
