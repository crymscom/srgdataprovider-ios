//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMediaMetadata.h"

/**
 *  Extended media metadata protocol. For internal use only.
 */
@protocol SRGMediaExtendedMetadata <SRGMediaMetadata>

/**
 *  The original blocking reason received in metadata.
 */
@property (nonatomic, readonly) SRGBlockingReason originalBlockingReason;

@end

/**
 *  Return the effective blocking reason for a given media metadata.
 *
 *  @discussion This function combines several information from `SRGMediaMetadata` to determine whether a media is effectively
 *              blocked or not.
 */
OBJC_EXTERN SRGBlockingReason SRGBlockingReasonForMediaMetadata(_Nullable id<SRGMediaExtendedMetadata> mediaMetadata);
