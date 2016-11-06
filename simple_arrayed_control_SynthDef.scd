// the number of oscillators in the oscillator bank
k = 10;

// define the SynthDef
(
SynthDef(\oscBank, {
	// the variable 'bank' holds n simple sinus oscillators, by default
	// automatically multichannel-expanded to n channels
	// 'stereo' spreads the output of 'bank' accross the stereo field
	var bank = SinOsc.ar(\sinFreq.kr(200!k)),
		stereo = Splay.ar(bank, level: 0.2);
	// route 'stereo' to bus 0
	// 2 channels (as derived from 'stereo')
	Out.ar(0, stereo);
}).add;
)

// instantiate a new Synth from the previously defined SynthDef after the server has booted
(
s.waitForBoot {
	a = Synth(\oscBank);
}
)

// set random frequencies in the oscillator bank
a.setn(\sinFreq, Array.fill(k, { 100.rrand(2000) }));

// the IP address on which VideOSC is running
// adjust to your device's IP address
n = NetAddr("192.168.1.4", 32000);

// see if any OSC messages are coming in ( warning: takes a lot of CPU!)
OSCFunc.trace(true);
// switch off OSC racing again
OSCFunc.trace(false);

// create a custom ControlSpec, describing lower and upper frequency
// constraints and curve
// for convenience it's named like the control name in the SynthDef, allowing
// an automatic detection of the right spec when used with CVCenter
Spec.add(\sinFreq, #[10, 1000, \exp]);

// set the frequency of each oscillator within the oscillator bank in Synth a
// from within an OSCdef, each listening to a different messages coming one pixel
// the following 'do' loop automatically creates k different OSCdefs
// and provides a counter variable i
// NOTE: to make this work the output must be *normalized* in VideOSC
// preferences -> Resolution Settings -> normalize output (0.0-1.0)
(
k.do{ |i|
	OSCdef(\freq ++ i, { |msg|
		var val = \sinFreq.asSpec.map(msg[1]);

		// set oscillator at index i in Synth a
		a.seti(\sinFreq, i, val);
		// send feedback to VideOSC
		// displayed within the pixel that,
		// sent the incoming value
		n.sendMsg('/vosc/blue' ++ (i+1), "freq["++i++"]");
	},
	// OSC command pattern, pixels start at 1, not 0: /vosc/blue1 to /vosc/blueN
	'/vosc/blue' ++ (i+1))
}
)

// clean up
OSCdef.freeAll;
n.disconnect;

// take a shortcut: use CVCenter
a.cvcGui;

// setup OSC listening
(1..10).do{ |i| CVCenter.cvWidgets[\sinFreq].oscConnect(name: "/vosc/blue" ++ i, oscMsgIndex: 1, slot: i-1) };

// clean up
(1..10).do{ |i| CVCenter.cvWidgets[\sinFreq].oscDisconnect(i-1) };
a.free;
CVCenter.removeAll;