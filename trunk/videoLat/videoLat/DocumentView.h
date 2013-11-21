//
//  DocumentView.h
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import <Cocoa/Cocoa.h>
#import "Protocols.h"
#import "DocumentDescriptionView.h"
#import "GraphView.h"
#import "Document.h"

@interface DocumentView : NSView {
    BOOL initialValues;
};

@property(retain) IBOutlet DocumentDescriptionView *status;
@property(retain) IBOutlet GraphView *values;
@property(retain) IBOutlet GraphView *distribution;
@property(retain) IBOutlet Document *document;

- (void)viewWillDraw;
- (void)updateView;
- (void)controlTextDidChange:(NSNotification *)aNotification;
@end
