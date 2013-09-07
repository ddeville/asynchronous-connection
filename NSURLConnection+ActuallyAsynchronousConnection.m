//
//  NSURLConnection+ActuallyAsynchronousConnection.m
//  Actually Asynchronous Connection
//
//  Created by Damien DeVille on 9/5/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import "NSURLConnection+ActuallyAsynchronousConnection.h"

@interface _NSURLActuallyAsynchronousURLConnectionOperation : NSOperation <NSURLConnectionDataDelegate>

- (id)initWithRequest:(NSURLRequest *)request;

@end

@interface _NSURLActuallyAsynchronousURLConnectionOperation (/* Connection */)

@property (strong, nonatomic) NSURLConnection *connection;

@property (strong, nonatomic) NSURLResponse *response;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSError *error;

@end

@interface _NSURLActuallyAsynchronousURLConnectionOperation (/* Operation */)

@property (assign, nonatomic) BOOL isExecuting, isFinished;

@property (strong, nonatomic) NSOperationQueue *connectionQueue;

@end

@implementation _NSURLActuallyAsynchronousURLConnectionOperation

static NSString * const _NSURLOperationIsExecuting = @"isExecuting";
static NSString * const _NSURLOperationIsFinished = @"isFinished";

- (id)initWithRequest:(NSURLRequest *)request
{
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	_connectionQueue = [[NSOperationQueue alloc] init];
	[_connectionQueue setName:[NSString stringWithFormat:@"%@-%@", NSStringFromClass([self class]), @"connection"]];
	[_connectionQueue setMaxConcurrentOperationCount:1];
	
	_connection = [[NSURLConnection alloc] initWithRequest:[request copy] delegate:self startImmediately:NO];
	[_connection setDelegateQueue:_connectionQueue];
	
	_error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	
	return self;
}

- (BOOL)isConcurrent
{
	return YES;
}

- (void)start
{
	[[self connectionQueue] addOperationWithBlock:^ {
		[self willChangeValueForKey:_NSURLOperationIsExecuting];
		[self setIsExecuting:YES];
		[self didChangeValueForKey:_NSURLOperationIsExecuting];
		
		[[self connection] start];
	}];
}

- (void)cancel
{
	[[self connectionQueue] addOperationWithBlock:^ {
		[[self connection] cancel];
		
		[self _finish];
		
		[super cancel];
	}];
	
	[super cancel];
}

- (void)_finish
{
	[self setConnection:nil];
	
	[self willChangeValueForKey:_NSURLOperationIsExecuting];
	[self setIsExecuting:YES];
	[self didChangeValueForKey:_NSURLOperationIsExecuting];
	
	[self willChangeValueForKey:_NSURLOperationIsFinished];
	[self setIsFinished:YES];
	[self didChangeValueForKey:_NSURLOperationIsFinished];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self setResponse:nil];
	[self setData:nil];
	[self setError:error];
	
	[self _finish];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[self setResponse:response];
	[self setData:[NSMutableData data]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[[self data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self setError:nil];
	
	[self _finish];
}

@end

#pragma mark -

@implementation NSURLConnection (ActuallyAsynchronousConnection)

+ (NSOperationQueue *)_actuallyAsynchronousURLConnectionOperationQueue
{
	static NSOperationQueue *actuallyAsynchronousURLConnectionOperationQueue = nil;
	
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^ {
		actuallyAsynchronousURLConnectionOperationQueue = [[NSOperationQueue alloc] init];
	});
	
	return actuallyAsynchronousURLConnectionOperationQueue;
}

+ (id)sendActuallyAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError))completionHandler
{
	queue = queue ? : [NSOperationQueue mainQueue];
	completionHandler = completionHandler ? : ^ (NSURLResponse *response, NSData *data, NSError *connectionError) {};
	
	_NSURLActuallyAsynchronousURLConnectionOperation *connectionOperation = [[_NSURLActuallyAsynchronousURLConnectionOperation alloc] initWithRequest:request];
	[[self _actuallyAsynchronousURLConnectionOperationQueue] addOperation:connectionOperation];
	
	NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^ {
		NSURLResponse *response = [connectionOperation response];
		NSData *data = [NSData dataWithData:[connectionOperation data]];
		NSError *connectionError = [connectionOperation error];
		
		completionHandler(response, data, connectionError);
	}];
	[completionOperation addDependency:connectionOperation];
	[queue addOperation:completionOperation];
	
	return connectionOperation;
}

+ (void)cancelActuallyAsynchronousRequest:(id)asynchronousRequest
{
	NSParameterAssert([asynchronousRequest isKindOfClass:[_NSURLActuallyAsynchronousURLConnectionOperation class]]);
	
	_NSURLActuallyAsynchronousURLConnectionOperation *operation = (_NSURLActuallyAsynchronousURLConnectionOperation *)asynchronousRequest;
	[operation cancel];
}

@end
