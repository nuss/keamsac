// a definition for an enveloped mono channel synth
// will only live for duration of the envelope
(
SynthDef(\grain, { |out=0, freq=300, amp=0.3|
	OffsetOut.ar(out, Pulse.ar(freq) * EnvGen.kr(Env.perc, doneAction: 2) * 0.2)
}).add;
)

// boot the default server
s.boot;

// create some CVWidgets in CVCenter
(
~numChans = 5;
// first argument in the 'use' call is the name of the new widget
// second argument is a ControlSpec or something that compiles
// to a ControlSpec if 'asSpec' is called on it
// the ! in combination with ~numChans operator creates an array
// that gets converted into an appropriate ControlSpec internally.
// 'use' will return the internal CV that may directly be used in
// any Pattern
CVCenter.use(\durs, #[0.1, 1] ! ~numChans);
CVCenter.use(\freqs, \midfreq ! ~numChans);
)

// alternatively load an existing setup from disk
(
CVCenter.loadSetup(
	// assuming you're executing this from the original file in its original location...
	Document.current.dir +/+ "CVCenter_setups/simple_grain_setup",
	oscConnectToIP: false,
	activateCalibration: true
);
)

// a pattern holding 5 parallel playing streams,
// each producing an infinite stream of grains
// the 'split' method applied to a multi-dimensional
// CVWidget (CVWidgetMS) creates as many single-valued
// CVs as the widget has slots. Each CV will continously
// get updated to the value of the parent multi-valued
// CV at its corresponding slot
(
Pdef(\ppar,
	Ppar({ |i|
		Pbind(
			\instrument, \grain,
			// the key dur has a special meaning: it denotes
			// the time from the creation of one grain to the
			// creation of the next one
			\dur, CVCenter.cvWidgets[\durs].split[i],
			// the frequency of the grain
			\freq, CVCenter.cvWidgets[\freqs].split[i],
			// the Pattern will play to a not yet known private
			// bus within the emclosing Ndef later
			// we just want to make shure the channel offset is right
			\channelOffset, i,
		)
	}!~numChans)
)
)

// embed the Pattern in an Ndef
// make sure the Ndef is initialized to the right number of channels
Ndef(\ppar).mold(~numChans, \audio, \elastic);
Ndef(\ppar)[0] = Pdef(\ppar);

// mix down 5 channels to stereo
// Splay spreads the channels over the stereo panorama
// possibly use headphones to clearly identify the effect
Ndef(\stereo, { Splay.ar(\in.ar(0!~numChans), level: \amp.ar(0.7)) });
Ndef(\stereo) <<> Ndef(\ppar);
Ndef(\stereo).play;
// add Ndef(\stereo)'s controls to CVCenter
// even if you have already loaded the full setup
// adding an already existing CVWidget should not overwrite the existing one
Ndef(\stereo).cvcGui;

// setup a filter Ndef that allows filtering each of the 5channels individually
// again, make sure the Ndef gets initialized to the right number of channels
(
Ndef(\filter, {
	HPF.ar(
		\in.ar(0!~numChans),
		SinOsc.ar({|i| 2 + i}!~numChans) + 1 * \multFreq.kr(Array.geom(~numChans, 400, 2), 0.2)
	)
}).mold(~numChans, \audio, \elastic);
)

// define a fadetime for the Ndefs, allowing a smooth transition when updating
// the chain of Ndefs
[\ppar, \stereo, \filter].do({ |k| Ndef(k).fadeTime_(3) });

// add Ndef(\filter) in between Ndef(\ppar) and Ndef(\stereo)
Ndef(\stereo) <<> Ndef(\filter) <<> Ndef(\ppar);
// you may simply switch back to the old (unfiltered) chain
Ndef(\stereo) <<> Ndef(\ppar);

// define a suitable ControlSpec for the multFreq control in the filter Ndef
// adding it under the same name as the control will make CVCenter pick it up
// automatically when adding the Ndef's controls to CVCenter
Spec.add(\multFreq, #[20, 12000]);
Ndef(\filter).cvcGui

// clean up when done
Ndef.clear;
Pdef.clear;