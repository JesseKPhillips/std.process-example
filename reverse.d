import std.algorithm;
import std.range;
import std.stdio;

void main(string[] args) {
    if(args[1..$].empty) {
        string input;
        readf("%s", &input);
        writeln(input.retro.array);
        stderr.writeln(input);
    } else if(args[1..$].count > 1) {
        writeln(reverseJoin(args[1..$]).array);
        stderr.writeln(args[1..$].joiner(" ").array);
    } else {
        writeln(args[1].retro.array);
        stderr.writeln(args[1]);
    }
}

auto reverseJoin(string[] args) {
    return args.retro.joiner(" ");
} unittest {
    assert(reverseJoin(["one", "two"]).equal("two one"));
}
