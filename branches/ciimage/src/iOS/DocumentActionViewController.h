//
//  DocumentActionViewController.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 3/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Document.h"

///
/// View controller for operations on documents.
///
@interface DocumentActionViewController : UIViewController
@property(weak) Document *document;
@property(weak) IBOutlet UIButton *bPrint;
@property(weak) IBOutlet UIButton *bUpload;

@end
