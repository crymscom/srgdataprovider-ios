//
//  SRGILFetchPath.m
//  SRGIntegrationLayerDataProvider
//  Copyright © 2015 SRG. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "SRGILURLComponents.h"
#import "SRGILErrors.h"
#import "NSBundle+SRGILDataProvider.h"

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
static const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

@interface SRGILURLComponents ()
@property(nonatomic, strong) NSURLComponents *wrapped;
@property(nonatomic, assign) SRGILFetchListIndex index;
@property(nonatomic, copy) NSString *identifier;
@end

@implementation SRGILURLComponents

+ (nullable SRGILURLComponents *)URLComponentsForFetchListIndex:(SRGILFetchListIndex)index
                                                 withIdentifier:(nullable NSString *)identifier
                                                          error:(NSError * __nullable __autoreleasing * __nullable)error;
{
    if (index < SRGILFetchListEnumBegin || index >= SRGILFetchListEnumEnd) {
        if (error) {
            *error = [NSError errorWithDomain:SRGILDataProviderErrorDomain
                                         code:SRGILDataProviderErrorCodeInvalidFetchIndex
                                     userInfo:@{NSLocalizedDescriptionKey: SRGILDataProviderLocalizedString(@"Invalid fetch index", nil)}];
        }
        return nil;
    }
    
    SRGILURLComponents *components = [[SRGILURLComponents alloc] init];
    components.index = index;
    components.identifier = identifier;
    
    switch (index) {
            // --- Videos ---
            
        case SRGILFetchListVideoLiveStreams:
            components.path = @"/video/livestream.json";
            break;
            
        case SRGILFetchListVideoEditorialPicks: {
            components.path = @"/video/editorialPlayerPicks.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            break;
            
        case SRGILFetchListVideoEditorialLatest:
            components.path = @"/video/editorialPlayerLatest.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            break;
            
        case SRGILFetchListVideoMostClicked:
            components.path = @"/video/mostClicked.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"],
                                     [NSURLQueryItem queryItemWithName:@"period" value:@"24"]];
            break;
            
        case SRGILFetchListVideoEpisodesByDate: {
            components.path = @"/video/episodesByDate.json";
            components.queryItems = @[[SRGILURLComponents URLQueryItemForDate:[NSDate date]]];
        }
            break;
            
        case SRGILFetchListVideoTopics:
            components.path = @"/tv/topic.json";
            break;

        case SRGILFetchListVideoMostRecentByTopic:
            components.path = @"/tv/topic.json";
            break;
            
        case SRGILFetchListVideoSearch:
            components.path = @"/video/search.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:SRGILFetchListURLComponentsEmptySearchQueryString],
                                     [NSURLQueryItem queryItemWithName:@"pageSize" value:@"24"]];
            break;
            
            
            // --- Video Shows ---
            
        case SRGILFetchListVideoShowsAlphabetical:
            components.path = @"/tv/assetGroup/editorialPlayerAlphabetical.json";
            break;
            
        case SRGILFetchListVideoShowsSearch:
            components.path = @"/tv/assetGroup/search.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:SRGILFetchListURLComponentsEmptySearchQueryString],
                                     [NSURLQueryItem queryItemWithName:@"pageSize" value:@"24"]];
            break;
            
            
            // --- Audio & Video Show Detail ---
            
        case SRGILFetchListVideoShowDetail:
        case SRGILFetchListAudioShowDetail: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/assetSet/listByAssetGroup/%@.json", identifier];
                components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            }
        }
            break;
            
            
            // --- Audios ---
            
        case SRGILFetchListAudioLiveStreams: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/audio/play/%@.json", identifier];
                components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            }
        }
            break;
            
        case SRGILFetchListAudioEditorialLatest: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/audio/editorialPlayerLatestByChannel/%@.json", identifier];
                components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            }
        }
            break;
            
        case SRGILFetchListAudioEpisodesLatest: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/audio/latestEpisodesByChannel/%@.json", identifier];
                components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            }
        }
            break;
            
        case SRGILFetchListAudioMostClicked: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/audio/mostClickedByChannel/%@.json", identifier];
                components.queryItems = @[[NSURLQueryItem queryItemWithName:@"pageSize" value:@"20"]];
            }
        }
            break;
            
        case SRGILFetchListAudioSearch: {
            components.path = @"/audio/search.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:SRGILFetchListURLComponentsEmptySearchQueryString],
                                     [NSURLQueryItem queryItemWithName:@"pageSize" value:@"24"]];
        }
            break;
            
            
            // --- Audio Shows ---
            
        case SRGILFetchListAudioShowsAlphabetical: {
            if (identifier.length > 0) {
                components.path = [NSString stringWithFormat:@"/radio/assetGroup/editorialPlayerAlphabeticalByChannel/%@.json", identifier];
            }
        }
            break;
            
            
        case SRGILFetchListAudioShowsSearch:
            components.path = @"/radio/assetGroup/search.json";
            components.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:SRGILFetchListURLComponentsEmptySearchQueryString],
                                     [NSURLQueryItem queryItemWithName:@"pageSize" value:@"24"]];
            break;
            
        default:
            break;
        }
    }
    
    if (!components.path && error) {
        if (identifier.length == 0) {
            NSString *format = SRGILDataProviderLocalizedString(@"An identifier is required for fetch index: %ld. Found %@.", nil);
            NSString *message = [NSString stringWithFormat:format, identifier, index];
            *error = SRGILCreateUserFacingError(message, nil, SRGILDataProviderErrorCodeMissingURLIdentifier);
        }
        else {
            *error = SRGILCreateUserFacingError(SRGILDataProviderLocalizedString(@"Error", nil), nil, SRGILDataProviderErrorCodeInvalidURLComponent);
        }
    }
    
    return components;
}

