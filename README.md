Actually asynchronous and cancelable URL connection
=======================

`+[NSURLConnection sendAsynchronousRequest:                          queue:completionHandler:]` has been reported to be built upon `+[NSURLConnection sendSynchronousRequest:returningResponse: error:]` and does not support cancellation.

This category adds a method that provides an actual asynchronous and cancelable connection. 
