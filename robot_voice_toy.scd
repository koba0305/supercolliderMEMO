/*
Robot Voice Toy for SuperCollider

How to use:
1. Evaluate this whole file.
2. Move the mouse anywhere on the screen:
   - X changes pitch
   - Y changes growl depth
3. Use the volume slider if you want it louder.
4. Click the window, then press keys: a i u e o or 1 2 3 4 5
5. Press Space to mute / unmute.
6. Press Record / Stop rec to save a WAV into ./recordings.
7. Close the window or press Cmd+. to stop.
*/

(
s.waitForBoot({
	var win, label, info, volumeLabel, volumeSlider, muteLabel, recordButton, recordLabel, synth;
	var vowelPresets, applyVowel, setVowel, startRecording, stopRecording, toggleRecording;
	var currentAmp = 0.20, isMuted = false, isRecording = false, toggleMute;
	var recordDir, recordingPath;

	vowelPresets = (
		a: [800, 1150, 2900, 0.040, "A"],
		i: [350, 1700, 2700, 0.030, "I"],
		u: [325, 700, 2530, 0.050, "U"],
		e: [500, 1750, 2450, 0.035, "E"],
		o: [450, 800, 2830, 0.045, "O"]
	);

	SynthDef(\robotVoiceToy, {
		|out = 0, f1 = 800, f2 = 1150, f3 = 2900, rq = 0.04, amp = 0.14|
		var pitch, growl, wobbleDepth, vibrato, base;
		var voiced, formants, slowWobble, robot, env;

		// Mouse UGens are server-side, so movement works even if GUI focus is weird.
		pitch = MouseX.kr(70, 280, 1).round(2);
		growl = MouseY.kr(1.2, 12.0);
		wobbleDepth = MouseY.kr(0.04, 0.22);

		vibrato = SinOsc.kr(growl, 0, pitch * 0.03);
		base = (pitch + vibrato).clip(50, 400);

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
		robot = formants * slowWobble;
		robot = robot * SinOsc.ar(26, 0, 0.18, 0.82);
		robot = robot + WhiteNoise.ar(0.002);
		robot = LeakDC.ar(tanh(robot * 2.5));
		robot = HPF.ar(robot, 90);

		env = EnvGen.kr(Env.asr(0.02, 1, 0.2), 1);
		Out.ar(out, (robot * env * amp).dup);
	}).add;

	s.sync;

	synth = Synth(\robotVoiceToy, [\amp, 0.20]);
	recordDir = (thisProcess.nowExecutingPath.notNil).if({
		thisProcess.nowExecutingPath.dirname +/+ "recordings"
	}, {
		Platform.recordingsDir
	});
	recordDir.mkdir;

	win = Window("Robot Voice Toy", Rect(120, 120, 520, 260)).front;
	win.alwaysOnTop_(true);
	win.view.background_(Color.gray(0.14));
	win.view.canFocus_(true);
	win.view.focus;

	label = StaticText(win, Rect(20, 18, 480, 30))
		.string_("Robot vowel: A")
		.stringColor_(Color.white)
		.font_(Font("Helvetica", 22));

	info = StaticText(win, Rect(20, 54, 480, 78))
		.string_(
			"Move mouse anywhere on screen:\n" ++
				"X = pitch, Y = growl depth\n\n" ++
				"Press: a i u e o or 1 2 3 4 5\n" ++
				"Space = mute / unmute, Record = WAV"
			)
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 16));

	volumeLabel = StaticText(win, Rect(20, 137, 100, 22))
		.string_("Volume")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 14));

	volumeSlider = Slider(win, Rect(90, 139, 250, 20))
		.value_(0.78)
		.action_({ |slider|
			currentAmp = slider.value.linexp(0, 1, 0.02, 0.38);
			if(isMuted.not) {
				synth.set(\amp, currentAmp);
			};
			win.view.focus;
		});

	muteLabel = StaticText(win, Rect(360, 137, 140, 22))
		.string_("Sound: on")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 14));

	recordButton = Button(win, Rect(360, 166, 120, 32))
		.states_([
			["Record", Color.white, Color.gray(0.28)],
			["Stop rec", Color.white, Color.red(0.55)]
		]);

	recordLabel = StaticText(win, Rect(20, 210, 470, 22))
		.string_("Recording: off")
		.stringColor_(Color.gray(0.88))
		.font_(Font("Helvetica", 13));

	toggleMute = {
		isMuted = isMuted.not;
		if(isMuted) {
			synth.set(\amp, 0);
			muteLabel.string = "Sound: muted";
		} {
			synth.set(\amp, currentAmp);
			muteLabel.string = "Sound: on";
		};
	};

	startRecording = {
		if(isRecording.not) {
			recordingPath = recordDir +/+ ("robot_voice_toy_" ++ Date.getDate.stamp ++ ".wav");
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

	setVowel = { |char|
		var key = char.asString.toLower;
		var vowelKey = key.asSymbol;

		if(key == " ") {
			toggleMute.value;
		} {
			if(key == "1") { vowelKey = \a };
			if(key == "2") { vowelKey = \i };
			if(key == "3") { vowelKey = \u };
			if(key == "4") { vowelKey = \e };
			if(key == "5") { vowelKey = \o };
			applyVowel.value(vowelKey);
		};
	};

	Button(win, Rect(20, 166, 56, 32))
		.states_([["A", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\a); win.view.focus; });

	Button(win, Rect(86, 166, 56, 32))
		.states_([["I", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\i); win.view.focus; });

	Button(win, Rect(152, 166, 56, 32))
		.states_([["U", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\u); win.view.focus; });

	Button(win, Rect(218, 166, 56, 32))
		.states_([["E", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\e); win.view.focus; });

	Button(win, Rect(284, 166, 56, 32))
		.states_([["O", Color.white, Color.gray(0.28)]])
		.action_({ applyVowel.value(\o); win.view.focus; });

	win.view.mouseDownAction_({
		win.view.focus;
	});

	win.view.keyDownAction_({ |view, char|
		setVowel.value(char);
	});

	win.onClose_({
		stopRecording.value;
		if(synth.notNil) { synth.free };
	});
});
)
