//
//  compat.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "compat.h"
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
	[[[UIAlertView alloc] initWithTitle:error.localizedDescription
                            message:error.localizedRecoverySuggestion
                           delegate:nil
                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                  otherButtonTitles:nil, nil] show];
#else
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
#endif
}

void showWarningAlert(NSString *warning) {
#ifdef WITH_UIKIT

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                            message:warning
                           delegate:nil
                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                  otherButtonTitles:nil, nil];
	[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
#else
    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", warning];
    [alert runModal];
#endif
}
