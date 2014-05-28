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

@property(weak) IBOutlet DocumentDescriptionView *status;
@property(weak) IBOutlet GraphView *values;
@property(weak) IBOutlet GraphView *distribution;
@property(weak) IBOutlet Document *document;

- (void)viewWillDraw;
- (void)updateView;
- (void)controlTextDidChange:(NSNotification *)aNotification;
@end
