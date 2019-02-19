import std.stdio;
import std.json;

import lambd.layer;
import lambd.bootstrap;

void main()
{
	//
	// Initialize the context
	// Normally this is coming from the AWS Lambda infrastructure
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
	//
	// Create a fake event
	//
	JSONValue evt = parseJSON("{}");
	evt.object["count"] = JSONValue(20);
	// XXX TODO: Move this into some test harness code
	// For now this serves as an executable tester
	JSONValue result = handler(evt, myctx);

	// dump to string for visual inspection
	writeln("results:", result.toString());
}
