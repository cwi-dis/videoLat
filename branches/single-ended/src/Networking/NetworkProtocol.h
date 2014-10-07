//
//  NetworkProtocol.h
//  videoLat
//
//  Created by Jack Jansen on 02/10/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkProtocolDelegate
- (void)received: (NSDictionary *)data from: (id)connection;
- (void)disconnected:(id)connection;
@end

@interface NetworkProtocolCommon : NSThread {
    int sock;               //<! our socket
    NSString *sendBuffer;   //<! next buffer to send
}

@property (weak) IBOutlet id <NetworkProtocolDelegate> delegate;
@property (readonly) NSString *host;
@property (readonly) int port;

- (NetworkProtocolCommon *)init;
- (void) send: (NSDictionary *)data;
- (void) sendString: (NSString *)data;
- (void) close;
- (void) main;
@end

@interface NetworkProtocolServer : NetworkProtocolCommon
- (NetworkProtocolServer *)init;
- (void) sendString: (NSString *)data;
@end

@interface NetworkProtocolClient : NetworkProtocolCommon

- (NetworkProtocolClient *)initWithPort: (int)port host: (NSString*)host;

@end
