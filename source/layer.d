/**
#
#Copyright (c) 2019 IoTone, Inc. All rights reserved.
#
**/
module lambd.layer;

import std.json;
import std.string;
import std.net.curl;
import core.time;
import std.stdio;
import std.conv;
import std.socket;
import std.regex;
import std.process;
import std.format;

// import core.stdc.stdlib;

nothrow extern (C) {
   char* getenv(const char*);
}

/**
 * Lambda Environment variable defs
 */
static immutable auto AWS_LAMBDA_FUNCTION_NAME = "AWS_LAMBDA_FUNCTION_NAME";
static immutable auto AWS_LAMBDA_FUNCTION_VERSION = "AWS_LAMBDA_FUNCTION_VERSION";
static immutable auto AWS_LAMBDA_FUNCTION_MEMORY_SIZE = "AWS_LAMBDA_FUNCTION_MEMORY_SIZE";
static immutable auto AWS_LAMBDA_LOG_GROUP_NAME = "AWS_LAMBDA_LOG_GROUP_NAME";
static immutable auto AWS_LAMBDA_LOG_STREAM_NAME = "AWS_LAMBDA_LOG_STREAM_NAME";
static immutable auto AWS_LAMBDA_RUNTIME_API = "AWS_LAMBDA_RUNTIME_API";
static immutable auto AWS_LAMBDA_RUNTIME_BASE = "/2018-06-01/runtime";
static immutable auto AWS_LAMBDA_RUNTIME_INVOCATION_NEXT = AWS_LAMBDA_RUNTIME_BASE ~ "/invocation/next";
static immutable auto AWS_LAMBDA_RUNTIME_INVOCATION_RESPONSE = AWS_LAMBDA_RUNTIME_BASE ~ "/invocation/%s/response";
// ENV["_X_AMZN_TRACE_ID"] = res.headers["Lambda-Runtime-Trace-Id"]? || ""

/**
 * LambdaContext
 * Inspired by nim's awslambda.nim
 *
 */
struct LambdaContext {
  string functionName;
  string invokedFunctionArn;
  string functionVersion;
  int memoryLimitInMB;          /* max limit is currently 2GB? */
  string logGroupName;
  string logStreamName;
  string awsRequestId;
  uint deadline;            /* Max MS is 60 (sec) * 1000 (ms) * 15min = 900000 */
  JSONValue identity;
  JSONValue clientContext;
}

unittest {
  auto myctx = LambdaContext ("myfunc",
						"somefakearn",
						"1.0.0",
						512, /* mb */
						"someloggroupname",
						"somelogstreamname",
						"somefakeawsrequestID",
						3000, /* only run for 3000ms */
						parseJSON("{}"), /* Fill in with an AWS identity JSON */
						parseJSON("{}") /* Fill in with some AWS client context */
	);
  assert(myctx.awsRequestId == "somefakeawsrequestID");
  assert(myctx.clientContext == parseJSON("{}"));
  assert(myctx.deadline == 3000);
  assert(myctx.memoryLimitInMB == 512);
  assert(myctx.logGroupName == "someloggroupname");
  assert(myctx.logStreamName == "somelogstreamname");
  assert(myctx.identity == parseJSON("{}"));
}

// static alias void function(int err, ref ubyte[] data) CallbackFunc;
static alias JSONValue function(JSONValue evt, LambdaContext ctx) HandlerFunc;
 


/**
 * runHandler
 *
 * General idea: Pass in a HandlerFunc and a Callback
 * Set the environment in the context
 * Invoke the runtime base
 * Run the handler
 * Post the handler response
 *
 */
