///
///  @file DocumentView.h
///  @brief Defines the DocumentView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "Protocols.h"
#import "DocumentDescriptionView.h"
#import "GraphView.h"
#import "Document.h"

///
/// Subclass of NSView, main view of the document. Contains the two graph views for distribution and samples
/// and the description view.
///
@interface DocumentView
#ifdef WITH_UIKIT
: UIScrollView <UIScrollViewDelegate>
#else
: NSView
#endif
{
    BOOL initialValues; //!< Internal: helper variable to initialize subview values at the right time
    __weak Document *_modelObject;	//!< Our document.
#ifdef WITH_UIKIT
	CGPoint _pointToCenterAfterResize;	//!< Helper variable to handle iOS device orientation changes.
	CGFloat _scaleToRestoreAfterResize;	//!< Helper variable to handle iOS device orientation changes.
#endif
};

@property(weak) IBOutlet DocumentDescriptionView *status;   //!< Set by NIB: view containing our metadata
@property(weak) IBOutlet GraphView *values;                 //!< Set by NIB: view showing the raw measurement values
@property(weak) IBOutlet GraphView *distribution;           //!< Set by NIB: view showing the measurement distribution
@property(weak) IBOutlet Document *modelObject;             //!< Set by NIB: pointer to our Document
#ifdef WITH_UIKIT
@property(weak) IBOutlet UIView *scrolledView;	//!< Outer view that handles scrolling and scaling the DocumentView
#endif

- (void)_updateView;     //!< Updates variables in status view so they reflect the document values
- (void)controlTextDidChange:(NSNotification *)aNotification;   //!< Called when description in status view has changed, updates the document

#ifdef WITH_APPKIT
- (void)viewWillDraw;   //!< Called by window manager just before viewing, calls updateView if needed
- (IBAction)openInputCalibration:(id)sender;	//!< UI callback method that opens the calibration of the input device
- (IBAction)openOutputCalibration:(id)sender;	//!< UI callback method that opens the calibration of the output device
#endif

#ifdef WITH_UIKIT
- (NSData *)generatePDF;	//!< Generate PDF for printing or emailing.
#endif
@end
