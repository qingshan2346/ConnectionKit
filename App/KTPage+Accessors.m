//
//  KTPage+Accessors.m
//  KTComponents
//
//  Created by Dan Wood on 8/9/05.
//  Copyright 2005-2009 Karelia Software. All rights reserved.
//

#import "KTPage.h"
#import "KTArchivePage.h"

#import "KTMaster+Internal.h"
#import "KTMediaManager.h"
#import "KTDesign.h"
#import "KTSite.h"
#import "KTDocumentController.h"
#import "KTMediaContainer.h"

#import "NSArray+Karelia.h"
#import "NSDocumentController+KTExtensions.h"
#import "NSManagedObject+KTExtensions.h"
#import "NSObject+Karelia.h"
#import "NSData+Karelia.h"
#import "NSString+Karelia.h"

#import "Debug.h"


@implementation KTPage (Accessors)

#pragma mark -
#pragma mark Comments

@dynamic allowComments;

/*	By default this is set to NO. Plugins can override it either in their info.plist, or dynamically at run-time
 *	using the -setDisableComments: method.
 */
- (BOOL)disableComments { return [self wrappedBoolForKey:@"disableComments"]; }

- (void)setDisableComments:(BOOL)disableComments { [self setWrappedBool:disableComments forKey:@"disableComments"]; }

#pragma mark -
#pragma mark Title

- (BOOL)shouldUpdateFileNameWhenTitleChanges
{
    return [self wrappedBoolForKey:@"shouldUpdateFileNameWhenTitleChanges"];
}

- (void)setShouldUpdateFileNameWhenTitleChanges:(BOOL)autoUpdate
{
    [self setWrappedBool:autoUpdate forKey:@"shouldUpdateFileNameWhenTitleChanges"];
}

#pragma mark Relationships

- (KTPage *)page
{
	return self;			// the containing page of this object is the page itself
}

#pragma mark Drafts

- (void)setIsDraft:(NSNumber *)flag;
{
	// Mark our old archive page (if there is one) stale
	KTArchivePage *oldArchivePage = [[self parentPage] archivePageForTimestamp:[self timestampDate] createIfNotFound:!flag];
	
	
	[super setIsDraft:flag];
	
	
	// Delete the old archive page if it has nothing on it now
	if (oldArchivePage)
	{
		NSArray *pages = [oldArchivePage sortedPages];
		if (!pages || [pages count] == 0) [[self managedObjectContext] deletePage:oldArchivePage];
	}
	
	
	// This may also affect the site menu
	if ([self includeInSiteMenu])
	{
		[[self valueForKey:@"site"] invalidatePagesInSiteMenuCache];
	}
	
	// And the index
	[[self parentPage] invalidatePagesInIndexCache];
}

#pragma mark Site Menu

- (BOOL)includeInSiteMenu { return [self wrappedBoolForKey:@"includeInSiteMenu"]; }

/*	In addition to a standard setter, we must also invalidate old site menu
 */
- (void)setIncludeInSiteMenu:(BOOL)include;
{
	[self setWrappedBool:include forKey:@"includeInSiteMenu"];
	[[self valueForKey:@"site"] invalidatePagesInSiteMenuCache];
}

- (NSString *)menuTitle;
{
    NSString *result = [self customMenuTitle];
    if (![result length])
    {
        result = [[self titleBox] text];
    }
    
    return result;
}

@dynamic customMenuTitle;

#pragma mark -
#pragma mark Timestamp

- (NSString *)timestamp
{
	NSDateFormatterStyle style = [[self master] timestampFormat];
	return [self timestampWithStyle:style];
}

+ (NSSet *)keyPathsForValuesAffectingTimestamp
{
    return [NSSet setWithObject:@"timestampDate"];
}

- (NSString *)timestampWithStyle:(NSDateFormatterStyle)aStyle;
{
	BOOL showTime = [[[self master] timestampShowTime] boolValue];
	NSDate *date = [self timestampDate];
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateStyle:aStyle]; 
	
	// Minor adjustments to timestampFormat for the time style
	if (!showTime)
	{
		aStyle = NSDateFormatterNoStyle;
	}
	else
	{
		aStyle = kCFDateFormatterShortStyle;	// downgrade to short to avoid seconds
	}
	[formatter setTimeStyle:aStyle];
	
	NSString *result = [formatter stringForObjectValue:date];
	return result;
}

- (NSDate *)timestampDate;
{
    NSDate *result = (KTTimestampModificationDate == [self timestampType])
    ? [self lastModificationDate]
    : [self creationDate];
	
	return result;
}

+ (NSSet *)keyPathsForValuesAffectingTimestampDate
{
    return [NSSet setWithObjects:@"timestampType", @"creationDate", @"lastModificationDate", nil];
}

@dynamic includeTimestamp;

- (KTTimestampType)timestampType { return [self wrappedIntegerForKey:@"timestampType"]; }

