//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGModel.h"
#import "SRGTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A resource provides a media URL and its description (quality, encoding, etc.).
 */
@interface SRGResource : SRGModel

/**
 *  The media URL.
 */
@property (nonatomic, readonly) NSURL *URL;

/**
 *  The media quality (standard, high definition, ...).
 */
@property (nonatomic, readonly) SRGQuality quality;

/**
 *  The protocol over which the media is served.
 */
@property (nonatomic, readonly) SRGProtocol protocol;

/**
 *  The media encoding.
 */
@property (nonatomic, readonly) SRGEncoding encoding;

/**
 *  The recommended way to present the media.
 */
@property (nonatomic, readonly) SRGPresentation presentation;

/**
 *  The media MIME type.
 */
@property (nonatomic, readonly, copy, nullable) NSString *MIMEType;

/**
 *  The list of analytics labels which should be supplied in SRG Analytics events
 *  (https://github.com/SRGSSR/srganalytics-ios).
 */
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *analyticsLabels;

@end

NS_ASSUME_NONNULL_END
