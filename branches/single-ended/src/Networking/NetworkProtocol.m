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
    socklen_t myAddrLen = sizeof(myAddr);
    int rv = getsockname(sock, (struct sockaddr *)&myAddr, &myAddrLen);
    if (rv < 0) {
        NSLog(@"getsockname failed: %s", strerror(errno));
        return nil;
    }
    
    return [NSString stringWithUTF8String: inet_ntoa(myAddr.sin_addr)];
}

- (int)port
{
    struct sockaddr_in myAddr;
    socklen_t myAddrLen = sizeof(myAddr);
    int rv = getsockname(sock, (struct sockaddr *)&myAddr, &myAddrLen);
    if (rv < 0) {
        NSLog(@"getsockname failed: %s", strerror(errno));
        return nil;
    }
    
    return ntohs(myAddr.sin_port);
}

- (NetworkProtocolCommon *)init
{
    self = [super init];
    if (self) {
        sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0) {
            NSLog(@"socket failed: %s", strerror(errno));
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
    if (jsonData == nil) {
        NSLog(@"dataWithJSONObject returned nil but no error");
        return;
    }
    NSString *stringData = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    if (stringData == nil) {
        NSLog(@"send: could not get NSString for NSdata for %@", data);
        return;
    }
    [self sendString: stringData];
}

- (void) sendString: (NSString *)data
{
    const char *cData = [data UTF8String];
    NSLog(@"sendString: sending %ld bytes", strlen(cData));
    ssize_t rv = send(sock, cData, strlen(cData), 0);
    if (rv < 0) {
        NSLog(@"send failed: %s", strerror(errno));
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
             NSLog(@"recv failed: %s", strerror(errno));
            [self close];
            [self.delegate disconnected: self];
        } else {
            if (buffer[0] == '{' && buffer[rv-1] == '}') {
                NSData *dataBuf = [NSData dataWithBytes:buffer length:rv];
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
            NSLog(@"listen failed: %s", strerror(errno));
            return nil;
        }
        [self start];
    }
    return self;
}

- (void)main
{
    struct sockaddr_in peerAddr;
    socklen_t peerAddrLen = sizeof(peerAddr);
    int connSock = accept(sock, (struct sockaddr *)&peerAddr, &peerAddrLen);
    if (connSock < 0) {
        NSLog(@"accept failed: %s", strerror(errno));
        [self close];
        [self.delegate disconnected: self];
        return;
    }
    close(sock);
    sock = connSock;
    [super main];
}

#if 0
- (void) sendString: (NSString *)data
{
    // Pass to server thread
}
#endif

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
