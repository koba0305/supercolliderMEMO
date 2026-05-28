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
   - Hold consonants: k s t n h m y r w g z b p d
   - Sound only plays while a mapped key is held.
5. Press Record / Stop rec to save a WAV into ./recordings.
*/

(
s.waitForBoot({
	var win, label, consonantLabel, info, volumeLabel, volumeSlider, soundLabel, recordButton, recordLabel, synth;
	var vowelPresets, consonantPresets, normalizeVowelKey, updateVowelGates, applyVowel, applyConsonant, handleKey, setSoundGate;
	var startRecording, stopRecording, toggleRecording;
	var currentAmp = 0.20, isSoundOn = false, isRecording = false;
	var activeVowels, activeConsonant = \none;
	var recordDir, recordingPath;

	vowelPresets = (
		a: [800, 1150, 2900, 0.040, "A"],
		i: [350, 1700, 2700, 0.030, "I"],
		u: [325, 700, 2530, 0.050, "U"],
		e: [500, 1750, 2450, 0.035, "E"],
		o: [450, 800, 2830, 0.045, "O"]
	);

	consonantPresets = (
		none: [0, "None"],
		k: [1, "K"],
		s: [2, "S"],
		t: [3, "T"],
		n: [4, "N"],
		h: [5, "H"],
		m: [6, "M"],
		y: [7, "Y"],
		r: [8, "R"],
		w: [9, "W"],
		g: [10, "G"],
		z: [11, "Z"],
		b: [12, "B"],
		p: [13, "P"],
		d: [14, "D"]
	);

	SynthDef(\robotVoiceToyBranch, {
		|out = 0, aGate = 0, iGate = 0, uGate = 0, eGate = 0, oGate = 0,
		consonantIndex = 0, soundGate = 0, amp = 0.14|
		var pitch, growl, wobbleDepth, vibrato, base;
		var voiced, slowWobble, vowelVoice, vowelCount;
		var aVoice, iVoice, uVoice, eVoice, oVoice;
		var mVoice, sVoice, yVoice, kVoice, tVoice, nVoice, hVoice, rVoice, wVoice;
		var gVoice, zVoice, bVoice, pVoice, dVoice, consonantVoice, robot, gate;

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

		slowWobble = SinOsc.kr(growl * 0.35, 0, wobbleDepth, 1 - (wobbleDepth * 0.5));
		aVoice = Mix([BPF.ar(voiced, 800, 0.040, 1.8), BPF.ar(voiced, 1150, 0.036, 1.3), BPF.ar(voiced, 2900, 0.032, 0.9)]) * Lag.kr(aGate, 0.012);
		iVoice = Mix([BPF.ar(voiced, 350, 0.030, 1.8), BPF.ar(voiced, 1700, 0.027, 1.3), BPF.ar(voiced, 2700, 0.024, 0.9)]) * Lag.kr(iGate, 0.012);
		uVoice = Mix([BPF.ar(voiced, 325, 0.050, 1.8), BPF.ar(voiced, 700, 0.045, 1.3), BPF.ar(voiced, 2530, 0.040, 0.9)]) * Lag.kr(uGate, 0.012);
		eVoice = Mix([BPF.ar(voiced, 500, 0.035, 1.8), BPF.ar(voiced, 1750, 0.0315, 1.3), BPF.ar(voiced, 2450, 0.028, 0.9)]) * Lag.kr(eGate, 0.012);
		oVoice = Mix([BPF.ar(voiced, 450, 0.045, 1.8), BPF.ar(voiced, 800, 0.0405, 1.3), BPF.ar(voiced, 2830, 0.036, 0.9)]) * Lag.kr(oGate, 0.012);
		vowelCount = (aGate + iGate + uGate + eGate + oGate).max(1);
		vowelVoice = ((aVoice + iVoice + uVoice + eVoice + oVoice) / vowelCount.sqrt) * slowWobble;

		mVoice = LPF.ar(BPF.ar(voiced, 260, 0.06, 2.0) + SinOsc.ar(base * 0.5, 0, 0.04), 900);
		sVoice = BPF.ar(WhiteNoise.ar(0.035), 5200, 0.18);
		yVoice = BPF.ar(voiced, 300, 0.05, 1.0) + BPF.ar(voiced, 2200, 0.04, 1.2);
		kVoice = BPF.ar(WhiteNoise.ar(0.055), 1700, 0.14) + (BPF.ar(voiced, 900, 0.10, 0.5));
		tVoice = BPF.ar(WhiteNoise.ar(0.045), 3300, 0.10) + (BPF.ar(voiced, 1400, 0.08, 0.35));
		nVoice = LPF.ar(BPF.ar(voiced, 300, 0.05, 1.8), 1000);
		hVoice = HPF.ar(WhiteNoise.ar(0.03), 1800) + (BPF.ar(voiced, 1200, 0.08, 0.25));
		rVoice = BPF.ar(voiced, 1250 + SinOsc.kr(18, 0, 260), 0.08, 1.4);
		wVoice = LPF.ar(Saw.ar(base * 0.5, 0.10), 650);
		gVoice = BPF.ar(voiced, 650, 0.08, 1.4) + (BPF.ar(WhiteNoise.ar(0.025), 1200, 0.14) * 0.25);
		zVoice = BPF.ar(WhiteNoise.ar(0.035), 3600, 0.10) + BPF.ar(voiced, 1800, 0.08, 0.8);
		bVoice = BPF.ar(voiced, 500, 0.08, 1.4) + (BPF.ar(WhiteNoise.ar(0.02), 900, 0.16) * 0.25);
		pVoice = BPF.ar(WhiteNoise.ar(0.055), 900, 0.14) + (BPF.ar(voiced, 520, 0.10, 0.4));
		dVoice = BPF.ar(voiced, 760, 0.08, 1.2) + (BPF.ar(WhiteNoise.ar(0.035), 2600, 0.12) * 0.35);

		consonantVoice = Select.ar(consonantIndex.clip(0, 14), [
			DC.ar(0), kVoice, sVoice, tVoice, nVoice, hVoice, mVoice,
			yVoice, rVoice, wVoice, gVoice, zVoice, bVoice, pVoice, dVoice
		]);

		robot = vowelVoice + (consonantVoice * 0.45);
		robot = robot * SinOsc.ar(26, 0, 0.18, 0.82);
		robot = robot + WhiteNoise.ar(0.002);
		robot = HPF.ar(LeakDC.ar(tanh(robot * 2.3)), 90);

		gate = Lag.kr(soundGate, 0.02);
		Out.ar(out, (robot * amp * gate).dup);
	}).add;

	s.sync;

	synth = Synth(\robotVoiceToyBranch, [\amp, currentAmp, \soundGate, 0]);
	activeVowels = IdentitySet.new;
	recordDir = (thisProcess.nowExecutingPath.notNil).if({
		thisProcess.nowExecutingPath.dirname +/+ "recordings"
	}, {
		Platform.recordingsDir
	});
	recordDir.mkdir;

	win = Window("Robot Voice Toy Branch", Rect(120, 120, 560, 322)).front;
	win.alwaysOnTop_(true);
	win.view.background_(Color.gray(0.14));
	win.view.canFocus_(true);
	win.view.focus;

	consonantLabel = StaticText(win, Rect(20, 18, 250, 30))
		.string_("Consonant: None")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	label = StaticText(win, Rect(290, 18, 230, 30))
		.string_("Robot vowel: A")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	info = StaticText(win, Rect(20, 54, 520, 92))
		.string_(
				"Y = pitch, X = unused for now\n" ++
				"Vowels: a i u e o or 1 2 3 4 5\n" ++
				"Hold keys: k s t n h m y r w g z b p d\n" ++
				"Sound only while a mapped key is held / Record = WAV"
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
		.string_("Sound: off")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 14));

	recordButton = Button(win, Rect(20, 238, 120, 32))
		.states_([
			["Record", Color.white, Color.gray(0.28)],
			["Stop rec", Color.white, Color.red(0.55)]
		]);

	recordLabel = StaticText(win, Rect(156, 243, 380, 22))
		.string_("Recording: off")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 13));

	setSoundGate = { |shouldSound|
		isSoundOn = shouldSound;
		if(isSoundOn) {
			synth.set(\soundGate, 1);
			soundLabel.string = "Sound: on";
		} {
			synth.set(\soundGate, 0);
			soundLabel.string = "Sound: off";
		};
	};

	startRecording = {
		if(isRecording.not) {
			recordingPath = recordDir +/+ ("robot_voice_toy_branch_" ++ Date.getDate.stamp ++ ".wav");
			s.prepareForRecord(recordingPath, numChannels: 2);
			s.record;
			isRecording = true;
			recordButton.value = 1;
			recordLabel.string = "Recording: " ++ recordingPath;
		};
	};

	stopRecording = {
		if(isRecording) {
			s.stopRecording;
			isRecording = false;
			recordButton.value = 0;
			recordLabel.string = "Saved: " ++ recordingPath;
		};
	};

	toggleRecording = {
		if(isRecording) {
			stopRecording.value;
		} {
			startRecording.value;
		};
		win.view.focus;
	};

	recordButton.action_({ toggleRecording.value; });

	normalizeVowelKey = { |key|
		var vowelKey = key.asString.toLower;
		if(vowelKey == "1") { vowelKey = "a" };
		if(vowelKey == "2") { vowelKey = "i" };
		if(vowelKey == "3") { vowelKey = "u" };
		if(vowelKey == "4") { vowelKey = "e" };
		if(vowelKey == "5") { vowelKey = "o" };
		vowelKey.asSymbol;
	};

	updateVowelGates = {
		var text = "", sep = "";
		[\a, \i, \u, \e, \o].do({ |key|
			var isActive = activeVowels.includes(key);
			synth.set((key.asString ++ "Gate").asSymbol, isActive.if({ 1 }, { 0 }));
			if(isActive) {
				text = text ++ sep ++ vowelPresets[key][4];
				sep = "+";
			};
		});
		if(text == "") {
			label.string = "Robot vowel: None";
		} {
			label.string = "Robot vowel: " ++ text;
		};
		setSoundGate.value((activeVowels.size > 0) or: { activeConsonant != \none });
	};

	applyVowel = { |key|
		var preset = vowelPresets[key];

		if(preset.notNil) {
			activeVowels.add(key);
			updateVowelGates.value;
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
		var vowelKey = normalizeVowelKey.value(key);
		var isMapped = false;

		if(key == "0") {
			applyConsonant.value(\none);
			setSoundGate.value(false);
		} {
			if(vowelPresets[vowelKey].notNil) {
				activeVowels.add(vowelKey);
				updateVowelGates.value;
				isMapped = true;
			} {
				if(consonantPresets[key.asSymbol].notNil) {
					activeConsonant = key.asSymbol;
					applyConsonant.value(key.asSymbol);
					isMapped = true;
				};
			};

			if(isMapped) {
				setSoundGate.value(true);
			};
		};
	};

	Button(win, Rect(20, 192, 42, 32))
		.states_([["M", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\m); win.view.focus; });

	Button(win, Rect(70, 192, 42, 32))
		.states_([["S", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\s); win.view.focus; });

	Button(win, Rect(120, 192, 42, 32))
		.states_([["Y", Color.white, Color.gray(0.22)]])
		.action_({ applyConsonant.value(\y); win.view.focus; });

	Button(win, Rect(220, 192, 56, 32))
		.states_([["A", Color.white, Color.gray(0.28)]])
		.action_({ label.string = "Hold key: A"; win.view.focus; });

	Button(win, Rect(286, 192, 56, 32))
		.states_([["I", Color.white, Color.gray(0.28)]])
		.action_({ label.string = "Hold key: I"; win.view.focus; });

	Button(win, Rect(352, 192, 56, 32))
		.states_([["U", Color.white, Color.gray(0.28)]])
		.action_({ label.string = "Hold key: U"; win.view.focus; });

	Button(win, Rect(418, 192, 56, 32))
		.states_([["E", Color.white, Color.gray(0.28)]])
		.action_({ label.string = "Hold key: E"; win.view.focus; });

	Button(win, Rect(484, 192, 56, 32))
		.states_([["O", Color.white, Color.gray(0.28)]])
		.action_({ label.string = "Hold key: O"; win.view.focus; });

	win.view.mouseDownAction_({
		win.view.focus;
	});

	win.view.keyDownAction_({ |view, char|
		handleKey.value(char);
	});

	win.view.keyUpAction_({ |view, char|
		var key = char.asString.toLower.asSymbol;
		var vowelKey = normalizeVowelKey.value(char);

		if(consonantPresets[key].notNil or: { vowelPresets[vowelKey].notNil }) {
			if(vowelPresets[vowelKey].notNil) {
				activeVowels.remove(vowelKey);
				updateVowelGates.value;
			};
			if(consonantPresets[key].notNil and: { activeConsonant == key }) {
				activeConsonant = \none;
				applyConsonant.value(\none);
				setSoundGate.value(activeVowels.size > 0);
			};
		};
	});

	win.onClose_({
		stopRecording.value;
		if(synth.notNil) { synth.free };
	});
});
)
