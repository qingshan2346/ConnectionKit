//
//  SVURLPreviewViewController.h
//  Sandvox
//
//  Created by Mike on 15/01/2010.
//  Copyright 2010 Karelia Software. All rights reserved.
//

#import "KSWebViewController.h"
#import "SVSiteItemViewController.h"


@interface SVURLPreviewViewController : KSWebViewController <SVSiteItemViewController>
{
  @private
    id <SVSiteItemViewControllerDelegate>   _delegate;
    BOOL    _readyToAppear;
}

@property(nonatomic, assign) id <SVSiteItemViewControllerDelegate> delegate;

@end
