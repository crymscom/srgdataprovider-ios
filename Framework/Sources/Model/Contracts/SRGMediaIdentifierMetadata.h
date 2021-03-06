//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGTypes.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common protocol for media identification.
 */
@protocol SRGMediaIdentifierMetadata <NSObject>

/**
 *  The unique media identifier.
 */
@property (nonatomic, readonly, copy) NSString *uid;

/**
 *  The Uniform Resource Name identifying the media.
 */
@property (nonatomic, readonly, copy) NSString *URN;

/**
 *  The media type.
 */
@property (nonatomic, readonly) SRGMediaType mediaType;

/**
 *  The business unit which the media belongs to.
 */
@property (nonatomic, readonly) SRGVendor vendor;

@end

NS_ASSUME_NONNULL_END
