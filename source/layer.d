/**
#
#Copyright (c) 2019 IoTone, Inc. All rights reserved.
#
**/
module lambd.layer;

import std.json;
import std.string;
import core.time;
import std.stdio;
import std.conv;
import std.socket;
import std.regex;
import std.process;
import std.format;
import core.stdc.stdint;

// External libs
import arsd.http2;

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
  uint64_t deadline;            /* Max MS is 60 (sec) * 1000 (ms) * 15min = 900000 */
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

  writeln("å ø ∑ 😦 runHandler()");
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

  

  while (true) {
    // https://docs.aws.amazon.com/lambda/latest/dg/runtimes-api.html
    auto uriruntime_next = Uri("http://" ~ awsLambdaRuntimeAPI ~ AWS_LAMBDA_RUNTIME_INVOCATION_NEXT); // HTTP and not HTTPS?
    writeln("Invoking uri:" ~ uriruntime_next);
    auto req = new HttpRequest(uriruntime_next, HttpVerb.GET);
    req.perform();
    auto resp = req.waitForCompletion();

    if (resp.code != 200) {
      throw new LambDException("Failure to invoke AwsLambdaRuntimeAPI, reason: statusCode = " ~ resp.codeText ~ 
        "details: awsLambdaRuntimeAPI: " ~ awsLambdaRuntimeAPI ~ AWS_LAMBDA_RUNTIME_INVOCATION_NEXT ~ " calling function name: " ~ context.functionName);
    }

    // TODO: Handle exception possibility here
    writeln("resp.contentText:" ~ resp.contentText);

    if (resp.content.length > 0) {
      event = parseJSON(to!(const(char)[])(resp.content));
      writeln("JSONValue is " ~ event.type());
      writeln("event is:" ~ event.toPrettyString);
    } else {
      throw new LambDException("Failure to receive context back AwsLambdaRuntimeAPI, reason: statusCode = " ~ resp.contentText ~ 
        "details: awsLambdaRuntimeAPI: " ~ awsLambdaRuntimeAPI ~ AWS_LAMBDA_RUNTIME_INVOCATION_NEXT ~ " calling function name: " ~ context.functionName);
    }
    // TODO: Clean this env initilization into a loop that iterates over an array of the headers we need to load
    if ("Lambda-Runtime-Aws-Request-Id" in resp.headersHash) {
      context.awsRequestId = resp.headersHash["Lambda-Runtime-Aws-Request-Id"];
    }

    if ("Lambda-Runtime-Invoked-Function-Arn" in resp.headersHash) {
      context.invokedFunctionArn =  resp.headersHash["Lambda-Runtime-Invoked-Function-Arn"];
    }

    if ("Lambda-Runtime-Deadline-Ms" in resp.headersHash) {
      context.deadline = to!uint64_t(resp.headersHash["Lambda-Runtime-Deadline-Ms"]);
    }

    if ("Lambda-Runtime-Cognito-Identity" in resp.headersHash) {
      context.identity = parseJSON(resp.headersHash["Lambda-Runtime-Cognito-Identity"]);
    } else {
      context.identity.object = null;
    }

    if ("Lambda-Runtime-Client-Context" in resp.headersHash) {
      context.clientContext = parseJSON(resp.headersHash["Lambda-Runtime-Client-Context"]);
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
    auto uriruntime_resp = Uri("http://" ~ awsLambdaRuntimeAPI ~ format(AWS_LAMBDA_RUNTIME_INVOCATION_RESPONSE, context.awsRequestId));
    req = new HttpRequest(uriruntime_resp, HttpVerb.POST);
    req.perform();
    resp = req.waitForCompletion();

    if (resp.code != 202) {  // Should this be 202 or 200?
      throw new LambDException("Failure to post response AwsLambdaRuntimeAPI Invocation Response, reason: statusCode = " ~ resp.codeText);
    }

    return;
  }

}

class LambDException : Exception {
  this(string msg) { super(msg); }
}