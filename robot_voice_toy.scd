/*
Robot Voice Toy for SuperCollider

How to use:
1. Evaluate this whole file.
2. A window will open. Click inside the window to focus it.
3. Move the mouse:
   - X changes pitch
   - Y changes the growl / pulse speed
4. Press keys: a i u e o
5. Close the window to stop the sound.
*/

(
s.waitForBoot({
	var win, label, info, synth;
	var vowelPresets;

	vowelPresets = (
		a: [800, 1150, 2900, 0.018, "A"],
		i: [350, 1700, 2700, 0.010, "I"],
		u: [325, 700, 2530, 0.022, "U"],
		e: [500, 1750, 2450, 0.015, "E"],
		o: [450, 800, 2830, 0.020, "O"]
	);

	SynthDef(\robotVoiceToy, {
		|out = 0, pitch = 110, growl = 3, gateRate = 7,
		f1 = 800, f2 = 1150, f3 = 2900, rq = 0.02, amp = 0.18|
		var base, vibrato, voiced, formants, chatter, robot, env;

		vibrato = SinOsc.kr(growl, 0, pitch * 0.03);
		base = (pitch + vibrato).clip(50, 400);

		voiced = Mix([
			Saw.ar(base, 0.12),
			Pulse.ar(base * 1.01, 0.42, 0.08),
			SinOsc.ar(base * 2, 0, 0.03)
		]);

		formants = Mix([
			BPF.ar(voiced, f1, rq, 1.2),
			BPF.ar(voiced, f2, rq * 0.8, 1.0),
			BPF.ar(voiced, f3, rq * 0.6, 0.7)
		]);

		chatter = LFPulse.kr(gateRate, 0, 0.42).lag(0.01);
		robot = formants * chatter;
		robot = robot * SinOsc.ar(26, 0, 0.25, 0.75);
		robot = robot + (WhiteNoise.ar(0.012) * chatter);
		robot = LeakDC.ar(tanh(robot * 4));
		robot = HPF.ar(robot, 90);

		env = EnvGen.kr(Env.asr(0.02, 1, 0.2), 1);
		Out.ar(out, (robot * env * amp).dup);
	}).add;

	s.sync;

	synth = Synth(\robotVoiceToy, [
		\pitch, 110,
		\growl, 3,
		\gateRate, 7
	]);

	win = Window("Robot Voice Toy", Rect(120, 120, 520, 220)).front;
	win.alwaysOnTop_(true);
	win.view.background_(Color.gray(0.14));

	label = StaticText(win, Rect(20, 18, 480, 28))
		.string_("Robot vowel: A")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	info = StaticText(win, Rect(20, 60, 480, 120))
		.string_(
			"Move mouse in the window:\n" ++
			"X = pitch, Y = growl speed\n" ++
			"Press keys: a i u e o\n" ++
			"Close the window to stop"
		)
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 16));

	win.view.keyDownAction_({ |view, char|
		var key = char.asString.toLower.asSymbol;
		var preset = vowelPresets[key];

		if(preset.notNil) {
			synth.set(
				\f1, preset[0],
				\f2, preset[1],
				\f3, preset[2],
				\rq, preset[3]
			);
			label.string = "Robot vowel: " ++ preset[4];
		};
	});

	AppClock.sched(0.0, {
		if(win.isClosed or: { synth.isPlaying.not }) {
			nil
		} {
			var mousePos = win.view.mousePosition;
			var xNorm = (mousePos.x / win.view.bounds.width).clip(0, 1);
			var yNorm = (1 - (mousePos.y / win.view.bounds.height)).clip(0, 1);
			var pitch = xNorm.linexp(0, 1, 70, 280).round(2);
			var growl = yNorm.linlin(0, 1, 1.2, 12.0);
			var gateRate = yNorm.linlin(0, 1, 3.0, 16.0);

			synth.set(
				\pitch, pitch,
				\growl, growl,
				\gateRate, gateRate
			);

			0.03
		}
	});

	win.onClose_({
		if(synth.isPlaying) { synth.free };
	});
});
)
