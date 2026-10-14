using System.Collections.Generic;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>
    /// Plays tones on one channel and spoken lines on a queued voice channel. Voice lines are scheduled
    /// back to back so the dealer never talks over itself; words (numbers) are joined into one clip with
    /// a short gap between them, exactly as the Flutter player joined PCM.
    /// </summary>
    public sealed class UnitySoundService : MonoBehaviour, ISoundService
    {
        private const float MaxVoiceWait = 3f;
        private const float WordGapSeconds = 0.045f;
        private const int VoiceChannels = 4;

        private static readonly Dictionary<GameSfx, string> Tones = new Dictionary<GameSfx, string>
        {
            { GameSfx.Chip, "chip" }, { GameSfx.Deal, "deal" }, { GameSfx.Win, "win" }, { GameSfx.Lose, "lose" },
            { GameSfx.Push, "push" }, { GameSfx.Blackjack, "blackjack" }, { GameSfx.Turn, "turn" },
            { GameSfx.PotCelebration, "pot_celebration" },
        };

        private static readonly Dictionary<GameVoice, string> Voices = new Dictionary<GameVoice, string>
        {
            { GameVoice.PlayerWin, "player_win" }, { GameVoice.PlayerLose, "player_lose" }, { GameVoice.Push, "player_push" },
            { GameVoice.PlayerBlackjack, "player_blackjack" }, { GameVoice.PlayerBlackjackPot, "player_blackjack_pot" },
            { GameVoice.PlayerPot, "player_pot" }, { GameVoice.NpcStand, "npc_stand" }, { GameVoice.NpcBust, "npc_bust" },
        };

        private AudioSource _tone;
        private AudioSource[] _voice;
        private int _next;
        private double _voiceFreeAt;
        private readonly Dictionary<string, AudioClip> _clips = new Dictionary<string, AudioClip>();
        private readonly Dictionary<string, float[]> _samples = new Dictionary<string, float[]>();

        private void Awake()
        {
            _tone = gameObject.AddComponent<AudioSource>();
            _tone.playOnAwake = false;
            _voice = new AudioSource[VoiceChannels];
            for (var i = 0; i < VoiceChannels; i++)
            {
                _voice[i] = gameObject.AddComponent<AudioSource>();
                _voice[i].playOnAwake = false;
            }
        }

        private AudioClip Clip(string path)
        {
            if (_clips.TryGetValue(path, out var cached)) return cached;
            var clip = Resources.Load<AudioClip>("Sfx/" + path);
            if (clip == null) Debug.LogWarning("Missing audio clip " + path);
            _clips[path] = clip;
            return clip;
        }

        public void Play(GameSfx sfx)
        {
            var clip = Clip(Tones[sfx]);
            if (clip == null) return;
            _tone.Stop();
            _tone.clip = clip;
            _tone.Play();
        }

        public double? PlayVoice(GameVoice voice)
        {
            var clip = Clip(Voices[voice]);
            return clip == null ? null : Speak(clip);
        }

        public double? PlayWords(IReadOnlyList<string> words)
        {
            if (words.Count == 0) return null;
            var joined = Join(words);
            return joined == null ? null : Speak(joined);
        }

        public void SilenceVoice()
        {
            foreach (var channel in _voice) channel.Stop();
            _voiceFreeAt = 0;
        }

        private double? Speak(AudioClip clip)
        {
            var now = Time.realtimeSinceStartupAsDouble;
            var start = System.Math.Max(_voiceFreeAt, now);
            var wait = start - now;
            // A line that would wait too long is dropped rather than spoken over the wrong moment.
            if (wait > MaxVoiceWait) return null;
            var endsAt = start + clip.length;
            _voiceFreeAt = endsAt;

            var channel = _voice[_next++ % VoiceChannels];
            channel.Stop();
            channel.clip = clip;
            if (wait <= 0.001) channel.Play();
            else channel.PlayScheduled(AudioSettings.dspTime + wait);
            return endsAt;
        }

        // Joins word clips (all the same format) with a short silence between them.
        private AudioClip Join(IReadOnlyList<string> words)
        {
            var key = string.Join("|", words);
            if (_clips.TryGetValue("join:" + key, out var cached)) return cached;

            var parts = new List<float[]>();
            AudioClip first = null;
            foreach (var word in words)
            {
                var clip = Clip("num/" + word);
                if (clip == null) return null;
                first ??= clip;
                if (!_samples.TryGetValue(word, out var data))
                {
                    data = new float[clip.samples * clip.channels];
                    if (!clip.GetData(data, 0)) { Debug.LogWarning("Cannot read audio " + word); return null; }
                    _samples[word] = data;
                }
                parts.Add(data);
            }

            var channels = first.channels;
            var gap = (int)(first.frequency * WordGapSeconds) * channels;
            var total = 0;
            foreach (var p in parts) total += p.Length;
            total += gap * (parts.Count - 1);

            var buffer = new float[total];
            var at = 0;
            for (var i = 0; i < parts.Count; i++)
            {
                if (i > 0) at += gap;
                System.Array.Copy(parts[i], 0, buffer, at, parts[i].Length);
                at += parts[i].Length;
            }

            var joined = AudioClip.Create("words:" + key, total / channels, channels, first.frequency, false);
            joined.SetData(buffer, 0);
            _clips["join:" + key] = joined;
            return joined;
        }
    }
}
