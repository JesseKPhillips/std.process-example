# std.process-example
Provides an example of using dlang's std.process for piping std in, out, and err.

# Background

After writing about using [`execute`](https://dev.to/jessekphillips/execute-a-program-1lh9-temp-slug-3754688) to run a process, I wanted to dive further into manipulating processes. I didn't know exactly where to start until my searchs lead me to this question.

[How to pipe stderr, and not stdout?](https://stackoverflow.com/a/18342079)

The answer I linked does a nice job of explaining the syntax for the bash piping arguments.

```command 2>&1 >/dev/null | grep 'something'```

Send stderr to stdout, send original stdout to /dev/null then connect stdout to stdin of grep. It is a nice concise syntax, like regex it is hard to write and hard to read.

I wanted to recreate this in D, which gave me some challenges as I needed to make sure all operations completed within their own thread (input and output buffers can fill up and prevent further processing).

I've placed the full source on github [std.process-example](https://github.com/JesseKPhillips/std.process-example/blob/master/talk.d). There are two supporting programs as I've chosen to swap out grep.

```bash
        command 2>&1 >/dev/null | grep 'something'
./reverse hello 2>&1 >/dev/null | ./check hello
```

`reverse` will output its arguments in reverse to stdout, The original will be sent to stderr. And `check` will use its arguments to verify what it gets to stdin. Since the objective is to send stderr to check, we should expect hello to come through in the original order.

'talk' is the program replacing all of the bash redirections.

# Start Process

```dlang
import std.process;

    // Start process execution and provide redirection pipes
    auto reverse = pipeProcess(["./reverse", "hello"]
                               , Redirect.stdout | Redirect.stderr);
    auto check   = pipeProcess(["./check", "hello"]
                               , Redirect.all);
```

This starts execution of both processes, but neither is talking to the other. I've chosen to redirect all of `check`'s endpoints, this is not strictly necessary and add some additional complications, but is good to see all implications of managing your output.

# Connect the Process

```dlang
import std.range;
import std.stdio;
import std.parallelism;

   auto pipeError() {
        reverse.stderr.byChunk(2048)
            .copy(check.stdin
              .lockingBinaryWriter());
   }

   auto pipeOutput() {
        reverse.stdout.byChunk(2048)
            .copy(File("/dev/null", "w")
              .lockingBinaryWriter());
    }

    // Execute forwarding on own threads
    // This prevents filling the output buffers
    auto t1 = task(&pipeError);
    auto t2 = task(&pipeOutput);
    t1.executeInNewThread;
    t2.executeInNewThread;
```

Here I've chosen to process the output `byChunk`. This provides more control over the frequency of data pushed, maybe using the same size a the output buffer would be optimal.

Two helper methods are created, they create a clouser around the local variables allowing for access to `reverse` and `check`. We then execute these methods within their own thread.

The operating system provides buffering for both input and output. When these buffers are full, the system will pause execution of a process waiting for the buffer to be cleared. Since both stderr and stdout are being redirected the code needs to continually process each pipe.

# Wait for Reverse to Complete

```dlang
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
    // Close the input pipe for the dependant process 'check'.
    // https://stackoverflow.com/questions/47486128/why-does-io-pipe-continue-to-block-even-when-eof-is-reached
    check.stdin.close();
```

The first part is hooking up processes to handle `check`'s pipes. This is an important first step before waiting on reverse because, again, stdin could have its buffer fill up preventing the first process, `reverse`, to run to completion.

The next part is waiting on the process and piping threads to complete for `reverse`. Once they have finished it is important to close out stdin for the processing we are piping to. This sends the EOF to the `check` process. Consider also that by having to close the pipe, the door is open to send additional data to check.stdin including piping an additional process.

# Wait for Check Process

```dlang
    wait(check.pid);
    t3.yieldForce;
    t4.yieldForce;
```

The last piece is to wait for the other side of the pipe to complete. We need to wait for the threads to complete data transfer even after the process itself has completed.
