///
/// @file xibfiles.h
/// @brief This file only exists to put bits of Doxygen input that has nowhere else to go.

/// @file MainMenu.xib
/// @brief Standard NIB file for Cocoa applications.
///
/// Holds the main menubar and instantiates the appDelegate object.

/// @file Document.xib
/// @brief Standard NIB file for Cocoa applications.
///
/// Loading this NIB file creates the document window which holds a DocumentView instance,
/// a DocumentDescriptionView instance and two GraphView instances.

/// @file NewMeasurement.xib
/// @brief NIB file that creates the window to control a new measurement run.
///
/// Loading this NIB file creates a window that contains a RunTypeView and a RunStatusView, plus
/// two placeholder NSView objects where the input view and output view objects will be inserted into.
/// The file's owner is the Document object.

/// @file VideoRunManager.xib
/// @brief NIB file for VideoRunManager run.
///
/// This NIB file in loaded the user selects a video run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
/// In addition it allocates VideoRunManager, VideoInput, FindQRCodes and GenQRCodes objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.

/// @file VideoCalibrationRunManager.xib
/// @brief NIB file for VideoCalibrationRunManager run.
///
/// This NIB file in loaded the user selects a video calibration run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
/// In addition it allocates VideoCalibrationRunManager, VideoInput, FindQRCodes and GenQRCodes objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.

/// @file VideoMonoRunManager.xib
/// @brief NIB file for VideoMonoRunManager run.
///
/// This NIB file in loaded the user selects a black/white video run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a VideoOutputView and a VideoSelectionView.
/// In addition it allocates VideoMonoRunManager, VideoInput, FindQRCodes and GenQRCodes objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.


/// @file HardwareRunManager.xib
/// @brief NIB file for HardwareRunManager run.
///
/// This NIB file in loaded the user selects a hardware light/no light run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a HardwareOutputView.
/// In addition it allocates HardwareRunManager, and LabJackDevice objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.


/// @file HardwareToCameraRunManager.xib
/// @brief NIB file for hardware-to-camera light measurement run.
///
/// This NIB file in loaded the user selects a hardware-light-to-camera run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a HardwareOutputView and a VideoSelectionView.
/// In addition it allocates VideoMonoRunManager and HardwareRunManager objects and links them together (the first
/// for input, the second for output). The corresponding VideoInput and LabJackDevice objects are also allocated.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.

/// @file AudioRunManager.xib
/// @brief NIB file for AudioRunManager run.
///
/// This NIB file in loaded the user selects an audio run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a AudioOutputView and a AudioSelectionView.
/// In addition it allocates AudioRunManager, AudioInput and AudioProcess objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.

/// @file AudioCalibrationRunManager.xib
/// @brief NIB file for AudioCalibrationRunManager run.
///
/// This NIB file in loaded the user selects an audio run. It loads up the bits into the
/// window that was created from NewMeasurement.xib with a AudioOutputView and a AudioSelectionView.
/// In addition it allocates AudioCalibrationRunManager, AudioInput and AudioProcess objects.
///
/// The file's owner is the RunTypeView object from the NewMeasurement.xib file.
