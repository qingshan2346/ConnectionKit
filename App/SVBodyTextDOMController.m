//
//  SVPageletBodyTextAreaController.m
//  Sandvox
//
//  Created by Mike on 14/10/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import "SVBodyTextDOMController.h"
#import "SVBodyParagraphDOMAdapter.h"

#import "KT.h"
#import "SVBodyParagraph.h"
#import "SVCallout.h"
#import "KTAbstractPage.h"
#import "SVPagelet.h"
#import "SVBody.h"
#import "KTDocWindowController.h"
#import "SVImage.h"
#import "SVLinkManager.h"
#import "SVLink.h"
#import "SVMediaRecord.h"
#import "SVWebContentObjectsController.h"

#import "NSDictionary+Karelia.h"
#import "DOMNode+Karelia.h"
#import "DOMRange+Karelia.h"

#import "KSOrderedManagedObjectControllers.h"


static NSString *sBodyElementsObservationContext = @"SVBodyTextAreaElementsObservationContext";


@implementation SVBodyTextDOMController

#pragma mark Init & Dealloc

- (id)initWithContentObject:(SVContentObject *)body inDOMDocument:(DOMDocument *)document;
{
    // Make an object controller
    KSSetController *elementsController = [[KSSetController alloc] init];
    [elementsController setOrderingSortKey:@"sortKey"];
    [elementsController setManagedObjectContext:[body managedObjectContext]];
    [elementsController setEntityName:@"BodyParagraph"];
    [elementsController setAutomaticallyRearrangesObjects:YES];
    [elementsController bind:NSContentSetBinding toObject:body withKeyPath:@"elements" options:nil];
    
    
    // Super
    self = [super initWithContentObject:body inDOMDocument:document];
    
    
    // Get our content populated first so we don't have to teardown and restup the DOM
    _content = elementsController;
    
    
    
    // Match each model element up with its DOM equivalent
    NSArray *bodyElements = [[self content] arrangedObjects];
    for (SVBodyElement *aModelElement in bodyElements)
    {
        Class class = [self controllerClassForBodyElement:aModelElement];
        SVDOMController *result = [[class alloc] initWithContentObject:aModelElement
                                                         inDOMDocument:[[self HTMLElement] ownerDocument]];
        
        [result setHTMLContext:[self HTMLContext]];
        
        [self addChildWebEditorItem:result];
        [result release];
    }
    
    
    // Observe DOM changes. Each SVBodyParagraphDOMAdapter will take care of its own section of the DOM
    [[self textHTMLElement] addEventListener:@"DOMNodeInserted" listener:self useCapture:NO];
    [[self textHTMLElement] addEventListener:@"DOMNodeRemoved" listener:self useCapture:NO];
    
    
    // Observe content changes
    [[self content] addObserver:self
                     forKeyPath:@"arrangedObjects"
                        options:0
                        context:sBodyElementsObservationContext];
    
    
    // Finish up
    return self;
}

- (void)dealloc
{
    // Stop observation
    [[self textHTMLElement] removeEventListener:@"DOMNodeInserted" listener:self useCapture:NO];
    [[self textHTMLElement] removeEventListener:@"DOMNodeRemoved" listener:self useCapture:NO];
    
    [[self content] removeObserver:self forKeyPath:@"arrangedObjects"];
    
    
    // Release ivars
    [_content release];
    
    [super dealloc];
}

#pragma mark DOM Node

- (void)setHTMLElement:(DOMHTMLElement *)element
{
    [super setHTMLElement:element];
    [self setTextHTMLElement:element];
}

#pragma mark Content

@synthesize content = _content;

