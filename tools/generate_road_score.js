"use strict";

// Creates the original, loop-crossfaded instrumental theme used by the game.
// Run from the project root with: node tools/generate_road_score.js
const fs = require("node:fs");
const path = require("node:path");

const SAMPLE_RATE = 22050;
const TEMPO_BPM = 96;
const BEAT_SECONDS = 60 / TEMPO_BPM;
const BAR_SECONDS = BEAT_SECONDS * 4;
const BAR_COUNT = 32;
const DURATION_SECONDS = BAR_SECONDS * BAR_COUNT;
const FRAME_COUNT = Math.round(SAMPLE_RATE * DURATION_SECONDS);
const OUTPUT_PATH = path.resolve(__dirname, "../assets/audio/road_theme.wav");

const left = new Float32Array(FRAME_COUNT);
const right = new Float32Array(FRAME_COUNT);
let randomState = 0x5a17e3;

function randomBipolar() {
	randomState = (Math.imul(randomState, 1664525) + 1013904223) >>> 0;
	return (randomState / 0xffffffff) * 2 - 1;
}

function frequencyForMidi(note) {
	return 440 * Math.pow(2, (note - 69) / 12);
}

function sectionGain(bar) {
	if (bar < 4) return 0.48;
	if (bar < 8) return 0.72;
	if (bar < 24) return 1.0;
	if (bar < 28) return 0.88;
	return 0.64;
}

function addVoice(startSeconds, durationSeconds, midi, voice, amplitude, pan, voiceSeed = 0) {
	const startFrame = Math.max(0, Math.floor(startSeconds * SAMPLE_RATE));
	const endFrame = Math.min(FRAME_COUNT, Math.ceil((startSeconds + durationSeconds) * SAMPLE_RATE));
	const frameLength = Math.max(0, endFrame - startFrame);
	if (frameLength === 0) return;

	const frequency = frequencyForMidi(midi);
	const leftGain = Math.cos(((pan + 1) * Math.PI) / 4);
	const rightGain = Math.sin(((pan + 1) * Math.PI) / 4);
	const detune = (voiceSeed % 9 - 4) * 0.00055;
	const phaseOffset = (voiceSeed % 7) * 0.19;
	const attackSeconds = voice === "pad" ? 0.42 : 0.008;
	const releaseSeconds = voice === "pad" ? 0.7 : 0.11;

	for (let frame = startFrame; frame < endFrame; frame += 1) {
		const t = (frame - startFrame) / SAMPLE_RATE;
		const remaining = durationSeconds - t;
		const attack = Math.min(1, t / attackSeconds);
		const release = Math.min(1, Math.max(0, remaining / releaseSeconds));
		let envelope = attack * release;
		let sample;
		const phase = 2 * Math.PI * frequency * t + phaseOffset;

		if (voice === "pad") {
			const slowBreath = 0.91 + 0.09 * Math.sin(2 * Math.PI * 0.17 * t + phaseOffset);
			const warmCore = Math.sin(phase);
			const detunedCore = Math.sin(phase * (1 + detune) + 0.31);
			const upperAir = Math.sin(phase * 2.003 + 0.73);
			sample = (warmCore * 0.56 + detunedCore * 0.32 + upperAir * 0.12) * slowBreath;
		} else if (voice === "pluck") {
			envelope *= Math.exp(-t * 4.8);
			sample = Math.sin(phase) * 0.68 + Math.sin(phase * 2.01 + 0.4) * 0.24 + Math.sin(phase * 3.97) * 0.08;
		} else if (voice === "bass") {
			envelope *= Math.exp(-t * 3.1);
			sample = Math.sin(phase) * 0.82 + Math.sin(phase * 2.0) * 0.18;
		} else {
			sample = Math.sin(phase);
		}

		const value = sample * envelope * amplitude;
		left[frame] += value * leftGain;
		right[frame] += value * rightGain;
	}
}

