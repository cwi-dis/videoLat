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
    NSError *myError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&myError];
    if (myError) {
        NSLog(@"dataWithJSONObject returned error %@", myError);
        return;
    }
    NSString *stringData = [NSString stringWithUTF8String:[jsonData bytes]];
    if (stringData) {
        [self sendString: stringData];
    } else {
        NSLog(@"send: could not get JSON data for %@", data);
    }
}

- (void) sendString: (NSString *)data
{
    const char *cData = [data UTF8String];
    NSLog(@"sendString: sending %ld bytes", strlen(cData));
    ssize_t rv = send(sock, cData, strlen(cData), 0);
    if (rv < 0) {
        [self close];
        [self.delegate disconnected: self];
    }
}

- (void) close
{
    close(sock);
    sock = -1;
}

- (void) main
{
    while (sock >= 0) {
        char buffer[2048];
        ssize_t rv = recv(sock, buffer, sizeof(buffer), 0);
        if (rv <= 0) {
            [self close];
            [self.delegate disconnected: self];
        } else {
            if (buffer[0] == '{' && buffer[rv-1] == '}') {
                NSData *dataBuf = [NSData dataWithBytesNoCopy:buffer length:rv];
                NSDictionary *data = [NSJSONSerialization JSONObjectWithData: dataBuf options:0 error:nil];
                [self.delegate received:data from:self];
            } else {
                NSLog(@"Received message not of form {.....}");
            }
        }
    }
}

@end

@implementation NetworkProtocolServer

- (NetworkProtocolServer *)init
{
    self = [super init];
    if (self) {
        assert(sock >= 0);
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
        assert(sock >= 0);
        struct sockaddr_in remote;
        memset(&remote, 0, sizeof(remote));
        remote.sin_family = AF_INET;
        remote.sin_addr.s_addr = inet_addr([host UTF8String]);
        remote.sin_port = htons(port);
        int rv = connect(sock, (struct sockaddr *)&remote, sizeof(remote));
        if (rv < 0) {
            NSLog(@"connect failed: %s", strerror(errno));
            return nil;
        }
        [self start];
    }
    return self;
}

@end
