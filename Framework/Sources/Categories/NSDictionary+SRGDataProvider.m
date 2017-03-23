//
//  Copyright (c) SRG. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSDictionary+SRGDataProvider.h"

#import "NSObject+SRGDataProvider.h"

@implementation NSDictionary (SRGDataProvider)

- (NSString *)srg_descriptionAtLevel:(NSInteger)level
{
    NSString *normalIndentationString = [@"" stringByPaddingToLength:level withString:@"\t" startingAtIndex:0];
    NSString *fieldIndentationString = [@"" stringByPaddingToLength:level + 1 withString:@"\t" startingAtIndex:0];
    
    NSMutableString *description = [NSMutableString stringWithFormat:@"(\n"];
    for (id key in self.allKeys) {
        id formattedValue = [self[key] srg_formattedObjectAtLevel:level + 1];
        [description appendFormat:@"%@%@ = %@,\n", fieldIndentationString, key, formattedValue];
    }
    [description appendFormat:@"%@)", normalIndentationString];
    return [description copy];
}

@end
