//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ViewController.h"

@import SRGIntegrationLayerDataProvider;

@interface ViewController ()

@property (nonatomic) SRGRequestQueue *requestQueue;

@end

@implementation ViewController

- (IBAction)request:(id)sender
{
    [[[SRGDataProvider currentDataProvider] videoTopicsWithCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSError * _Nullable error) {
        NSLog(@"Topics: %@; error: %@", topics, error);
        
        SRGTopic *firstTopic = topics.firstObject;
        if (firstTopic) {
            [[[SRGDataProvider currentDataProvider] latestVideosForTopicWithUid:firstTopic.uid pagination:nil completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPagination * _Nullable nextPagination, NSError * _Nullable error) {
                NSLog(@"Medias: %@; error: %@", medias, error);
            }] resume];
        }
    }] resume];
    
    [[[SRGDataProvider currentDataProvider] trendingVideosWithEditorialLimit:@5 pagination:nil completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPagination * _Nullable nextPagination, NSError * _Nullable error) {
        NSLog(@"Medias: %@; error: %@", medias, error);
    }] resume];
    
    [[[SRGDataProvider currentDataProvider] mediaCompositionForVideoWithUid:@"42297626" completionBlock:^(SRGMediaComposition * _Nullable mediaComposition, NSError * _Nullable error) {
        NSLog(@"Media composition: %@; error: %@", mediaComposition, error);
        
        [[[SRGDataProvider currentDataProvider] likeMediaComposition:mediaComposition withCompletionBlock:^(SRGLike * _Nullable like, NSError * _Nullable error) {
            NSLog(@"Like: %@; error: %@", like, error);
        }] resume];
    }] resume];
    
    [[[SRGDataProvider currentDataProvider] mostPopularVideosWithPagination:nil completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPagination * _Nullable nextPagination, NSError * _Nullable error) {
        NSLog(@"Medias: %@; error: %@", medias, error);
    }] resume];
    
    [[[SRGDataProvider currentDataProvider] latestVideosWithPagination:nil completionBlock:^(NSArray<SRGMedia *> * _Nullable medias, SRGPagination * _Nullable nextPagination, NSError * _Nullable error) {
        NSLog(@"Medias: %@; error: %@", medias, error);
    }] resume];
    
    [[[SRGDataProvider currentDataProvider] videoShowsWithCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, NSError * _Nullable error) {
        NSLog(@"Shows: %@; error: %@", shows, error);
    }] resume];
}

- (IBAction)requestQueue:(id)sender
{
    self.requestQueue = [[SRGRequestQueue alloc] initWithStateChangeBlock:^(BOOL finished, NSError * _Nullable error) {
        if (finished) {
            NSLog(@"Queue finished!");
        }
        else {
            NSLog(@"Queue started!");
        }
    }];
    
    SRGRequest *request1 = [[SRGDataProvider currentDataProvider] videoTopicsWithCompletionBlock:^(NSArray<SRGTopic *> * _Nullable topics, NSError * _Nullable error) {
        NSLog(@"Request 1 finished!");
    }];
    [self.requestQueue addRequest:request1 resume:YES];
    SRGRequest *request2 = [[SRGDataProvider currentDataProvider] videoShowsWithCompletionBlock:^(NSArray<SRGShow *> * _Nullable shows, NSError * _Nullable error) {
        NSLog(@"Request 2 finished!");
    }];
    [self.requestQueue addRequest:request2 resume:YES];
}

@end
