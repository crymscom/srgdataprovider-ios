//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGImageMetadata.h"
#import "SRGMetadata.h"
#import "SRGModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common base class for results of a search request.
 */
@interface SRGSearchResult : SRGModel <SRGImageMetadata, SRGMetadata>

@end

NS_ASSUME_NONNULL_END