- (void)setTimestampType:(KTTimestampType)timestampType
{
	OBPRECONDITION(timestampType == KTTimestampCreationDate || timestampType == KTTimestampModificationDate);
	[self setWrappedInteger:timestampType forKey:@"timestampType"];
}

- (NSString *)timestampTypeLabel
{
	NSString *result = (KTTimestampModificationDate == [self timestampType])
		? NSLocalizedString(@"(Modification Date)",@"Label to indicate that date shown is modification date")
		: NSLocalizedString(@"(Creation Date)",@"Label to indicate that date shown is creation date");
	return result;
}

#pragma mark -
#pragma mark Thumbnail

+ (NSSet *)keyPathsForValuesAffectingThumbnail
{
    return [NSSet setWithObject:@"collectionSummaryType"];
}

- (KTMediaContainer *)thumbnail
{
	KTMediaContainer *result = [self wrappedValueForKey:@"thumbnail"];
	
	if (!result)
	{
		NSString *mediaID = [self valueForKey:@"thumbnailMediaIdentifier"];
		if (mediaID)
		{
			result = [[self mediaManager] mediaContainerWithIdentifier:mediaID];
			[self setPrimitiveValue:result forKey:@"thumbnail"];
		}
		else
		{
			[self setPrimitiveValue:[NSNull null] forKey:@"thumbnail"];
		}
	}
	else if ((id)result == [NSNull null])
	{
		result = nil;
	}
	
	return result;
}

- (void)_setThumbnail:(KTMediaContainer *)thumbnail
{
	OBPRECONDITION(!thumbnail || [thumbnail isKindOfClass:[KTMediaContainer class]]);
    
    [self willChangeValueForKey:@"thumbnail"];
	[self setPrimitiveValue:thumbnail forKey:@"thumbnail"];
	[self setValue:[thumbnail identifier] forKey:@"thumbnailMediaIdentifier"];
	[self didChangeValueForKey:@"thumbnail"];
	
	
	// Propogate the thumbnail to our parent if needed
	if ([[self parentPage] pageToUseForCollectionThumbnail] == self)
	{
		[[self parentPage] _setThumbnail:thumbnail];
	}
}

- (void)setThumbnail:(KTMediaContainer *)thumbnail
{
	OBPRECONDITION(!thumbnail || [thumbnail isKindOfClass:[KTMediaContainer class]]);
    
    [self setCollectionSummaryType:KTSummarizeAutomatic];
	[self _setThumbnail:thumbnail];
}


/*	Called when a setting has been changed such that the collection's thumbnail needs updating.
 */
- (void)generateCollectionThumbnail
{
	KTCollectionSummaryType summaryType = [self collectionSummaryType];
	if (summaryType == KTSummarizeFirstItem || summaryType == KTSummarizeMostRecent)
	{
		KTPage *thumbnailPage = [self pageToUseForCollectionThumbnail];
		if (thumbnailPage)
		{
			[self _setThumbnail:[thumbnailPage thumbnail]];
		}
	}
}


/*	For collections, the thumbnail is often automatically generated from a child page.
 *	This method tells you which page to use.
 */
- (KTPage *)pageToUseForCollectionThumbnail
{
	KTPage *result;
	
	switch ([self collectionSummaryType])
	{
		case KTSummarizeFirstItem:
			result = [[self sortedChildren] firstObjectKS];
			break;
		case KTSummarizeMostRecent:
			result = [[self childrenWithSorting:SVCollectionSortByDateModified inIndex:NO] firstObjectKS];
			break;
		default:
			result = self;
			break;
	}
	
	return result;
}

- (NSSize)maxThumbnailSize { return NSMakeSize(64.0, 64.0); }

- (BOOL)mediaContainerShouldRemoveFile:(KTMediaContainer *)mediaContainer
{
	BOOL result = YES;
	
	if (mediaContainer == [self thumbnail])
	{
		id delegate = [self delegate];
		if (delegate && [delegate respondsToSelector:@selector(pageShouldClearThumbnail:)])
		{
			result = [delegate pageShouldClearThumbnail:self];
		}
	}
	
	return result;
}

#pragma mark -
#pragma mark Keywords

- (NSArray *)keywords
{
    return [self transientValueForKey:@"keywords" persistentPropertyListKey:@"keywordsData"];
}

- (void)setKeywords:(NSArray *)keywords
{	
	[self setTransientValue:keywords forKey:@"keywords" persistentPropertyListKey:@"keywordsData"];
}

- (NSString *)keywordsList;		// comma separated for meta
{
	NSString *result = [[self keywords] componentsJoinedByString:@", "];
	return result;
}

#pragma mark -
#pragma mark Site Outline

- (BOOL)shouldMaskCustomSiteOutlinePageIcon:(KTPage *)page
{
	BOOL result = YES;
	
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:_cmd])
	{
		result = [delegate shouldMaskCustomSiteOutlinePageIcon:page];
	}
	
	return result;
}

- (KTCodeInjection *)codeInjection
{
    return [self wrappedValueForKey:@"codeInjection"];
}

@end
