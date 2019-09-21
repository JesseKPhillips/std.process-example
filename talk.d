import std.algorithm;
import std.parallelism;
import std.process;
import std.range;
import std.stdio;

void main() {
    // https://stackoverflow.com/a/18342079
    //         command 2>&1 >/dev/null | grep 'something'
    // ./reverse hello 2>&1 >/dev/null | ./check hello

    auto reverse = pipeProcess(["./reverse", "hello"]
                               , Redirect.stdout | Redirect.stderr);
    auto check   = pipeProcess(["./check", "hello"]
                               , Redirect.all);

    auto pipeError() {
        reverse.stderr.byChunk(2048)
            .copy(check.stdin.lockingBinaryWriter());
    }

    auto pipeOutput() {
        reverse.stdout.byChunk(2048)
            .copy(File("/dev/null", "w").lockingBinaryWriter());
    }

    // Execute forwarding on own threads
    // This prevents filling the output buffers
    auto t1 = task(&pipeError);
    auto t2 = task(&pipeOutput);
    t1.executeInNewThread;
    t2.executeInNewThread;

    // Store output into memory.
    auto errors = appender!string;
    auto t3 = task(() => check.stderr.byChunk(2048).copy(errors));
    t3.executeInNewThread;
    auto output = appender!string;
    auto t4 = task(() => check.stdout.byChunk(2048).copy(output));
    t4.executeInNewThread;

    wait(reverse.pid);
    t1.yieldForce;
    t2.yieldForce;
    // reverse will no longer be writing data
    // Close the pipe.
    check.stdin.close();

    wait(check.pid);
    t3.yieldForce;
    t4.yieldForce;

    writeln("errors: ", errors[]);
    writeln("output: ", output[]);
}
