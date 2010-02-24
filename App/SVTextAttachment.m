// 
//  SVTextAttachment.m
//  Sandvox
//
//  Created by Mike on 10/01/2010.
//  Copyright 2010 Karelia Software. All rights reserved.
//

#import "SVTextAttachment.h"

#import "SVGraphic.h"
#import "SVHTMLContext.h"

#import "NSError+Karelia.h"


@implementation SVTextAttachment 

- (void)writeHTML;
{
    NSString *string = [[[self paragraph] archiveString] substringWithRange:[self range]];
    [[SVHTMLContext currentContext] writeString:string];
}

#pragma mark Range

@dynamic body;
@dynamic pagelet;


- (NSRange)range;
{
    NSRange result = NSMakeRange([[self location] unsignedIntegerValue],
                                 [[self length] unsignedIntegerValue]);
    return result;
}

@dynamic length;
@dynamic location;

#pragma mark Placement

@dynamic placement;

- (BOOL)validatePlacement:(NSNumber **)placement error:(NSError **)error;
{
    BOOL result = YES;
    
    SVGraphicPlacement placementValue = [*placement integerValue];
    if (placementValue == SVGraphicPlacementInline)
    {
        result = [[self pagelet] canBePlacedInline];
        if (!result && error)
        {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSValidationNumberTooSmallError localizedDescription:@"Can't place graphic inline"];
        }
    }
    
    return result;
}

#pragma mark Wrap

@dynamic causesWrap;
@dynamic wrap;

- (NSNumber *)wrapIsFloatOrBlock
{
    NSNumber *result = [self wrap];
    if (![result isEqualToNumber:SVContentObjectWrapNone])
    {
        result = [NSNumber numberWithBool:YES];
    }
    return result;
}

- (void)setWrapIsFloatOrBlock:(NSNumber *)useFloatOrBlock
{
    [self setWrap:useFloatOrBlock];
}

+ (NSSet *)keyPathsForValuesAffectingWrapIsFloatOrBlock
{
    return [NSSet setWithObject:@"wrap"];
}

- (BOOL)wrapLeft
{
    BOOL result = ([[self causesWrap] boolValue] &&
                   [[self wrap] isEqualToNumber:SVContentObjectWrapFloatLeft]);
    return result;
}
- (void)setWrapLeft:(BOOL)floatLeft
{
    [self setWrap:(floatLeft ? SVContentObjectWrapFloatLeft : SVContentObjectWrapNone)];
}
+ (NSSet *)keyPathsForValuesAffectingWrapLeft
{
    return [NSSet setWithObjects:@"wrap", @"causesWrap", nil];
}

- (BOOL)wrapRight
{
    BOOL result = ([[self causesWrap] boolValue] &&
                   [[self wrap] isEqualToNumber:SVContentObjectWrapFloatRight]);
    return result;
}
- (void)setWrapRight:(BOOL)FloatRight
{
    [self setWrap:(FloatRight ? SVContentObjectWrapFloatRight : SVContentObjectWrapNone)];
}
+ (NSSet *)keyPathsForValuesAffectingWrapRight
{
    return [NSSet setWithObjects:@"wrap", @"causesWrap", nil];
}

- (BOOL)wrapLeftSplit
{
    BOOL result = ([[self causesWrap] boolValue] &&
                   [[self wrap] isEqualToNumber:SVContentObjectWrapBlockLeft]);
    return result;
}
- (void)setWrapLeftSplit:(BOOL)BlockLeft
{
    [self setWrap:(BlockLeft ? SVContentObjectWrapBlockLeft : SVContentObjectWrapNone)];
}
+ (NSSet *)keyPathsForValuesAffectingWrapLeftSplit
{
    return [NSSet setWithObjects:@"wrap", @"causesWrap", nil];
}

- (BOOL)wrapCenterSplit
{
    BOOL result = ([[self causesWrap] boolValue] &&
                   [[self wrap] isEqualToNumber:SVContentObjectWrapBlockCenter]);
    return result;
}
- (void)setWrapCenterSplit:(BOOL)BlockCenter
{
    [self setWrap:(BlockCenter ? SVContentObjectWrapBlockCenter : SVContentObjectWrapNone)];
}
+ (NSSet *)keyPathsForValuesAffectingWrapCenterSplit
{
    return [NSSet setWithObjects:@"wrap", @"causesWrap", nil];
}

- (BOOL)wrapRightSplit
{
    BOOL result = ([[self causesWrap] boolValue] &&
                   [[self wrap] isEqualToNumber:SVContentObjectWrapBlockRight]);
    return result;
}
- (void)setWrapRightSplit:(BOOL)BlockRight
{
    [self setWrap:(BlockRight ? SVContentObjectWrapBlockRight : SVContentObjectWrapNone)];
}
+ (NSSet *)keyPathsForValuesAffectingWrapRightSplit
{
    return [NSSet setWithObjects:@"wrap", @"causesWrap", nil];
}

@end
