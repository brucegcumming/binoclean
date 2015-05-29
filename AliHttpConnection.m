
//
//  AXiHttpConnection.m
//  TCPtest
//
//  Created by Ali Moeeny on 3/12/14.
//  Copyright (c) 2014 Ali Moeeny. All rights reserved.
//

#import "AliHttpConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"

extern Expt expt;
extern NSMutableArray * inputPipeBuffer;
NSString * outputPipeBuffer;
BOOL dataReadyInInputPipe;
char *DescribeState(char caller);
extern int inexptstim,innotify,ReadingInputPipe;
extern FILE *seroutfile;
int AddingToInputPipe = 0,AddingToOutputPipe = 0;;
static int notifyclash = 0;
extern struct timeval firstframetime,zeroframetime,exptstimtime;
struct timeval lastcalltime; //keep track of when this is called, to check that its not interupting expts
int checkinexpt = 0;
// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

@implementation AliHttpConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    return YES;
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();

	// Inform HTTP server that we expect a body to accompany a POST request

	if([method isEqualToString:@"POST"])
		return YES;

	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSData *outputdata = [@"" dataUsingEncoding:NSASCIIStringEncoding];
    NSString * s = @"";
    int readloop = 0;
    struct timeval now;
    float t,timediff(),zt;

    if ([method isEqualToString:@"GET"]) {
        if (request.url){
            if (request.url.pathComponents){
                if ([request.url.pathComponents count]>1){
                    //NSString * pq = [request.url.pathComponents[1] componentsSeparatedByString:@"="][1];
                    NSString * command = [[request.url.relativeString substringFromIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]; //request.url.pathComponents[1];
                    if (expt.verbose[4] > 0){
                        NSLog(@"Input Pipe: %@", command);
                    }
                    gettimeofday(&lastcalltime,NULL);
                    if (inexptstim && checkinexpt){
                        gettimeofday(&now,NULL);
                        zt = timediff(&firstframetime,&exptstimtime);
                        t = timediff(&now,&exptstimtime);
                        NSLog(@"http request while %.3f (%.3f, %.3f),%d frames into Expt Stim.",t,zt,(float)(zeroframetime.tv_usec)/1000000.0,expt.st->framectr);
                        NSLog(@"now usec, %.3f",(float)(now.tv_usec)/1000000.0);
                        if (expt.st->framectr > 0){
                            gettimeofday(&now,NULL);
                        }
                    }
                    AddingToOutputPipe = 1;
                    NSArray * sLines = [command componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
                    for (int i = 0; i < [sLines count]; i++) {
                        if (strncmp([[sLines objectAtIndex:i] UTF8String], "whatsup", 7) == 0){
                            if (innotify == 1){
                                notifyclash++;
                                NSLog(@"http request while notify is writing.");
                                s = [NSString stringWithFormat:@"NOTIFYCLASH%06d\n", notifyclash];
                            }
                            else{
                                s = [NSString stringWithFormat:@"SENDING%06d\n%@", [outputPipeBuffer length], outputPipeBuffer];
                                outputPipeBuffer = @"";
                                notifyclash = 0;
                            }
                            outputdata = [s dataUsingEncoding:NSASCIIStringEncoding];
                        }
                        else if (strncmp([[sLines objectAtIndex:i] UTF8String], "getstate", 8) == 0){
                            char * cs =DescribeState('1');
                            s = [NSString stringWithUTF8String:cs];
                            if([s length] == 0){
                                NSLog(@"Empty String conversion in GetState. strlen(*cs) is%d\n%s", strlen(cs),cs);
                                cs[5] = 'X'; //let verg know
                                DescribeState('2');
                            }
                            s = [[NSString alloc] initWithBytes:cs length:strlen(cs) encoding:NSASCIIStringEncoding];
                            outputdata = [s dataUsingEncoding:NSASCIIStringEncoding];
                        }
                        else if (strncmp([[sLines objectAtIndex:i] UTF8String], "login", 5) == 0){
// s http requet that seems to come to this port occasionally. ??? fro matlab or elsewhere?
                            NSLog(@"Login Request %@", command);
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"updatecommandhistory" object:nil userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:"Login Requested!!"] forKey:@"text"]];
                            if (seroutfile){
                                fprintf(seroutfile,"#HTTP%s\n",[[sLines objectAtIndex:i] UTF8String]);
                                fflush(seroutfile);
                            }
                        }
                        else{
                            if (!inputPipeBuffer) {
                                inputPipeBuffer = [[NSMutableArray alloc] init];
                            }
                            while (ReadingInputPipe && readloop < 100){
                                if (readloop %10 ==0 && expt.verbose[2]){
                                    NSLog(@"http request while ReadInputPipe is Reading(%d).", readloop);
                                }
                                readloop++;
                                usleep(100);
                            }
                            if (readloop > 0) { //? need to re-fetch the http stuff?
                                if (seroutfile){
                                    fprintf(seroutfile,"#HTTP input timed out reading: %s\n",[[sLines objectAtIndex:i] UTF8String]);
                                    fflush(seroutfile);
                                }
                            }
                            if (strncmp([[sLines objectAtIndex:i] UTF8String], "favico", 6) == 0){
                                NSLog(@"Supsicious Inputpipe %@", command);
                            }
                            AddingToInputPipe = 1;
                            [inputPipeBuffer addObject:[sLines objectAtIndex:i]];
                            AddingToInputPipe = 0;
                            dataReadyInInputPipe = YES;
                        }
                    }
                    AddingToOutputPipe = 0;
                }
            }
        }
    }
    //[outputdata retain];
    return [[HTTPDataResponse alloc] initWithData:outputdata];
    //	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();

	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();

	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.

	BOOL result = [request appendData:postDataChunk];
	if (!result)
	{
		HTTPLogError(@"%@[%p]: %@ - Couldn't append bytes!", THIS_FILE, self, THIS_METHOD);
	}
}

@end
