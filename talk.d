import std.stdio;
import std.process;
import std.conv;
import std.array;
import std.range;
import std.algorithm;

/**
 * Update: https://forum.dlang.org/post/hbrfvliocdfhtbfeuypw@forum.dlang.org
 *
 * Connect the relative programs 'reverse' and 'check'
 * utilizing std.process.
 *
 * Utilizing the example explaination of the following command
 * translated for the two speific helper programs.
 *
 * https://stackoverflow.com/a/18342079
 *               command 2>&1 >/dev/null | grep 'something'
 *    -> ./reverse hello 2>&1 >/dev/null | ./check hello
 */
void main ()
{
   auto proc1Error = pipe ();
   auto reverse = spawnProcess (["./reverse", "hello"], stdin, stdout, proc1Error.writeEnd);

   auto proc2Output = pipe ();
   auto check = spawnProcess (["./check", "hello"], proc1Error.readEnd, proc2Output.writeEnd);

   auto os = appender!string;
   proc2Output.readEnd.byChunk (4096).copy (os);

   auto proc2Status = wait (check);
   auto proc1Status = wait (reverse);

   write (os[]);
}
