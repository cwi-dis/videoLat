//
//  NetworkProtocol.h
//  videoLat
//
//  Created by Jack Jansen on 02/10/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// Delegate protocol for monitoring a network connection.
///
@protocol NetworkProtocolDelegate

/// Data was received.
/// @param data NSDictionary containing key/value pairse of received message.
/// @param connection The connection that received the message.
- (void)received: (NSDictionary *)data from: (id)connection;

/// Connection was closed.
/// @param connection Which connection was closed.
- (void)disconnected:(id)connection;
@end

///
/// Common baseclass for NetworkProtocolServer and NetworkProtocolClient.
///
@interface NetworkProtocolCommon : NSThread {
    int sock;               //<! our socket
    NSString *sendBuffer;   //<! next buffer to send
}

@property (weak) IBOutlet id <NetworkProtocolDelegate> delegate;	//!< Our NetworkProtocolDelegate
@property (readonly) NSString *host;	//!< Our IP-address
@property (readonly) int port;			//!< Our portnumber

- (NetworkProtocolCommon *)init;

/// Send a message consisting of key/value pairs.
/// @param data The message to send.
- (void) send: (NSDictionary *)data;

/// Send a message consisting of a string.
/// @param data The string to send.
- (void) sendString: (NSString *)data;

/// Close the connection.
- (void) close;

/// Internal: main worker routine for NSThread.
- (void) main;
@end

///
/// Network connection, server side.
///
@interface NetworkProtocolServer : NetworkProtocolCommon
- (NetworkProtocolServer *)init;
@end

///
/// Network connection, client side.
///
@interface NetworkProtocolClient : NetworkProtocolCommon

/// Open a connection to the server.
/// @param port Server port number.
/// @param host Server hostname or IP address.
- (NetworkProtocolClient *)initWithPort: (int)port host: (NSString*)host;

@end
