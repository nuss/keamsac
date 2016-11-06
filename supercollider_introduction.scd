/* a quick introduction into working with SuperCollider */

/*
SuperCollider really consists of two different processes:
- sclang: the inbuilt programming language
- scsynth, respectively more recently, supernova: the sound engine, often referred
as the *server*.
All sound-generating structures, arithmetic operations and commands
are defined in the language and then communicated to the server (scsynth or
supernova) via OSC. The server, in contrary to sclang, is completely language agnostic
and only understands OSC commands.
Apart from the above described SuperCollider comes with a Qt-based IDE that allows code-
editing and execution (other editors like Sublime, Atom, VIM, Emacs, etc. are possible
as well)
*/

// code execution
// place the cursor anywhere on the following line and hit shift + enter -> you should
// see "Hello world" being posted to the console (the "Post window")
"Hello world".postln;
// a simple calculation
(1 + 1).postln; // 2

/*
while shift + enter executes only the current line it is possible to execute several
lines (a block of code) by hitting cmd + enter (mac) or ctrl + enter (win, linux)
for convenience a block of code can be confined by a pair of round brackets, causing
the interpreter to only executed inbetween the brackets.
*/

// place the cursor anywhere within the following block of code
// when executing several lines of code each line must end with a semicolon
(
// some variable declarations
// the varaibales will only be valid within the executed block of code
var one, two;
// sclang does not respect operator precedence!!
one = 45 / 37 + 56 * 0.34;
two = one ** 3;
trunc(one * two, 0.01); // result -> posted to the console
)

// a block of code like the previous one may be defined in a function which
// makes it reusable whenever needed
// a variable prefixed with a ~ denotes an environment variable
// environment variables are valid glaobally
// functions are denoted by a pair of {} brackets
(
~func = {
	// a function may be defined with arguments,
	// variables that can be passed in when the function is called
	// arguments may have default values
	arg a = 37, b = 3;
	var one, two;
	one = 45 / a + 56 * 0.34;
	two = one ** b;
	// functions do not have a dedicated return value
	// the last expression in the function will be returned as result
	trunc(one * two, 0.01);
};
)

// call the function without arguments
~func.value;
// with some values
~func.value(42, 5);

/*
functions also provide a quick way to generate sound.
when used to make sound a number of steps happen behind the scenes:
- a temporary SynthDef, a binary representations of a sound producing structure, will be compiled
- a Synth will be instantiated from the previously compiled SynthDef
the process of compiling the SynthDef and instantiating the Synth is triggered by calling 'play' on
the function
*/

// first: boot the server
// here s is a shortcut for Sever.default
s.boot;

// small letters a-z are interpreter variables that can be used anywhere
// interpreter variables are global
// a simple mono sine wave playing at 440 hz
a = { SinOsc.ar * 0.2 }.play;

// stop sound again
a.free;

// stereo may simple be achieved by using arrays in function arguments
a = { SinOsc.ar([234, 236], mul: 0.2) }.play;
// release with a small decay
a.release;

// using arguments for the function
// |freq=#[234, 236]| is equivalent to arg freq=#[234, 236];
// a # in front of an array denotes a literal array
// as such the array may not contain any computed values (e.g. 2 * 3)
a = { |freq=#[234, 236]| SinOsc.ar(freq, mul: 0.2) }.play;

// set the frequencies
a.set(\freq, [256, 261]);

// ... and release
a.release;

// note: hitting cmd/ctrl + . will free any currently playing synth

/*
rather than playing functions it is recommended to create SynthDefs explicitely
as temporary SynthDefs remain in memory and pile up over time. SynthDefs are the basic structure within every sound creation in SC. There are various other ways to define sound generating structures (e.g. NodeProxy, Ndef, ProxySpace, Instr) but behind the scenes they will always create a SynthDef. Writing a SynthDef is more difficult than writing a function.
*/
(
SynthDef(\simpleSine, { |out=0, freq=#[234, 236], amp=0.2|
	var sig = SinOsc.ar(freq);
	// we need to explicitely declare an output bus
	Out.ar(out, sig * amp);
}).add; // temporarlily add the SynthDef to the SynthDescLIb
)

a = Synth(\simpleSine);
a.set(\freq, [256, 261]);
a.free;

// the same thing, using an Ndef
(
Ndef(\simpleSine, { |freq=#[234, 236], amp=0.2|
	// differently to a SynthDef we don't declare an outbus
	// routing to audio outputs is handled by the Ndef itself
	SinOsc.ar(freq) * amp;
}).mold(2, \audio);
)

Ndef(\simpleSine).play

// in contrary to a SynthDef an Ndef can be rewritten while the Ndef is playing
// the internal Synth will be stopped (or faded out) and be replaced by a new one
Ndef(\simpleSine).fadeTime_(15);
Ndef(\simpleSine, { |freq=#[145, 167], amp=0.2| Pulse.ar(freq) * amp });

// fade out and stop
Ndef(\simpleSine).clear(10);