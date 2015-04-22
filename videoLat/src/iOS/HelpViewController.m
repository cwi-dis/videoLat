//
//  HelpViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 22/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "HelpViewController.h"

@implementation HelpViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	((UIWebView *)self.view).delegate = self;
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"videolat_ios_help" withExtension:@"html"];
	[(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:url]];

}

- (BOOL) webView:(UIWebView *)webView 
      shouldStartLoadWithRequest:(NSURLRequest *)request 
      navigationType:(UIWebViewNavigationType)navigationType
{
  // detect link clicked
  if ( navigationType == UIWebViewNavigationTypeLinkClicked ) {
    // call safari
    [[UIApplication sharedApplication] openURL: request.URL];
	return NO;
  }
  
  return YES;
}
@end
