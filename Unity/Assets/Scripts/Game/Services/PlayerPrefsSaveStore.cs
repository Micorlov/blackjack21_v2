using System;
using Blackjack.Core;
using UnityEngine;

namespace Blackjack.Game.Services
{
    /// <summary>Saves to PlayerPrefs under the same keys the Flutter app used.</summary>
    public sealed class PlayerPrefsSaveStore : ISaveStore
    {
        private const string SaveKey = "gameStateV1";
        private const string LastClaimKey = "dailyBonusLastClaimMs";
        private const string StreakDayKey = "dailyBonusStreakDay";

        public SavedGame Load()
        {
            try
            {
                var raw = PlayerPrefs.GetString(SaveKey, "");
                return string.IsNullOrEmpty(raw) ? null : SavedGameJson.FromJson(raw);
            }
            catch (Exception e)
            {
                Debug.LogWarning("Save load failed: " + e.Message);
                return null;
            }
        }

        public void Save(SavedGame game)
        {
            try
            {
                PlayerPrefs.SetString(SaveKey, SavedGameJson.ToJson(game));
                PlayerPrefs.Save();
            }
            catch (Exception e)
            {
                Debug.LogWarning("Save failed: " + e.Message);
            }
        }

        public DateTime? LoadLastClaim()
        {
            // PlayerPrefs has no long; the claim time is stored as a string of milliseconds.
            var raw = PlayerPrefs.GetString(LastClaimKey, "");
            if (!long.TryParse(raw, out var ms) || ms <= 0) return null;
            return DateTimeOffset.FromUnixTimeMilliseconds(ms).LocalDateTime;
        }

        public int LoadStreakDay() => PlayerPrefs.GetInt(StreakDayKey, 0);

        public void SaveClaim(DateTime claimedAt, int streakDay)
        {
            PlayerPrefs.SetString(LastClaimKey, new DateTimeOffset(claimedAt).ToUnixTimeMilliseconds().ToString());
            PlayerPrefs.SetInt(StreakDayKey, streakDay);
            PlayerPrefs.Save();
        }
    }
}