function addKick(startSeconds, amplitude) {
	const startFrame = Math.floor(startSeconds * SAMPLE_RATE);
	const frameCount = Math.min(Math.ceil(0.34 * SAMPLE_RATE), FRAME_COUNT - startFrame);
	for (let offset = 0; offset < frameCount; offset += 1) {
		const t = offset / SAMPLE_RATE;
		const phase = 2 * Math.PI * (47 * t + 65 * (1 - Math.exp(-21 * t)) / 21);
		const body = Math.sin(phase) * Math.exp(-t * 13);
		const softClick = Math.sin(2 * Math.PI * 190 * t) * Math.exp(-t * 54) * 0.08;
		const value = (body + softClick) * amplitude;
		left[startFrame + offset] += value * 0.71;
		right[startFrame + offset] += value * 0.71;
	}
}

function addSnare(startSeconds, amplitude, seedOffset) {
	const startFrame = Math.floor(startSeconds * SAMPLE_RATE);
	const frameCount = Math.min(Math.ceil(0.24 * SAMPLE_RATE), FRAME_COUNT - startFrame);
	let previousNoise = 0;
	for (let offset = 0; offset < frameCount; offset += 1) {
		const t = offset / SAMPLE_RATE;
		const noise = randomBipolar();
		const highNoise = noise - previousNoise * 0.67;
		previousNoise = noise;
		const decay = Math.exp(-t * (17 + (seedOffset % 3)));
		const tone = Math.sin(2 * Math.PI * (185 + seedOffset) * t) * Math.exp(-t * 22) * 0.2;
		const value = (highNoise * 0.8 + tone) * decay * amplitude;
		left[startFrame + offset] += value * 0.64;
		right[startFrame + offset] += value * 0.64;
	}
}

function addHat(startSeconds, amplitude, pan) {
	const startFrame = Math.floor(startSeconds * SAMPLE_RATE);
	const frameCount = Math.min(Math.ceil(0.075 * SAMPLE_RATE), FRAME_COUNT - startFrame);
	const leftGain = Math.cos(((pan + 1) * Math.PI) / 4);
	const rightGain = Math.sin(((pan + 1) * Math.PI) / 4);
	let previousNoise = 0;
	for (let offset = 0; offset < frameCount; offset += 1) {
		const t = offset / SAMPLE_RATE;
		const noise = randomBipolar();
		const metallic = noise - previousNoise * 0.9;
		previousNoise = noise;
		const value = metallic * Math.exp(-t * 58) * amplitude;
		left[startFrame + offset] += value * leftGain;
		right[startFrame + offset] += value * rightGain;
	}
}

const chords = [
	{ bass: 40, tones: [52, 59, 64, 67] }, // E minor
	{ bass: 36, tones: [48, 55, 60, 64] }, // C major
	{ bass: 43, tones: [50, 55, 59, 62] }, // G major
	{ bass: 38, tones: [50, 57, 62, 66] }, // D major
];
const melodyByBar = [
	[64, 67, 71, 74, 71, 67],
	[64, 67, 72, 76, 72, 67],
	[62, 67, 71, 74, 71, 67],
	[62, 66, 69, 74, 69, 66],
];

