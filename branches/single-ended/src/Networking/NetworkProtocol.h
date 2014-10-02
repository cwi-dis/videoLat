//
//  NetworkProtocol.h
//  videoLat
//
//  Created by Jack Jansen on 02/10/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkProtocolDelegate
- (NSDictionary *)receivedFrom: (id)me;
- (void)disconnected:(id)me;
@end

@interface NetworkProtocolCommon : NSObject {
    int sock;
}

@property (weak) IBOutlet id <NetworkProtocolDelegate> delegate;
@property (readonly) NSString *host;
@property (readonly) int port;

- (NetworkProtocolCommon *)init;
- (void) send: (NSDictionary *)data;
- (void) sendString: (NSString *)data;
- (void) close;
@end

@interface NetworkProtocolServer : NetworkProtocolCommon
- (NetworkProtocolServer *)init;
- (void) sendString: (NSString *)data;
@end

@interface NetworkProtocolClient : NetworkProtocolCommon

- (NetworkProtocolClient *)initWithPort: (int)port host: (NSString*)host;

@end
