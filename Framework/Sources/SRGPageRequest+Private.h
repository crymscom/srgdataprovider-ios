//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGPageRequest.h"

NS_ASSUME_NONNULL_BEGIN

// Block signatures.
typedef void (^SRGPageCompletionBlock)(NSDictionary * _Nullable JSONDictionary, NSNumber * _Nullable total, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPresponse, NSError * _Nullable error);

/**
 *  Private interface for implementation purposes.
 */
@interface SRGPageRequest (Private)

/**
 *  The page which is requested.
 */
@property (nonatomic) SRGPage *page;

/**
 *  The completion block to be called.
 */
@property (nonatomic, copy) SRGPageCompletionBlock pageCompletionBlock;

@end

NS_ASSUME_NONNULL_END
