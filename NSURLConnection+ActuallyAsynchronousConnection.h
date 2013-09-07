//
//  NSURLConnection+ActuallyAsynchronousConnection.h
//  Asynchronous Connection
//
//  Created by Damien DeVille on 9/5/13.
//  Copyright (c) 2013 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (ActuallyAsynchronousConnection)

/*!
	Perform a cancellable and actually asynchronous request.
	
	@param request The request to load. The request is copied as part of the initialization.
	@param queue An NSOperationQueue upon which the handler block will be dispatched.
	@param completionHandler A block which receives the results of the resource load.
	
	@return	An opaque object to act as the connection. You should only use this returned value to cancel the connection.
 */
+ (id)sendActuallyAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError))completionHandler;

/*!
	Cancel a previously created asynchronous connection request.
	
	@param connection The asynchronous connection to cancel. Must not be nil and must only be an object returned by `-sendActuallyAsynchronousRequest:queue:completionHandler:`.
 */
+ (void)cancelActuallyAsynchronousRequest:(id)connection;

@end