for (let bar = 0; bar < BAR_COUNT; bar += 1) {
	const start = bar * BAR_SECONDS;
	const chord = chords[bar % chords.length];
	const strength = sectionGain(bar);
	const padDuration = BAR_SECONDS * 1.16;
	for (let noteIndex = 0; noteIndex < chord.tones.length; noteIndex += 1) {
		const note = chord.tones[noteIndex];
		const pan = noteIndex % 2 === 0 ? -0.22 : 0.22;
		addVoice(start, padDuration, note, "pad", 0.028 * strength, pan, bar * 5 + noteIndex);
	}
	addVoice(start, BAR_SECONDS * 1.12, chord.tones[1] + 12, "pad", 0.009 * strength, -0.45, bar + 2);

	for (let beat = 0; beat < 4; beat += 1) {
		const beatStart = start + beat * BEAT_SECONDS;
		const bassNote = chord.bass + (beat === 2 ? 12 : 0);
		addVoice(beatStart, BEAT_SECONDS * 0.78, bassNote, "bass", 0.065 * strength, 0.0, bar * 4 + beat);
		if (bar >= 4 && (beat === 0 || beat === 2)) {
			addKick(beatStart, 0.105 * strength * (beat === 0 ? 1.0 : 0.78));
		}
		if (bar >= 4 && (beat === 1 || beat === 3)) {
			addSnare(beatStart, 0.041 * strength, bar + beat);
		}
	}

	if (bar >= 8 && bar < 28) {
		for (let eighth = 0; eighth < 8; eighth += 1) {
			const offbeat = eighth % 2 === 1;
			const accent = eighth === 2 || eighth === 6 ? 1.2 : 0.72;
			addHat(start + eighth * (BEAT_SECONDS / 2), 0.014 * strength * accent * (offbeat ? 0.84 : 1.0), eighth % 2 === 0 ? -0.32 : 0.32);
		}
	}

	if (bar >= 6 && bar < 28) {
		const motif = melodyByBar[bar % melodyByBar.length];
		const notesPerBar = bar < 8 || bar >= 24 ? 3 : motif.length;
		for (let noteIndex = 0; noteIndex < notesPerBar; noteIndex += 1) {
			const onsetBeat = [0.5, 1.5, 2.25, 3.0, 3.5, 3.75][noteIndex];
			const note = motif[noteIndex];
			const noteStrength = (noteIndex === 0 || noteIndex === 3 ? 1.0 : 0.72) * strength;
			addVoice(start + onsetBeat * BEAT_SECONDS, BEAT_SECONDS * 0.52, note, "pluck", 0.034 * noteStrength, noteIndex % 2 === 0 ? -0.18 : 0.18, bar + noteIndex * 3);
		}
	}

	if (bar % 4 === 3 && bar >= 8 && bar < 28) {
		const bellNote = chord.tones[2] + 12;
		addVoice(start + BEAT_SECONDS * 3.5, BEAT_SECONDS * 1.35, bellNote, "pluck", 0.021 * strength, 0.38, bar + 11);
	}
}

// Give the loop a soft, repeatable seam; the runtime crossfades the end into
// the next start so the intro/outro breath is not heard as a hard cut.
for (let frame = 0; frame < FRAME_COUNT; frame += 1) {
	const seconds = frame / SAMPLE_RATE;
	const fadeIn = Math.min(1, seconds / 2.2);
	const fadeOut = Math.min(1, (DURATION_SECONDS - seconds) / 2.4);
	const gain = fadeIn * fadeOut;
	left[frame] *= gain;
	right[frame] *= gain;
}

let peak = 0;
for (let frame = 0; frame < FRAME_COUNT; frame += 1) {
	peak = Math.max(peak, Math.abs(left[frame]), Math.abs(right[frame]));
}
const normalization = peak > 0 ? 0.72 / peak : 1;
const dataBytes = FRAME_COUNT * 4;
const wav = Buffer.alloc(44 + dataBytes);
wav.write("RIFF", 0, "ascii");
wav.writeUInt32LE(36 + dataBytes, 4);
wav.write("WAVE", 8, "ascii");
wav.write("fmt ", 12, "ascii");
wav.writeUInt32LE(16, 16);
wav.writeUInt16LE(1, 20);
wav.writeUInt16LE(2, 22);
wav.writeUInt32LE(SAMPLE_RATE, 24);
wav.writeUInt32LE(SAMPLE_RATE * 4, 28);
wav.writeUInt16LE(4, 32);
wav.writeUInt16LE(16, 34);
wav.write("data", 36, "ascii");
wav.writeUInt32LE(dataBytes, 40);
for (let frame = 0; frame < FRAME_COUNT; frame += 1) {
	const leftSample = Math.tanh(left[frame] * normalization * 1.15) / Math.tanh(1.15);
	const rightSample = Math.tanh(right[frame] * normalization * 1.15) / Math.tanh(1.15);
	wav.writeInt16LE(Math.round(Math.max(-1, Math.min(1, leftSample)) * 32767), 44 + frame * 4);
	wav.writeInt16LE(Math.round(Math.max(-1, Math.min(1, rightSample)) * 32767), 46 + frame * 4);
}

fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
fs.writeFileSync(OUTPUT_PATH, wav);
console.log(`ROAD_THEME_GENERATED path=${OUTPUT_PATH} duration_s=${DURATION_SECONDS} bpm=${TEMPO_BPM} bars=${BAR_COUNT} sample_rate=${SAMPLE_RATE} peak=${peak.toFixed(4)} bytes=${wav.length}`);
