//
//  NetworkProtocol.m
//  videoLat
//
//  Created by Jack Jansen on 02/10/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkProtocol.h"
#import <sys/socket.h>
#import <arpa/inet.h>

@implementation NetworkProtocolCommon

@synthesize delegate;

- (NSString *)host
{
    struct sockaddr_in myAddr;
    getsockname(sock, (struct sockaddr *)&myAddr, sizeof(myAddr));
    
    return [NSString stringWithUTF8String: inet_ntoa(myAddr.sin_addr)];
}

- (int)port
{
    struct sockaddr_in myAddr;
    getsockname(sock, (struct sockaddr *)&myAddr, sizeof(myAddr));
    
    return ntohs(myAddr.sin_port);
}

- (NetworkProtocolCommon *)init
{
    self = [super init];
    if (self) {
        sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0) {
            NSLog(@"Cannot create socket");
            return nil;
        }
    }
    return self;
}

- (void) send: (NSDictionary *)data
{
    NSString *stringData = [NSString stringWithFormat: @"%@", data];
    [self sendString: stringData];
}

- (void) sendString: (NSString *)data
{
    const char *cData = [data UTF8String];
    ssize_t rv = send(sock, cData, strlen(cData), 0);
    if (rv < 0) {
        [self.delegate disconnected: self];
        [self close];
    }
}

- (void) close
{
}

@end

@implementation NetworkProtocolServer

- (NetworkProtocolServer *)init
{
    self = [super init];
    if (self) {
        int rv = listen(sock, 1);
        if (rv < 0) {
            NSLog(@"listen failed");
            return nil;
        }
        // XXXJACK start receiver thread, and maybe wait for it?
    }
    return self;
}

- (void) sendString: (NSString *)data
{
    // Pass to server thread
}

@end

@implementation NetworkProtocolClient


- (NetworkProtocolClient *)initWithPort: (int)port host: (NSString*)host
{
    self = [super init];
    if (self) {
        struct sockaddr_in remote;
        remote.sin_family = AF_INET;
        remote.sin_addr.s_addr = inet_addr([host UTF8String]);
        remote.sin_port = htons(port);
        int rv = connect(sock, NULL, port);
        if (rv < 0) {
            NSLog(@"connect failed");
            return nil;
        }
    }
    return self;
}

@end