- (void)update
{
    [self willUpdate];
    
    // Walk the content array. Shuffle up DOM nodes to match if needed
    DOMHTMLElement *domNode = [[self textHTMLElement] firstChildOfClass:[DOMHTMLElement class]];
    
    for (SVBodyElement *aModelElement in [[self content] arrangedObjects])
    {
        // Locate the matching controller
        SVDOMController *controller = [self controllerForBodyElement:aModelElement];
        if (controller)
        {
            // Ensure the node is in the right place. Most of the time it already will be. If it isn't 
            if ([controller HTMLElement] != domNode)
            {
                [[self textHTMLElement] insertBefore:[controller HTMLElement] refChild:domNode];
                domNode = [controller HTMLElement];
            }
        
        
        
            domNode = [domNode nextSiblingOfClass:[DOMHTMLElement class]];
        }
        else
        {
            // It's a new object, create controller and node to match
            Class controllerClass = [self controllerClassForBodyElement:aModelElement];
            controller = [[controllerClass alloc] initWithHTMLDocument:
                          (DOMHTMLDocument *)[[self HTMLElement] ownerDocument]];
            [controller setHTMLContext:[self HTMLContext]];
            [controller setRepresentedObject:aModelElement];
            
            [[self textHTMLElement] insertBefore:[controller HTMLElement] refChild:domNode];
            
            [self addChildWebEditorItem:controller];
            [controller release];
        }
    }
    
    
    // All the nodes for deletion should have been pushed to the end, so we can delete them
    while (domNode)
    {
        DOMHTMLElement *nextNode = [domNode nextSiblingOfClass:[DOMHTMLElement class]];
        
        [[self controllerForDOMNode:domNode] removeFromParentWebEditorItem];
        [[domNode parentNode] removeChild:domNode];
        
        domNode = nextNode;
    }
    
    [self didUpdate];
}

- (IBAction)insertElement:(id)sender;
{
    // First remove any selected text. This should make the Web Editor post a kSVWebEditorViewWillChangeNotification
    WebView *webView = [[[[self HTMLElement] ownerDocument] webFrame] webView];
    [webView delete:self];
    
    
    // Figure out the body element to insert next to
    DOMRange *selection = [webView selectedDOMRange];
    OBASSERT([selection collapsed]);    // calling -delete: should have collapsed it
    
    KSDOMController *controller = [self controllerForDOMNode:[selection startContainer]];
    if (controller)
    {
        // TODO: Make the insertion
    }
}

- (IBAction)insertPagelet:(id)sender;
{
    // TODO: Make the insertion
}

- (IBAction)insertFile:(id)sender;
{
    NSWindow *window = [[[self HTMLElement] documentView] window];
    NSOpenPanel *panel = [[window windowController] makeChooseDialog];
    
    [panel beginSheetForDirectory:nil file:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(chooseDialogDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)chooseDialogDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSCancelButton) return;
    
    
    NSManagedObjectContext *context = [[self representedObject] managedObjectContext];
    SVMediaRecord *media = [SVMediaRecord mediaWithURL:[sheet URL]
                                            entityName:@"ImageMedia"
                        insertIntoManagedObjectContext:context
                                                 error:NULL];
    
    if (media)
    {
        SVImage *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image"
                                                       inManagedObjectContext:context];
        [image setMedia:media];
        
        CGSize size = [image originalSize];
        [image setWidth:[NSNumber numberWithFloat:size.width]];
        [image setHeight:[NSNumber numberWithFloat:size.height]];
        [image setConstrainProportions:[NSNumber numberWithBool:YES]];
        
        [self insertElement:image];
    }
    else
    {
        NSBeep();
    }
}

#pragma mark Editability

- (BOOL)isSelectable { return NO; }

- (void)setEditable:(BOOL)editable
{
    // TODO: Embedded graphics must NOT be selectable
    for (SVDOMController *aGraphicController in [self graphicControllers])
    {
        [[[aGraphicController HTMLElement] style] setProperty:@"-webkit-user-select"
                                                        value:@"none"
                                                     priority:@"!important"];
    }
    
    // Carry on
    [super setEditable:editable];
}

#pragma mark Subcontrollers

