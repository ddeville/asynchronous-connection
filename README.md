Actually asynchronous and cancelable URL connection
=======================

`+[NSURLConnection sendAsynchronousRequest:                          queue:completionHandler:]` has been [reported](https://twitter.com/landonfuller/status/375403178206171137) to be built upon `+[NSURLConnection sendSynchronousRequest:returningResponse: error:]` and does not support cancellation.

This category adds a method that provides an actual asynchronous and cancelable connection. 
