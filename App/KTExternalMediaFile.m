//
//  KTExternalMediaFile.m
//  Marvel
//
//  Created by Mike on 11/12/2007.
//  Copyright 2007-2009 Karelia Software. All rights reserved.
//

#import "KTExternalMediaFile.h"

#import "NSManagedObject+KTExtensions.h"
#import "NSString+Karelia.h"

#import "BDAlias.h"
#import "BDAlias+QuickLook.h"


@implementation KTExternalMediaFile

#pragma mark -
#pragma mark Init

+ (id)insertNewMediaFileWithPath:(NSString *)path inManagedObjectContext:(NSManagedObjectContext *)moc
{
	return [self insertNewMediaFileWithAlias:[BDAlias aliasWithPath:path] inManagedObjectContext:moc];
}

+ (id)insertNewMediaFileWithAlias:(BDAlias *)alias inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    KTExternalMediaFile *result = nil;
    BOOL canInsert = YES;
    
    
    // Figure out if the alias is suitable
    NSString *path = [alias fullPath];
    NSString *UTI = nil;
    if (!path)
    {
        UTI = [NSString UTIForFileAtPath:[alias lastKnownPath]];
        if (!UTI) canInsert = NO;
    }
    
    
    // Insert if possible
    if (canInsert)
    {
        result = [super insertNewMediaFileWithPath:path inManagedObjectContext:moc];
        [result setAlias:alias];
    }
    
	return result;
}

#pragma mark -
#pragma mark Other

+ (NSString *)entityName { return @"ExternalMediaFile"; }

- (BDAlias *)alias
{
	BDAlias *result = [self wrappedValueForKey:@"alias"];
	
	if (!result)
	{
		NSData *aliasData = [self valueForKey:@"aliasData"];
		if (aliasData)
		{
			result = [BDAlias aliasWithData:aliasData];
			[self setPrimitiveValue:result forKey:@"alias"];
		}
	}
	
	return result;
}

- (void)setAlias:(BDAlias *)alias
{
	[self setWrappedValue:alias forKey:@"alias"];
	[self setValue:[alias aliasData] forKey:@"aliasData"];
}

- (NSURL *)fileURL;
{
	NSString *path = [[self alias] fullPath];
	
	// Ignore files which are in the Trash
	if (path && [path rangeOfString:@".Trash"].location == NSNotFound)
	{
		return [NSURL fileURLWithPath:path];
	}
    
    return nil;
}

- (NSString *)filename
{
    return [[[self alias] lastKnownPath] lastPathComponent];
}

- (NSString *)filenameExtension
{
    return [[[self alias] lastKnownPath] pathExtension];
}

- (NSString *)quickLookPseudoTag
{
	NSString *result = [[self alias] quickLookPseudoTag];
	return result;
}

- (NSString *)preferredFilename
{
	NSString *result = [[[self valueForKeyPath:@"alias.lastKnownPath"] lastPathComponent] stringByDeletingPathExtension];
	return result;
}

@end
