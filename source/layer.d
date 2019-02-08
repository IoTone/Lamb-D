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
  int memoryLimitInMB;
  string logGroupName;
  string logStreamName;
  string awsRequestId;
  Duration deadline;
  JSONValue identity;
  JSONValue clientContext;
}

static alias void function(int err, ref ubyte[] data) CallbackFunc;
static alias void function(JSONValue evt, LambdaContext ctx) HandlerFunc;
 


/**
 * runHandler
 *
 * General idea: Pass in a HandlerFunc and a Callback
 * Set the environment in the context
 * Run the handler
 * Post the results back to the lambda
 *
 */
JSONValue* runHandler(HandlerFunc handler, CallbackFunc cb) {
  LambdaContext context;

  /**
   * Set data from environment
   */
  if (environment[AWS_LAMBDA_FUNCTION_NAME] != null) {
    context.functionName = environment[AWS_LAMBDA_FUNCTION_NAME];
  }

  if (environment[AWS_LAMBDA_FUNCTION_VERSION] != null) {
    context.functionName = environment[AWS_LAMBDA_FUNCTION_VERSION];
  }

  if (environment[AWS_LAMBDA_FUNCTION_MEMORY_SIZE] != null) {
    context.functionName = environment[AWS_LAMBDA_FUNCTION_MEMORY_SIZE];
  }

  if (environment[AWS_LAMBDA_LOG_GROUP_NAME] != null) {
    context.functionName = environment[AWS_LAMBDA_LOG_GROUP_NAME];
  }

  if (environment[AWS_LAMBDA_LOG_STREAM_NAME] != null) {
    context.functionName = environment[AWS_LAMBDA_LOG_STREAM_NAME];
  }

  if (environment[AWS_LAMBDA_RUNTIME_API] != null) {
    context.functionName = environment[AWS_LAMBDA_RUNTIME_API];
  }


  return null;
}