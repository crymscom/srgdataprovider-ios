//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSHTTPURLResponse+SRGDataProvider.h"

#import <XCTest/XCTest.h>

@interface NSHTTPURLResponse_DataProviderTestCase : XCTestCase

@end

@implementation NSHTTPURLResponse_DataProviderTestCase

#pragma mark Tests

- (void)testValues
{
    NSArray *statusCodes = @[ @100, @101, @102,
                              @200, @201, @202, @203, @204, @205, @206, @207, @208, @226,
                              @300, @301, @302, @303, @304, @305, @306, @307, @308,
                              @400, @401, @402, @403, @404, @405, @406, @407, @408, @409, @410, @411, @412, @413, @414, @415, @416, @417, @418, @421, @422, @423, @424, @426, @428, @429, @431, @451,
                              @500, @501, @502, @503, @504, @505, @506, @507, @508, @510, @511,
                              @103, @420, @450, @498, @499, @509, @530, @598, @599,
                              @440, @449, @451,
                              @444, @495, @496, @497, @499,
                              @520, @521, @522, @523, @524, @525, @526, @527];
    
    for (NSNumber *statusCode in statusCodes) {
        NSString *message = [NSHTTPURLResponse play_localizedStringForStatusCode:statusCode.integerValue];
        NSLog(@"%@: %@", statusCode, message);
        XCTAssertNotNil(message);
    }
}

@end