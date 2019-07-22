/**
@file xibfiles.h
@brief This file only exists to put bits of Doxygen input that has nowhere else to go.
*/

/**
 @mainpage videoLat structure overview
 
 
 This is the internal developer-oriented documentation of videoLat. For user documentation and other information please visit the videoLat website at https://www.videolat.org .

 @section global Global structure overview
 
 The global structure of videoLat follows the normal pattern for a Cocoa dodument-based application.
 This global structure is contained in the files MainMenu.xib, Document.xib and the inevitable main.m.
 The main classes and their helper classes are:
 
 - Document, plus DeviceDescription, MachineDescription, MeasurementDataStore and MeasurementDistribution
 - DocumentView, plus DeviceDescriptionView, DocumentDescriptionView and GraphView
 - AppDelegate, plus CommonAppDelegate, MeasurementType, EventLogger and (for Mac only) PythonLoader.
 - New measurement control, described below.
 
 protocols.h is part of the global structure and defines various protocols implemented by multiple objects.
 
 compat.h and compat.m handle part of the support for the two platforms, OSX and iOS.
 
 In the XCode project, these sources are contained in the toplevel "src" group and the "Document" and "Supporting Files"
 groups.
 
 @section iOS iOS global structure
 
 The global structure for iPhone and iPad is based on the Main.storyboard. The first screen is controlled by
 MainMenuTableViewController which allows the user to select the task. The next levels are controlled by
 NewMeasurementTableViewController, NewCalibrationTableViewController, OpenDocumentTableViewController and
 DownloadCalibrationTableViewController.
 
 The first two are used to select a measurement type, after which we proceed to InputSelectionViewController to
 select the input, and then to MeasurementContainerViewController to do the measurement, using the
 structures described below.
 
 When the document has been selected (or created) we do an unwind segue to the toplevel where we open the
 document using DocumentViewController. If the user wants to do an action on the document (print, upload, etc)
 we popup a DocumentActionViewController.
 
 @section Measurements New measurement control
 
 On OSX there is a NewMeasurementViewController (in group NewDocument) that handles selection of the measurement type,
 as NewMeasurementTableViewController does on iOS.
 
 After the user has selected the measurement or calibration type and pressed OK a XIB file is loaded (into
 a new window on OSX, and as a subview of MeasurementContainerViewController on iOS) that is particular to the measurement
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

 @section Implementations New measurement implementations
 
 Each measurement run implementation consists at least of a XIB file and a subclass of BaseRunManager.
 
 The implemented measurement types are:
 
 - Video roundtrip, which does roundtrip delay measurements using QR code patterns.
   Contained in VideoRun.xib and VideoRunManager. It has helper classes VideoInput, VideoOutputView,
   VideoSelectionView, FindQRcode and GenQRcode.
 - Video calibration roundtrip, which is a specialisation of video roundtrip for calibrating the videoLat machine.
   It uses VideoCalibrationRun.xib and VideoCalibrationRunManager.
 - Video monochrome roundtrip, which is a specialisation of video roundtrip. It shows alternating 100% black and 100% white
   images.
   It uses VideoMonoRun.xib and VideoMonoRunManager.
 - Hardware (OSX only), which drives a LED to show light and uses a phototransistor to detect light, through either a LabJack U3
   USB interface or an arduino.
   It is intended to be "foton-compatible" with video monochrome roundtrip, and mainly exists to calibrate the hardware delay.
   The implementation is in HardwareRun.xib and HardwareRunManager. It has helper classes HardwareOutputView
   and LabJackDevice.
 - Mixed hardware-to-camera (OSX only). This uses an LED to generate light and detects it with the camera. The intention
   of this measurement type is to allow you to measure the delay of your input path only.
   The implementation is in HardwaretoCameraRun.xib and reuses the relevant components from video monochrome
   roundtrip and hardware. ScreenToHardwareRun.xib is the reverse, it generates light on the screen and detects it with the
   hardware.
 - Audio roundtrip. Plays out a sample and waits until it detects the same sample on input.
   Contained in AudioRun.xib and AudioRunManager, plus the helper classes AudioInput, AudioOutputView,
   AudioSelectionView and AudioProcess.
 - Audio calibration roundtrip, specialisation of audio roundtrip to measure the audio delay of the videoLat system.
   Contained in AudioCalibrationRun.xib and AudioCalibrationRunManager.
 - One-way measurements, with different sender and receiver machines that comminucate over the network, are
   implemented with NetworkRunManager and NetworkProtocol and 4 distinct XIB files. MasterSenderRun.xib is used
   on the image-transmitting side for normal measurements, it listens to a socket and communicates its port and
   IP through the first QR-code shown. SlaveReceiverRun.xib waits until it sees that QR code on the camera, connects to the
   server and then the measurement can proceed. There are two more XIB files that are very similar to these two, but
   for a slightly different purpose, they are used to calibrate the local camera (on the slave side) or the
   local screen (on the master side): MasterSenderScreenCalibrationRun.xib and SlaveReceiverCameraCalibrationRun.xib.
  
 In the XCode project, these measurements are grouped by type and contained in subgroups of the "MeasurementRun" group.
*/

/**
@file MainMenu.xib
@brief Standard NIB file for Cocoa applications (OSX only).

Holds the main menubar and instantiates the AppDelegate object.
 */

/**
@file Main.storyboard
@brief Standard storyboard file for APPKIT applications (iOS only).

Holds the overall user interface navigation structure.
 */

/**
@file Document.xib
@brief Standard NIB file for Cocoa applications.

Loading this NIB file creates the document window which holds a DocumentView instance,
a DocumentDescriptionView instance, two DeviceDescriptionView instances and two GraphView instances.
 */

/**
@file NewMeasurementView.xib
@brief NIB file that creates the window to select a new measurement type or download calibrations (OSX only).

Loading this NIB file creates a small window where the user either selects the measurement
type for a new run (after which the relevant measurement run XIB file is opened) or
select a calibration to download from videolat.org.
 */

/**
@file VideoRun/VideoRun.xib
@brief NIB file for VideoRunManager run.
 */

 /**
@file VideoCalibrationRun/VideoCalibrationRun.xib
@brief NIB file for VideoCalibrationRunManager run.
 */

 /**
@file VideoMonoRun.xib
@brief NIB file for VideoMonoRunManager run.
 */

 /**
@file HardwareRun.xib
@brief NIB file for HardwareRunManager run.
 */

/**
@file HardwareToCameraRun.xib
@brief NIB file for hardware-to-camera light measurement run.
 */

/**
@file ScreenToHardwareRun.xib
@brief NIB file for hardware-to-camera light measurement run.
 */

/**
@file MasterSenderRun/MasterSenderRun.xib
@brief NIB file for sending (server) side of asymetric measurements.
 */

/**
@file MasterSenderRun/MasterSenderScreenCalibrationRun.xib
@brief NIB file for sending (server) side of asymetric measurements to do a screen calibration.
 */

/**
@file SlaveReceiverRun/SlaveReceiverRun.xib
@brief NIB file for receiving (client) side of asymetric measurements.
 */

/**
@file SlaveReceiverRun/SlaveReceiverCameraCalibrationRun.xib
@brief NIB file for sending (server) side of asymetric measurements to do a camera calibration.
 */

/**
@file AudioRun/AudioRun.xib
@brief NIB file for AudioRunManager run.
 */

/**
@file AudioCalibrationRun/AudioCalibrationRun.xib
@brief NIB file for AudioCalibrationRunManager run.
*/
