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

///
/// Subclass of NSView, main view of the document. Contains the two graph views for distribution and samples
/// and the description view.
///
@interface DocumentView : NSView {
    BOOL initialValues; //!< Internal: helper variable to initialize subview values at the right time
};

@property(weak) IBOutlet DocumentDescriptionView *status;   //!< Set by NIB: view containing our metadata
@property(weak) IBOutlet GraphView *values;                 //!< Set by NIB: view showing the raw measurement values
@property(weak) IBOutlet GraphView *distribution;           //!< Set by NIB: view showing the measurement distribution
@property(weak) IBOutlet Document *document;                //!< Set by NIB: pointer to our Document

- (void)viewWillDraw;   //!< Called by window manager just before viewing, calls updateView if needed
- (void)updateView;     //!< Updates variables in status view so they reflect the document values
- (void)controlTextDidChange:(NSNotification *)aNotification;   //!< Called when description in status view has changed, updates the document
@end
