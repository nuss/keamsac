(
// set freqs, ringtimes, impulsefreqs from outside later,
// \freqs.kr(), \ringtimes.kr(), \impulsefreqs.kr() denote settable
// parameters in the synth
SynthDef('help-dynKlank', {
    var freqs, ringtimes, signal, impulsefreqs;
    freqs = \freqs.kr([800, 1071, 1153, 1723, 1398]);
    ringtimes = \ringtimes.kr([1, 1, 1, 1, 1]);
	impulsefreqs = \impulsefreqs.kr(2!5);
    signal = DynKlank.ar(`[freqs, nil, ringtimes ], Impulse.ar(impulsefreqs, 0, 0.1));
    Out.ar(0, Splay.ar(signal));
}).add;
)

// instantiate a new Synth
a = Synth('help-dynKlank');
// set impulsefreqs to random values between 1 and 5
a.set(\impulsefreqs, {1.rrand(5)}!5);

// setup parameters to listen to OSC messages from VideOSC
// specs determining the ranges to which incoming values
// shall be mapped
Spec.add(\freqs, #[400, 2000, \exp].asSpec);
Spec.add(\ringtimes, #[1, 10].asSpec);
Spec.add(\impulsefreqs, #[1, 5].asSpec);

// set up a NetAddr, determining where feedback will be sent
// must of course be adjusted to fit to your device
n = NetAddr("192.168.1.2", 32000)

// in order to work you need at least 5 distinct pixels
// and normalization in VideOSC must be activated
(
5.do{ |i|
	OSCdef(\freq ++ i, { |msg|
		var val = \freqs.asSpec.map(msg[1]);

		// set oscillator at index i in Synth a
		a.seti(\freqs, i, val);
		// send feedback to VideOSC
		// displayed within the pixel that,
		// sent the incoming value
		n.sendMsg('/vosc/blue' ++ (i+1), "freqs["++i++"]");
	},
	// OSC command pattern, pixels start at 1, not 0: /vosc/blue1 to /vosc/blueN
	'/vosc/blue' ++ (i+1));

	OSCdef(\ringtime ++ i, { |msg|
		var val = \ringtimes.asSpec.map(msg[1]);
		a.seti(\ringtimes, i, val);
		n.sendMsg('/vosc/green' ++ (i+1), "ringtimes["++i++"]");
	},
	'/vosc/green' ++ (i+1));

	OSCdef(\impulsefreq ++ i, { |msg|
		var val = \impulsefreqs.asSpec.map(msg[1]);
		a.seti(\impulsefreqs, i, val);
		n.sendMsg('/vosc/red' ++ (i+1), "ringtimes["++i++"]");
	},
	'/vosc/red' ++ (i+1));
}
)

// clean up when done
OSCdef.freeAll;
a.free;
