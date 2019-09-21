import std.algorithm;
import std.exception;
import std.range;
import std.stdio;

void main(string[] args) {
    if(args[1..$].count > 1) {
        // Array validation
        enforce(stdin.byLineCopy.joiner.array
                .equal(args[1..$].joiner(" ")));
    } else {
        // String validation
        enforce(stdin.byLineCopy.joiner.array
                .equal(args[1]));
    }

    writeln("Success");
}
