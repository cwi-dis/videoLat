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

- (void) dealloc
{
}

- (NSString *)host
{
    // Use a datagram socket and connect it to a known website.
    int tmpSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (tmpSock < 0) {
        NSLog(@"socket(tmpSock) failed: %s", strerror(errno));
        return nil;
    }
    
    struct sockaddr_in remote;
    memset(&remote, 0, sizeof(remote));
    remote.sin_family = AF_INET;
    remote.sin_addr.s_addr = inet_addr("1.1.1.1");
    remote.sin_port = htons(11111);
    int rv = connect(tmpSock, (struct sockaddr *)&remote, sizeof(remote));
    if (rv < 0) {
        NSLog(@"connect(tmpSock) failed: %s", strerror(errno));
        return nil;
    }
    

    struct sockaddr_in myAddr;
    socklen_t myAddrLen = sizeof(myAddr);
    rv = getsockname(tmpSock, (struct sockaddr *)&myAddr, &myAddrLen);

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
    //NSLog(@"sendString: sending %ld bytes", strlen(cData));
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
	int bufsiz = 8192;
	char *buffer = malloc(bufsiz);
    while (sock >= 0) {
		char *bufptr = buffer;
		ssize_t rv;
		while(1) {
			if (buffer == NULL || bufptr == NULL) {
				NSLog(@"Receiver out of memory");
				[self close];
				[self.delegate disconnected: self];
				rv = -1;
				break;
			}
			rv = recv(sock, bufptr, (buffer+bufsiz)-bufptr, 0);
			if (rv < 0) break;
			if (bufptr[rv-1] == '}') {
				rv += (bufptr-buffer);
				break;
			}
			bufptr += rv;
			if (bufptr == buffer+bufsiz) {
				buffer = realloc(buffer, bufsiz*2);
				bufptr = buffer + bufsiz;
				bufsiz *= 2;
			}
		}
        if (rv <= 0) {
             NSLog(@"recv failed: %s", strerror(errno));
            [self close];
            [self.delegate disconnected: self];
			break;
        } else {
            char *closePtr = strchr(buffer, '}');
            if (buffer[0] == '{' && closePtr && *closePtr == '}') {
                NSData *dataBuf = [NSData dataWithBytes:buffer length:closePtr-buffer+1];
                assert(dataBuf);
                NSError *error;
                NSDictionary *data = [NSJSONSerialization JSONObjectWithData: dataBuf options:0 error:&error];
                if (data) {
                    [self.delegate received:data from:self];
                } else {
                    NSLog(@"NetworkProtocol: error json-decoding data: %@", error);
                }
            } else {
                NSLog(@"Received message not of form {.....}");
            }
        }
    }
	free(buffer);
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
