/**
@file xibfiles.h
@brief This file only exists to put bits of Doxygen input that has nowhere else to go.
*/

/**
 @mainpage videoLat structure overview
 
 
 This is the internal developer-oriented documentation of videoLat. For user documentation and other information please visit the videoLat website at http://www.videolat.org .

 @section global Global structure overview
 
 The global structure of videoLat follows the normal pattern for a Cocoa dodument-based application.
 This global structure is contained in the files MainMenu.xib, Document.xib and the inevitable main.m.
 The main classes and their helper classes are:
 
 - Document, plus DeviceDescription, MachineDescription, MeasurementDataStore and MeasurementDistribution
 - DocumentView, plus DeviceDescriptionView, DocumentDescriptionView and GraphView
 - AppDelegate, plus CommonAppDelegate, MeasurementType, EventLogger and (for Mac only) PythonLoader.
 
 protocols.h is part of the global structure and defines various protocols implemented by multiple objects.
 
 compat.h and compat.m handle part of the support for the two platforms, OSX and iOS.
 
 In the XCode project, these sources are contained in the toplevel "src" group and the "Document" and "Supporting Files"
 groups.
 
 @section iOS global structure
 
 The global structure for iPhone and iPad is based on the Main.storyboard. The first screen is controlled by
 MainMenuTableViewController which allows the user to select the task. The next levels are controlled by
 NewMeasurementTableViewController, NewClibrationTableViewController, OpenDocumentTableViewController and
 DownloadCalibrationTableViewController. 
 
 The first two are used to select a measurement type, after which we proceed to InputSelectionViewController to
 select the input, and then to MeasurementContainerViewController to do the measurement, using the
 
 When the document has been selected (or created) we do an unwind segue to the toplevel where we open the
 document using DocumentViewController. If the user wants to do an action on the document (print, upload, etc)
 we popup a DocumentActionViewController.
 
 @section Measurements New measurement control
 
 On OSX there is a NewMeasurementView (in group NewDocument) that handles selection of the measurement type,
 as NewMeasurementTableViewController does on iOS.
 
 After the user has selected the measurement or calibration type and pressed OK a XIB file is loaded (into
 a new window on OSX, and as a subview of MeasurementContainerView on iOS) that is particular to the measurement
 being done.
 
 Note that the XIB files differ between iOS and OSX, but the names are the same. The sources for the iOS
 XIB files are in an "iOS" subdirectory, whereas the OSX XIB file lives with the implementation classes in the
 per-measurement-type subdirectory of "src".
 
 These XIB files will generally contain a number of views and objects:
 
 - a RunManagerView containing all the other bits.
 - a RunStatusView gives the user feedback on current delay average and such.
 - a runmanager, an instance of a subclass of BaseRunManager that controls the measurement run.
 - for asymetric measurements a second BaseRunManager subclass instance to handle to output aspects of
   the measurement run.
 - An input capturer, adhering to InputCaptureProtocol, to grab images (or audio, or something else).
 - A view adhering to OutputViewProtocol to show the output codes.
 - a RunCollector to collect the data points (individual delay measurements).
 
 In the XCode project, these source files are contained in the "MeasurementRun" group, and the individual
 implementation in its subgroups.
 
 xxxjack got to here.
 
 @section Implementations New measurement implementations
 
 Each measurement run implementation consists at least of a XIB file and a subclass of BaseRunManager.
 
 The implemented measurement types are:
 
 - Video roundtrip, which does roundtrip delay measurements using QR code patterns.
   Contained in VideoRun.xib and VideoRunManager. It has helper classes VideoInput, VideoOutputView,
   VideoSelectionView, FindQRcodes and GenQRcodes.
 - Video calibration roundtrip, which is a specialisation of video roundtrip for calibrating the videoLat machine.
   It uses VideoCalibrationRunManager.xib and VideoCalibrationRunManager.
 - Video monochrome roundtrip, which is a specialisation of video roundtrip. It shows alternating 100% black and 100% white
   images.
   It uses VideoMonoRunManager.xib and VideoMonoRunManager.
 - Hardware, which drives a LED to show light and uses a phototransistor to detect light, through a LabJack U3
   USB interface.
   It is intended to be "foton-compatible" with video monochrome roundtrip, and mainly exists to calibrate the hardware delay.
   The implementation is in HardwareRunManager.xib and HardwareRunManager. It has helper classes HardwareOutputView
   and LabJackDevice.
 - Mixed hardware-to-camera. This uses an LED to generate light and detects it with the camera. The intention
   of this measurement type is to allow you to measure the delay of your input path only.
   The implementation is in HardwaretoCameraRunManager.xib and reuses the relevant components from video monochrome
   roundtrip and hardware.
 - Audio roundtrip. Plays out a sample and waits until it detects the same sample on input.
   Contained in AudioRunManager.xib and AudioRunManager, plus the helper classes AudioInput, AudioOutputView,
   AudioSelectionView and AudioProcess.
 - Audio calibration roundtrip, specialisation of audio roundtrip to measure the audio delay of the videoLat system.
   Contained in AudioCalibrationRunManager.xib and AudioCalibrationRunManager.
 
 What has not been implemented yet is network roundtrip, which should measure the network delay to another videoLat
 instance running elsewhere, and mixed screen-to-hardware. Once these two have been implemented we have all the
 framework needed to do one-way measurements, by running one videoLat as a sender and another as a receiver
 and connect them through the network. Once that has been done an iPhone port becomes feasible, using two iPhones
 at each end of the connection.
 
 In the XCode project, these measurements are grouped by type and contained in subgroups of the "MeasurementRun" group.
*/

