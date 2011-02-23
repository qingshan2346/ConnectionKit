//
//  TweetButtonInspector.m
//  TweetButtonElement
//
//  Created by Terrence Talbot on 2/21/11.
//  Copyright 2011 Terrence Talbot. All rights reserved.
//

#import "TweetButtonInspector.h"


@implementation TweetButtonInspector

- (void)updatePlaceholder
{
    NSString *title = [self.inspectedPagesController valueForKeyPath:@"selection.title"];
    [[[self tweetTextField] cell] setPlaceholderString:title];
}

- (void)awakeFromNib
{
    [self.inspectedPagesController addObserver:self 
                                    forKeyPath:@"selection.title"
                                       options:0 
                                       context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( [keyPath isEqualToString:@"selection.title" ] )
    {
        [self updatePlaceholder];
    }
}

- (void)dealloc
{
    [self.inspectedPagesController removeObserver:self forKeyPath:@"selection.title"];
    self.inspectedPagesController = nil;
    self.tweetTextField = nil;
    [super dealloc];
}


@synthesize inspectedPagesController = _inspectedPagesController;
@synthesize tweetTextField = _tweetTextField;
@end