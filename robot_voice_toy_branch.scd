/*
Robot Voice Toy Branch for SuperCollider

How to use:
1. Evaluate this whole file.
2. Move the mouse anywhere on the screen:
   - Y changes pitch
   - X is unused for now
3. Use the volume slider if you want it louder.
4. Click the window, then press keys:
   - Vowels: a i u e o or 1 2 3 4 5
   - Hold consonants: m s y k t n h r w g z p b
   - 0 clears consonant
5. Sound plays by default.
6. Hold Space, or hold the MUTE pad, to go silent.
*/

(
s.waitForBoot({
	var win, label, consonantLabel, info, volumeLabel, volumeSlider, soundLabel, holdPad, synth;
	var vowelPresets, consonantPresets, applyVowel, applyConsonant, handleKey, setSoundGate;
	var currentAmp = 0.20, isSoundOn = true;

	vowelPresets = (
		a: [800, 1150, 2900, 0.040, "A"],
		i: [350, 1700, 2700, 0.030, "I"],
		u: [325, 700, 2530, 0.050, "U"],
		e: [500, 1750, 2450, 0.035, "E"],
		o: [450, 800, 2830, 0.045, "O"]
	);

	consonantPresets = (
		none: [0, "None"],
		m: [1, "M"],
		s: [2, "S"],
		y: [3, "Y"],
		k: [4, "K"],
		t: [5, "T"],
		n: [6, "N"],
		h: [7, "H"],
		r: [8, "R"],
		w: [9, "W"],
		g: [10, "G"],
		z: [11, "Z"],
		p: [12, "P"],
		b: [13, "B"]
	);

	SynthDef(\robotVoiceToyBranch, {
		|out = 0, f1 = 800, f2 = 1150, f3 = 2900, rq = 0.04,
		consonantIndex = 0, soundGate = 1, amp = 0.14|
		var pitch, growl, wobbleDepth, vibrato, base;
		var voiced, formants, slowWobble, vowelVoice;
		var mVoice, sVoice, yVoice, kVoice, tVoice, nVoice, hVoice, rVoice, wVoice;
		var gVoice, zVoice, pVoice, bVoice, consonantVoice, robot, gate;

		// Mouse UGens are server-side, so Y pitch still works even if GUI focus is weird.
		pitch = MouseY.kr(60, 700, 1).round(2);
		growl = 4.0;
		wobbleDepth = 0.10;

		vibrato = SinOsc.kr(growl, 0, pitch * 0.03);
		base = (pitch + vibrato).clip(50, 700);

		voiced = Mix([
			Saw.ar(base, 0.10),
			Pulse.ar(base * 1.01, 0.42, 0.06),
			SinOsc.ar(base * 2, 0, 0.025)
		]);

		formants = Mix([
			BPF.ar(voiced, f1, rq, 1.8),
			BPF.ar(voiced, f2, rq * 0.9, 1.3),
			BPF.ar(voiced, f3, rq * 0.8, 0.9)
		]);

		slowWobble = SinOsc.kr(growl * 0.35, 0, wobbleDepth, 1 - (wobbleDepth * 0.5));
		vowelVoice = formants * slowWobble;

		mVoice = LPF.ar(BPF.ar(voiced, 260, 0.06, 2.0) + SinOsc.ar(base * 0.5, 0, 0.04), 900);
		sVoice = HPF.ar(WhiteNoise.ar(0.12), 4200);
		yVoice = BPF.ar(voiced, 300, 0.05, 1.0) + BPF.ar(voiced, 2200, 0.04, 1.2);
		kVoice = BPF.ar(WhiteNoise.ar(0.14), 1700, 0.14);
		tVoice = BPF.ar(WhiteNoise.ar(0.13), 3300, 0.10);
		nVoice = LPF.ar(BPF.ar(voiced, 300, 0.05, 1.8), 1000);
		hVoice = HPF.ar(WhiteNoise.ar(0.07), 1600);
		rVoice = BPF.ar(voiced, 1250 + SinOsc.kr(18, 0, 260), 0.08, 1.4);
		wVoice = LPF.ar(Saw.ar(base * 0.5, 0.10), 650);
		gVoice = BPF.ar(voiced, 650, 0.08, 1.4) + (BPF.ar(WhiteNoise.ar(0.06), 1200, 0.14) * 0.4);
		zVoice = BPF.ar(WhiteNoise.ar(0.09), 3600, 0.10) + BPF.ar(voiced, 1800, 0.08, 0.8);
		pVoice = BPF.ar(WhiteNoise.ar(0.16), 900, 0.14);
		bVoice = BPF.ar(voiced, 500, 0.08, 1.4) + (BPF.ar(WhiteNoise.ar(0.05), 900, 0.16) * 0.35);

		consonantVoice = Select.ar(consonantIndex.clip(0, 13), [
			DC.ar(0), mVoice, sVoice, yVoice, kVoice, tVoice, nVoice,
			hVoice, rVoice, wVoice, gVoice, zVoice, pVoice, bVoice
		]);

		robot = vowelVoice + (consonantVoice * 0.65);
		robot = robot * SinOsc.ar(26, 0, 0.18, 0.82);
		robot = robot + WhiteNoise.ar(0.002);
		robot = HPF.ar(LeakDC.ar(tanh(robot * 2.3)), 90);

		gate = Lag.kr(soundGate, 0.02);
		Out.ar(out, (robot * amp * gate).dup);
	}).add;

	s.sync;

	synth = Synth(\robotVoiceToyBranch, [\amp, currentAmp, \soundGate, 1]);

	win = Window("Robot Voice Toy Branch", Rect(120, 120, 560, 280)).front;
	win.alwaysOnTop_(true);
	win.view.background_(Color.gray(0.14));
	win.view.canFocus_(true);
	win.view.focus;

	label = StaticText(win, Rect(20, 18, 230, 30))
		.string_("Robot vowel: A")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	consonantLabel = StaticText(win, Rect(270, 18, 260, 30))
		.string_("Consonant: None")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	info = StaticText(win, Rect(20, 54, 520, 92))
		.string_(
			"Y = pitch, X = unused for now\n" ++
			"Vowels: a i u e o or 1 2 3 4 5\n" ++
			"Hold consonants: m s y k t n h r w g z p b / 0 = none\n" ++
			"Sound plays by default / Hold Space or MUTE = silent"
		)
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 16));

	volumeLabel = StaticText(win, Rect(20, 154, 100, 22))
		.string_("Volume")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 14));

	volumeSlider = Slider(win, Rect(90, 156, 250, 20))
		.value_(0.78)
		.action_({ |slider|
			currentAmp = slider.value.linexp(0, 1, 0.02, 0.38);
			synth.set(\amp, currentAmp);
			win.view.focus;
		});

	soundLabel = StaticText(win, Rect(360, 154, 160, 22))
		.string_("Sound: on")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 14));

	setSoundGate = { |shouldSound|
		isSoundOn = shouldSound;
		if(isSoundOn) {
			synth.set(\soundGate, 1);
			soundLabel.string = "Sound: on";
		} {
			synth.set(\soundGate, 0);
			soundLabel.string = "Muted";
		};
	};

	applyVowel = { |key|
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
	};

	applyConsonant = { |key|
		var preset = consonantPresets[key];

		if(preset.notNil) {
			synth.set(\consonantIndex, preset[0]);
			consonantLabel.string = "Consonant: " ++ preset[1];
		};
	};

	handleKey = { |char|
		var key = char.asString.toLower;
		var vowelKey = key.asSymbol;

		if(key == " ") {
			setSoundGate.value(false);
		} {
			if(key == "1") { vowelKey = \a };
			if(key == "2") { vowelKey = \i };
			if(key == "3") { vowelKey = \u };
			if(key == "4") { vowelKey = \e };
			if(key == "5") { vowelKey = \o };

			applyVowel.value(vowelKey);
			applyConsonant.value(key.asSymbol);

			if(key == "0") {
				applyConsonant.value(\none);
			};
		};
	};

	Button(win, Rect(20, 192, 56, 32))
		.states_([["A", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\a); win.view.focus; });

	Button(win, Rect(86, 192, 56, 32))
		.states_([["I", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\i); win.view.focus; });

	Button(win, Rect(152, 192, 56, 32))
		.states_([["U", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\u); win.view.focus; });

	Button(win, Rect(218, 192, 56, 32))
		.states_([["E", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\e); win.view.focus; });

	Button(win, Rect(284, 192, 56, 32))
		.states_([["O", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\o); win.view.focus; });

	Button(win, Rect(360, 192, 42, 32))
		.states_([["M", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\m); win.view.focus; });

	Button(win, Rect(410, 192, 42, 32))
		.states_([["S", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\s); win.view.focus; });

	Button(win, Rect(460, 192, 42, 32))
		.states_([["Y", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\y); win.view.focus; });

	holdPad = UserView(win, Rect(20, 238, 520, 28));
	holdPad.background_(Color.gray(0.23));
	holdPad.drawFunc_({
		Pen.color = Color.white;
		Pen.stringCenteredIn("HOLD MUTE", holdPad.bounds.insetBy(0, 5), Font("Helvetica", 14));
	});
	holdPad.mouseDownAction_({
		setSoundGate.value(false);
		win.view.focus;
	});
	holdPad.mouseUpAction_({
		setSoundGate.value(true);
		win.view.focus;
	});

	win.view.mouseDownAction_({
		win.view.focus;
	});

	win.view.keyDownAction_({ |view, char|
		handleKey.value(char);
	});

	win.view.keyUpAction_({ |view, char|
		var key = char.asString.toLower.asSymbol;

		if(char.asString == " ") {
			setSoundGate.value(true);
		};

		if(consonantPresets[key].notNil) {
			applyConsonant.value(\none);
		};
	});

	win.onClose_({
		if(synth.notNil) { synth.free };
	});
});
)
