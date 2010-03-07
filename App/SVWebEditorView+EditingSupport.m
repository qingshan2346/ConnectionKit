//
//  SVWebEditorView+EditingSupport.m
//  Sandvox
//
//  Created by Mike on 15/02/2010.
//  Copyright 2010 Karelia Software. All rights reserved.
//


#import "SVWebEditorView.h"

#import "SVLinkInspector.h"


@implementation SVWebEditorView (EditingSupport)

#pragma mark Cut, Copy & Paste

- (void)cut:(id)sender
{
    // Let the WebView handle it unless there is no text selection
    if ([self selectedDOMRange])
    {
        [self forceWebViewToPerform:_cmd withObject:sender];
    }
    else
    {
        if ([self copySelectedItemsToGeneralPasteboard])
        {
            [self delete:sender];
        }
    }
}

- (void)copy:(id)sender
{
    // Let the WebView handle it unless there is no text selection
    if ([self selectedDOMRange])
    {
        [self forceWebViewToPerform:_cmd withObject:sender];
    }
    else
    {
        [self copySelectedItemsToGeneralPasteboard];
    }
}

- (BOOL)copySelectedItemsToGeneralPasteboard;
{
    // Rely on the datasource to serialize items to the pasteboard
    BOOL result = [[self dataSource] webEditor:self 
                                    writeItems:[self selectedItems]
                                  toPasteboard:[NSPasteboard generalPasteboard]];
    if (!result) NSBeep();
    
    return result;
}

- (void)delete:(id)sender forwardingSelector:(SEL)action;
{
    if ([self selectedDOMRange])
    {
        [self forceWebViewToPerform:action withObject:sender];
    }
    else
    {
        NSArray *items = [self selectedItems];
        if (![[self dataSource] webEditor:self deleteItems:items])
        {
            NSBeep();
        }
    }
}

- (void)delete:(id)sender;
{
    [self delete:sender forwardingSelector:_cmd];
}

- (void)deleteForward:(id)sender;
{
    [self delete:sender forwardingSelector:_cmd];
}

- (void)deleteBackward:(id)sender;
{
    [self delete:sender forwardingSelector:_cmd];
}

#pragma mark Links

- (void)createLink:(SVLinkInspector *)sender;
{
    //  Pass on to focused text
    if (![[self dataSource] webEditor:self createLink:sender])
    {
        if ([[self focusedText] respondsToSelector:_cmd])
        {
            [[self focusedText] performSelector:_cmd withObject:sender];
        }
    }
}

#pragma mark Undo

/*  Covers for private WebKit methods
 */

- (BOOL)allowsUndo { return [(NSTextView *)[self webView] allowsUndo]; }
- (void)setAllowsUndo:(BOOL)undo { [(NSTextView *)[self webView] setAllowsUndo:undo]; }

- (void)removeAllUndoActions
{
    [[self webView] performSelector:@selector(_clearUndoRedoOperations)];
}

@end
