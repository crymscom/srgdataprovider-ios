//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGMetadata.h"

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGTopic : MTLModel <SRGMetadata, MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *uid;

@end

NS_ASSUME_NONNULL_END
