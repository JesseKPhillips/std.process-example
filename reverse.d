import std.algorithm;
import std.range;
import std.stdio;

/**
 * write the original input to stderr
 * write the reverse of input to stdout
 */
void main(string[] args) {
    if(args[1..$].empty) {
        // Read from stdin to get original input
        // Reverse by code point
        string input;
        readf("%s", &input);
        writeln(input.retro.array);
        stderr.writeln(input);
    } else if(args[1..$].count > 1) {
        // Reverse the array
        writeln(reverseJoin(args[1..$]).array);
        stderr.writeln(args[1..$].joiner(" ").array);
    } else {
        // Reverse by code point
        writeln(args[1].retro.array);
        stderr.writeln(args[1]);
    }
}

/**
 * Returns a string which has had the array content
 * reversed and joined by spaces.
 */
auto reverseJoin(string[] args) {
    return args.retro.joiner(" ");
} unittest {
    assert(reverseJoin(["one", "two"]).equal("two one"));
}
