type AudioCtor = typeof AudioContext;

let ctx: AudioContext | null = null;

function getContext(): AudioContext | null {
  if (ctx) return ctx;
  const Ctor: AudioCtor | undefined =
    window.AudioContext ?? (window as unknown as { webkitAudioContext?: AudioCtor }).webkitAudioContext;
  if (!Ctor) return null;
  try {
    ctx = new Ctor();
  } catch {
    ctx = null;
  }
  return ctx;
}

function needsResume(audio: AudioContext): boolean {
  return audio.state !== 'running' && audio.state !== 'closed';
}

export function unlockAudio(): void {
  const audio = getContext();
  if (audio && needsResume(audio)) audio.resume().catch(() => {});
}

export function playAlertSound(): void {
  try {
    const audio = getContext();
    if (!audio) return;
    if (needsResume(audio)) audio.resume().catch(() => {});
    const osc = audio.createOscillator();
    const gain = audio.createGain();
    osc.connect(gain);
    gain.connect(audio.destination);
    osc.frequency.value = 880;
    gain.gain.setValueAtTime(0.3, audio.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audio.currentTime + 1.2);
    osc.start();
    osc.stop(audio.currentTime + 1.2);
  } catch {
    return;
  }
}
