///
///  @file compat.h
///  @brief Defines, typedefs and functions to handle iOS/OSX compatibility.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "compat.h"
#import "AppDelegate.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

uint64_t monotonicMicroSecondClock()
{
#ifdef WITH_MACH_ABSOLUTE_TIME
    UInt64 machTimestamp = mach_absolute_time();
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    uint64_t timestamp = machTimestamp * info.numer / (info.denom * 1000);
#endif
#ifdef WITH_HOST_GET_CLOCK_SERVICE
    clock_serv_t cclock;
    mach_timespec_t mts;
    
    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);
    uint64_t timestamp = ((UInt64)mts.tv_sec*1000000LL) + mts.tv_nsec/1000LL;
#endif
    return timestamp;

}

void showErrorAlert(NSError *error) {
#ifdef WITH_UIKIT
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:error.localizedDescription
                                 message:error.localizedRecoverySuggestion
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    // Note that this does not run modal....
    [rootVC presentViewController:alert animated:YES completion:nil];
#else
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
#endif
}

void showWarningAlert(NSString *warning) {
#ifdef WITH_UIKIT
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Warning"
                                 message:warning
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alert addAction:ok];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    // Note that this does not run modal....
    [rootVC presentViewController:alert animated:YES completion:nil];
#else
    
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(showAlert:) withObject:warning waitUntilDone:YES];
#endif
}
