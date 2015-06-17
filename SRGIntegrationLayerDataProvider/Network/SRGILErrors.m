//
//  SRGErrors.m
//  SRFPlayer
//
//  Created by Samuel Défago on 07/02/14.
//  Copyright (c) 2014 SRG SSR. All rights reserved.
//

#import "SRGILErrors.h"

NSString *const SRGILErrorDomain = @"ch.srgssr.integrationlayer";

NSError *SRGILCreateUserFacingError(NSString *failureReason, NSError *underlyingError, enum SRGILErrorCode errorCode)
{
    NSMutableDictionary *errorInfo = [NSMutableDictionary dictionary];
    
    [errorInfo setObject:NSLocalizedString(@"GENERIC_ERROR_MESSAGE", nil) forKey:NSLocalizedDescriptionKey];
    if (failureReason) {
        [errorInfo setObject:failureReason forKey:NSLocalizedFailureReasonErrorKey];
    }
    
    if (underlyingError) {
        [errorInfo setObject:underlyingError forKey:NSUnderlyingErrorKey];
    }
    
    NSError *newError = [NSError errorWithDomain:SRGILErrorDomain code:errorCode userInfo:errorInfo];
    return newError;
}