- (SVDOMController *)controllerForBodyElement:(SVBodyElement *)element;
{
    SVDOMController * result = nil;
    for (result in [self childWebEditorItems])
    {
        if ([result representedObject] == element) break;
    }
    
    return result;
}

- (SVDOMController *)controllerForDOMNode:(DOMNode *)node;
{
    SVDOMController *result = nil;
    for (result in [self childWebEditorItems])
    {
        if ([node isDescendantOfNode:[result HTMLElement]]) break;
    }
             
    return result;
}

- (Class)controllerClassForBodyElement:(SVBodyElement *)element;
{
    Class result = [element DOMControllerClass];
    
    return result;
}

- (NSArray *)graphicControllers;
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[[self childWebEditorItems] count]];
    
    for (KSDOMController *aController in [self childWebEditorItems])
    {
        if (![aController isKindOfClass:[SVBodyParagraphDOMAdapter class]])
        {
            [result addObject:aController];
        }
    }
    
    return result;
}

#pragma mark Updates

- (void)webViewDidChange;
{
    //  Body Text Controller doesn't track indivdual text changes itself, leaving that up to the paragraphs. So use this point to pass a similar message onto those subcontrollers to handle.
    
    
    [super webViewDidChange];
    
    // Use an old-fashioned iteration since paragraphs may insert paragraphs after themselves during this process.
    for (int i = 0; i < [[self childWebEditorItems] count]; i++)
    {
        [[[self childWebEditorItems] objectAtIndex:i] enclosingBodyControllerWebViewDidChange:self];
    }
}

@synthesize updating = _isUpdating;

- (void)willUpdate
{
    OBPRECONDITION(!_isUpdating);
    _isUpdating = YES;
}

- (void)didUpdate
{
    OBPRECONDITION(_isUpdating);
    _isUpdating = NO;
}

#pragma mark Editing

- (void)handleEvent:(DOMMutationEvent *)event
{
    // We're only interested in nodes being added or removed from our own node
    if ([event relatedNode] != [self textHTMLElement]) return;
    
    
    // Nor do we care mid-update
    if ([self isUpdating]) return;
    
    
    // Add or remove controllers for the new element
    if ([[event type] isEqualToString:@"DOMNodeInserted"])
    {
        // WebKit sometimes likes to keep the HTML neat by inserting both a newline character and HTML element at the same time. Ignore the former
        DOMHTMLElement *insertedNode = (DOMHTMLElement *)[event target];
        if (![insertedNode isKindOfClass:[DOMHTMLElement class]])
        {
            return;
        }
        
        
        // Create paragraph
        SVBodyParagraph *paragraph = [[self content] newObject];
        [paragraph readHTMLFromElement:insertedNode];
        
        
        // Create a matching controller
        Class class = [self controllerClassForBodyElement:paragraph];
        SVDOMController *controller = [[class alloc] initWithHTMLElement:insertedNode];
        
        [controller setRepresentedObject:paragraph];
        [paragraph release];
        [controller setHTMLContext:[self HTMLContext]];
        
        [self addChildWebEditorItem:controller];
        [controller release];
        
        
        // Insert the paragraph into the model in the same spot as it is in the DOM
        [self willUpdate];
         
        DOMHTMLElement *nextNode = [insertedNode nextSiblingOfClass:[DOMHTMLElement class]];
        if (nextNode)
        {
            KSDOMController * nextController = [self controllerForDOMNode:nextNode];
            OBASSERT(nextController);
            
            NSArrayController *content = [self content];
            NSUInteger index = [[content arrangedObjects] indexOfObject:[nextController representedObject]];
            [content insertObject:paragraph atArrangedObjectIndex:index];
        }
        else
        {
            // shortcut, know we're inserting at the end
            [[self content] addObject:paragraph];
        }
        
        [self didUpdate];
    }
    else if ([[event type] isEqualToString:@"DOMNodeRemoved"])
    {
        // Remove paragraph
        DOMHTMLElement *removedNode = (DOMHTMLElement *)[event target];
        if ([removedNode isKindOfClass:[DOMHTMLElement class]])
        {
            SVWebEditorItem *controller = [self controllerForDOMNode:removedNode];
            if (controller)
            {
                SVBodyElement *element = [controller representedObject];
                
                [self willUpdate];
                [[self content] removeObject:element];
                [self didUpdate];
                
                [controller removeFromParentWebEditorItem];
            }
        }
    }
}