- (void)updateQueryItemsWithSearchString:(NSString *)newQueryString
{
    NSParameterAssert(newQueryString);
    [self replaceQueryItemWithName:@"q" withNewItem:[NSURLQueryItem queryItemWithName:@"q" value:newQueryString]];
}

- (void)updateQueryItemsWithPageSize:(NSString *)newPageSize
{
    NSParameterAssert(newPageSize);
    [self replaceQueryItemWithName:@"pageSize" withNewItem:[NSURLQueryItem queryItemWithName:@"pageSize" value:newPageSize]];
}

- (void)updateQueryItemsWithDate:(NSDate *)newDate
{
    NSParameterAssert(newDate);
    if (self.index == SRGILFetchListVideoEpisodesByDate) {
        [self replaceQueryItemWithName:@"day" withNewItem:[SRGILURLComponents URLQueryItemForDate:newDate]];
    }
    else {
        DDLogDebug(@"Providing a date for an index different from SRGILFetchListVideoEpisodesByDate has no effect.");
    }
}

- (void)replaceQueryItemWithName:(nonnull NSString *)name withNewItem:(nonnull NSURLQueryItem *)newItem
{
    NSMutableArray *items = [self.queryItems mutableCopy];
    if (!items) {
        items = [NSMutableArray array];
    }
    NSArray *filteredArray = [self.queryItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
    if (filteredArray.count == 1) {
        [items removeObject:filteredArray.lastObject];
    }
    [items addObject:newItem];
    self.queryItems = items;
}

+ (nonnull NSURLQueryItem *)URLQueryItemForDate:(NSDate *)date
{
    if (!date) {
        date = [NSDate date];
    }
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    NSString *dateString = [NSString stringWithFormat:@"%4li-%02li-%02li", (long)dateComponents.year, (long)dateComponents.month, (long)dateComponents.day];
    return [NSURLQueryItem queryItemWithName:@"day" value:dateString];
}

#pragma mark - Constructors

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.wrapped = [[NSURLComponents alloc] init];
    }
    return self;
}

- (instancetype)initWithString:(NSString *)URLString
{
    self = [super init];
    if (self) {
        self.wrapped = [[NSURLComponents alloc] initWithString:URLString];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url resolvingAgainstBaseURL:(BOOL)resolve
{
    self = [super init];
    if (self) {
        self.wrapped = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:resolve];
    }
    return self;
}

#pragma mark - Accessors

// Required. Otherwise, we get *** Terminating app due to uncaught exception 'NSInvalidArgumentException',
// reason: '*** -setPath: only defined for abstract class.  Define -[SRGILURLComponents setPath:]!'
// Basically, NSURLComponents cannot be subclassed without using a decorator pattern, as it is done here.
// See also https://twitter.com/zadr/status/422482466394624000

- (NSString *)fragment
{
    return self.wrapped.fragment;
}

- (void)setFragment:(NSString *)fragment
{
    self.wrapped.fragment = fragment;
}

- (NSString *)host
{
    return self.wrapped.host;
}

- (void)setHost:(NSString *)host
{
    self.wrapped.host = host;
}

- (NSString *)password
{
    return self.wrapped.password;
}

- (void)setPassword:(NSString *)password
{
    self.wrapped.password = password;
}

- (NSString *)path
{
    return self.wrapped.path;
}

- (void)setPath:(NSString *)path
{
    self.wrapped.path = path;
}

- (NSNumber *)port
{
    return self.wrapped.port;
}

- (void)setPort:(NSNumber *)port
{
    self.wrapped.port = port;
}

- (NSString *)query
{
    return self.wrapped.query;
}

- (void)setQuery:(NSString *)query
{
    self.wrapped.query = query;
}

- (NSArray<NSURLQueryItem *> *)queryItems
{
    return self.wrapped.queryItems;
}

- (void)setQueryItems:(NSArray<NSURLQueryItem *> *)queryItems
{
    self.wrapped.queryItems = queryItems;
}

- (NSString *)scheme
{
    return self.wrapped.scheme;
}

- (void)setScheme:(NSString *)scheme
{
    self.wrapped.scheme = scheme;
}

- (NSString *)user
{
    return self.wrapped.user;
}

- (void)setUser:(NSString *)user
{
    self.wrapped.user = user;
}

- (NSString *)string
{
    return self.wrapped.string;
}

- (NSURL *)URL
{
    return self.wrapped.URL;
}

- (NSURL *)URLRelativeToURL:(NSURL *)baseURL
{
    return [self.wrapped URLRelativeToURL:baseURL];
}

@end
