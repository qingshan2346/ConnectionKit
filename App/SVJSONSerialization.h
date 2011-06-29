//
//  SVJSONSerialization.h
//  Sandvox
//
//  Created by Mike on 29/06/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SVJSONSerialization : NSObject

// Pass in an array or dictionary as the object
// No options are available yet
+ (NSData *)dataWithJSONObject:(id)obj options:(NSUInteger)opt error:(NSError **)error;

@end
