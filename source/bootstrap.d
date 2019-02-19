module lambd.bootstrap;

import std.stdio;
import std.json;
import std.conv;
import lambd.layer;

// Inspired by some code I wrote for IoToneKit, see iotksvc.d and ultraviolet middleware.d
// static alias JSONValue function(JSONValue evt, LambdaContext ctx) HandlerFunc;
 HandlerFunc handler = (JSONValue evt, LambdaContext ctx) {
    JSONValue result;
    // Implement your lambda here!
    // Some ideas:
    // - add up some numbers
    // - do something awesome in phobos
    // - do something like hello world
    // - just get it working
    // - some cool crypto stuff
    // - break the Internet

    //
    // YOU SHOULD DELETE EVERYTHING BELOW HERE AND REPLACE WITH YOUR OWN LAMBDA
    //
    // For this quick example, we will simply generate UUIDs
    // event should contain:
    // - (optional) inputdata: [] array, with input data strings
    // - (optional) count: the number of uuids to generate, default is 1 if no inputdata and no count is provided
    //
    // Returns a json object
    // results: [] array of UUIDs as strings
    import std.uuid;
    int uuidcount = 1;
    JSONValue* uuidinputdata;
    if (const(JSONValue)* inputdata= "inputdata" in evt) {
        // TODO: Implement
    } else if (const(JSONValue)* count = "count" in evt) {
        uuidcount = to!int(count.integer);
        writeln("Generate ", uuidcount, " UUIDs");
    } else {
        // assume count = 1;
        writeln("Performing default UUID gen count = 1");
    }

    // UUID[] ids;

    result["result"] = parseJSON("[]");
    for (int i = 0; i < uuidcount; i++) {
        // ids ~= randomUUID();
        result["result"].array ~= JSONValue(randomUUID.toString());
    }

    // TODO: Figure out how to deal with errors and how to pass those back properly to the LambdaContext


     return result;
 };
