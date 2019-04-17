import std.stdio;
import std.json;

import lambd.layer;
import lambd.bootstrap;

void main()
{
	// handler is defined in bootstrap
	runHandler(handler);
}