void runHandler(HandlerFunc handler) {
  LambdaContext context;
  string awsLambdaRuntimeAPI;
  JSONValue event;
  JSONValue result;

  /**
   * Set data from environment
   */
  if (environment[AWS_LAMBDA_FUNCTION_NAME] != null) {
    context.functionName = environment[AWS_LAMBDA_FUNCTION_NAME];
  }

  if (environment[AWS_LAMBDA_FUNCTION_VERSION] != null) {
    context.functionVersion = environment[AWS_LAMBDA_FUNCTION_VERSION];
  }

  if (environment[AWS_LAMBDA_FUNCTION_MEMORY_SIZE] != null) {
    context.memoryLimitInMB = to!int(environment[AWS_LAMBDA_FUNCTION_MEMORY_SIZE]);
  }

  if (environment[AWS_LAMBDA_LOG_GROUP_NAME] != null) {
    context.logGroupName = environment[AWS_LAMBDA_LOG_GROUP_NAME];
  }

  if (environment[AWS_LAMBDA_LOG_STREAM_NAME] != null) {
    context.logStreamName = environment[AWS_LAMBDA_LOG_STREAM_NAME];
  }

  if (environment[AWS_LAMBDA_RUNTIME_API] != null) {
    awsLambdaRuntimeAPI = environment[AWS_LAMBDA_RUNTIME_API];
  }

  auto http = HTTP(awsLambdaRuntimeAPI ~ AWS_LAMBDA_RUNTIME_INVOCATION_NEXT);

  while(true) {
    int responseCode;
    // XXX Fix all of these calls to grab data from callbacks
    http.onReceiveStatusLine = (HTTP.StatusLine status){ responseCode = status.code; };
    http.onReceive = (ubyte[] data) {
      event = parseJSON(to!(const(char)[])(data));
      

      if (responseCode != 200) {
        throw new LambDException("Failure to invoke AwsLambdaRuntimeAPI, reason: statusCode = " ~ to!string(responseCode) ~ 
        "details: awsLambdaRuntimeAPI: " ~ awsLambdaRuntimeAPI ~ AWS_LAMBDA_RUNTIME_INVOCATION_NEXT ~ " calling function name: " ~ context.functionName);
      }
      

      if ("Lambda-Runtime-Aws-Request-Id" in http.responseHeaders) {
        context.awsRequestId =  http.responseHeaders["Lambda-Runtime-Aws-Request-Id"];
      }
      context.invokedFunctionArn =  http.responseHeaders["Lambda-Runtime-Invoked-Function-Arn"];
      context.deadline = to!uint(http.responseHeaders["Lambda-Runtime-Deadline-Ms"]);

      if (http.responseHeaders["Lambda-Runtime-Cognito-Identity"] != null) {
        context.identity = parseJSON(http.responseHeaders["Lambda-Runtime-Cognito-Identity"]);
      } else {
        context.identity.object = null;
      }

      if (http.responseHeaders["Lambda-Runtime-Client-Context"] != null) {
        context.clientContext = parseJSON(http.responseHeaders["Lambda-Runtime-Client-Context"]);
      } else {
        context.clientContext.object = null;
      }

      // Might want to se this: putEnv("_X_AMZN_TRACE_ID", res.headers.getOrDefault("Lambda-Runtime-Trace-Id"))

      //
      // Invoke the handler
      //
      result = handler(event, context);

      //
      // Then return the response for the request id
      //
      // XXX Fix all of these calls to grab data from callbacks
      http = HTTP(awsLambdaRuntimeAPI ~ format(AWS_LAMBDA_RUNTIME_INVOCATION_RESPONSE, context.awsRequestId));
      http.postData = [result.toString];
      http.onReceiveStatusLine = (HTTP.StatusLine status){ 
        responseCode = status.code; 
        if (responseCode != 200) {
          throw new LambDException("Failure to post response AwsLambdaRuntimeAPI Invocation Response, reason: statusCode = " ~ to!string(responseCode));
        }
      };

      http.perform();
      return data.length; 
    };

    http.perform();

    
  }
  // Nothing to return
}

class LambDException : Exception {
  this(string msg) { super(msg); }
}