/**
@file MainMenu.xib
@brief Standard NIB file for Cocoa applications.

Holds the main menubar and instantiates the appDelegate object.
 */

/**
@file Document.xib
@brief Standard NIB file for Cocoa applications.

Loading this NIB file creates the document window which holds a DocumentView instance,
a DocumentDescriptionView instance and two GraphView instances.
 */

/**
@file NewMeasurement.xib
@brief NIB file that creates the window to control a new measurement run.

Loading this NIB file creates a window that contains a RunTypeView and a RunStatusView, plus
two placeholder NSView objects where the input view and output view objects will be inserted into.
The file's owner is the Document object.
 */

/**
@file VideoRunManager.xib
@brief NIB file for VideoRunManager run.

This NIB file in loaded the user selects a video run. It loads up the bits into the
window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
In addition it allocates VideoRunManager, VideoInput, FindQRCodes and GenQRCodes objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

 /**
@file VideoCalibrationRunManager.xib
@brief NIB file for VideoCalibrationRunManager run.

 This NIB file in loaded the user selects a video calibration run. It loads up the bits into the
window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
In addition it allocates VideoCalibrationRunManager, VideoInput, FindQRCodes and GenQRCodes objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

 /**
@file VideoMonoRunManager.xib
@brief NIB file for VideoMonoRunManager run.

This NIB file in loaded the user selects a black/white video run. It loads up the bits into the
window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
In addition it allocates VideoMonoRunManager, VideoInput, FindQRCodes and GenQRCodes objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

 /**
@file HardwareRunManager.xib
@brief NIB file for HardwareRunManager run.

This NIB file in loaded the user selects a hardware light/no light run. It loads up the bits into the
window that was created from NewMeasurement.xib with a HardwareOutputView.
In addition it allocates HardwareRunManager, and LabJackDevice objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

/**
@file HardwareToCameraRunManager.xib
@brief NIB file for hardware-to-camera light measurement run.

This NIB file in loaded the user selects a hardware-light-to-camera run. It loads up the bits into the
window that was created from NewMeasurement.xib with a HardwareOutputView and a VideoSelectionView.
In addition it allocates VideoMonoRunManager and HardwareRunManager objects and links them together (the first
for input, the second for output). The corresponding VideoInput and LabJackDevice objects are also allocated.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

/**
@file AudioRunManager.xib
@brief NIB file for AudioRunManager run.

This NIB file in loaded the user selects an audio run. It loads up the bits into the
window that was created from NewMeasurement.xib with a AudioOutputView and a AudioSelectionView.
In addition it allocates AudioRunManager, AudioInput and AudioProcess objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
 */

/**
@file AudioCalibrationRunManager.xib
@brief NIB file for AudioCalibrationRunManager run.

This NIB file in loaded the user selects an audio run. It loads up the bits into the
window that was created from NewMeasurement.xib with a AudioOutputView and a AudioSelectionView.
In addition it allocates AudioCalibrationRunManager, AudioInput and AudioProcess objects.

The file's owner is the RunTypeView object from the NewMeasurement.xib file.
*/