- (BOOL)webEditorTextDoCommandBySelector:(SEL)selector
{
    BOOL result = [super webEditorTextDoCommandBySelector:selector];
    return result;
}

#pragma mark Links

- (void)changeLinkDestinationTo:(NSString *)linkURLString;
{
    SVWebEditorView *webEditor = [self webEditor];
    DOMRange *selection = [webEditor selectedDOMRange];
    
    if (!linkURLString)
    {
        DOMHTMLAnchorElement *anchor = [selection editableAnchorElement];
        if (anchor)
        {
            // Figure out selection before editing the DOM
            DOMNode *remainder = [anchor unlink];
            [selection selectNode:remainder];
            [webEditor setSelectedDOMRange:selection affinity:NSSelectionAffinityDownstream];
        }
        else
        {
            // Fallback way
            [[webEditor selectedDOMRange] removeAnchorElements];
        }
    }
    else
    {
        DOMHTMLAnchorElement *link = (id)[[webEditor HTMLDocument] createElement:@"A"];
        [link setHref:linkURLString];
        
        // Changing link affects selection. But if the selection is collapsed the user almost certainly wants to affect surrounding word/link
        if ([selection collapsed])
        {
            [[webEditor webView] selectWord:self];
            selection = [webEditor selectedDOMRange];
        }
        
        [selection surroundContents:link];
        
        // Make the link the selected object
        [selection selectNode:link];
        [webEditor setSelectedDOMRange:selection affinity:NSSelectionAffinityDownstream];
    }
    
    // Need to let paragraph's controller know an actual editing change was made
    [self webViewDidChange];
}

- (void)changeLink:(SVLinkManager *)sender;
{
    [self changeLinkDestinationTo:[[sender selectedLink] URLString]];
}

@synthesize selectedLink = _selectedLink;

- (void)webEditorTextDidChangeSelection:(NSNotification *)notification
{
    [super webEditorTextDidChangeSelection:notification];
    
    
    // Does the selection contain a link? If so, make it the selected object
    SVWebEditorView *webEditor = [self webEditor];
    DOMRange *selection = [webEditor selectedDOMRange];
    DOMHTMLAnchorElement *anchorElement = [selection editableAnchorElement];
    
    SVLink *link = nil;
    if (anchorElement)
    {
        // Is it a page link?
        NSString *linkURLString = [anchorElement getAttribute:@"href"]; // -href will give the URL a scheme etc. if there's no base URL
        if ([linkURLString hasPrefix:kKTPageIDDesignator])
        {
            NSString *pageID = [linkURLString substringFromIndex:[kKTPageIDDesignator length]];
            KTAbstractPage *target = [KTAbstractPage pageWithUniqueID:pageID
                                               inManagedObjectContext:[[self representedObject] managedObjectContext]];
            
            if (target)
            {
                link = [[SVLink alloc] initWithPage:target
                                    openInNewWindow:[[anchorElement target] isEqualToString:@"_blank"]];
            }
        }
        
        // Not a page link? Fallback to regular link
        if (!link)
        {
            link = [[SVLink alloc] initWithURLString:linkURLString
                                     openInNewWindow:[[anchorElement target] isEqualToString:@"_blank"]];
        }
    }
    
    [[SVLinkManager sharedLinkManager] setSelectedLink:link editable:(selection != nil)];
    [link release];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == sBodyElementsObservationContext)
    {
        if (![self isUpdating])
        {
            [self setNeedsUpdate];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

