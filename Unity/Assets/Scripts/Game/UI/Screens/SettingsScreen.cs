using System;
using System.Linq;
using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>Account, avatar, language, sound, notifications, privacy, help and about.</summary>
    public sealed class SettingsScreen : ScreenView
    {
        private const string VideoPokerUrl =
            "https://play.google.com/store/apps/details?id=com.micorlov.videopoker&referrer=utm_source%3Dblackjack21";

        private Dyn _body;

        public SettingsScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("Settings", parent).Fill();
            var scroll = W.Scroll(Root, Ui.Pad(20, 20, 20, 24), 0, true, false, out var sr);
            scroll.Fill();
            _body = new Dyn(Ui.VStack(sr.content, 0, null, TextAnchor.UpperLeft, true, "Body"));
        }

        public override void Refresh(AppState s)
        {
            var sig = $"{s.SignedIn}|{s.DisplayName}|{s.AvatarColor}|{s.LanguageOverride}|{s.HapticsOn}{s.SoundOn}{s.VoiceOn}"
                      + $"{s.NotifSocial}{s.NotifLeaderboard}{s.NotifDaily}{s.AnalyticsOn}|{Loc.Code}";
            _body.Update(sig, host => Build(host, s));
        }

        private void Build(RectTransform host, AppState s)
        {
            W.ScreenTitle(host, Loc.T("settingsTitle"));
            W.SectionLabel(host, Loc.T("settingsSectionAccount"));
            Account(host, s);
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionAvatarColor"));
            AvatarColors(host, s);
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionLanguage"));
            Languages(host, s);
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionSoundHaptics"));
            Toggles(host,
                (Loc.T("hapticsLabel"), s.HapticsOn, G.ToggleHaptics, null, true),
                (Loc.T("soundEffectsLabel"), s.SoundOn, G.ToggleSound, null, true),
                (Loc.T("voiceCalloutsLabel"), s.VoiceOn, G.ToggleVoice,
                    s.SoundOn ? Loc.T("voiceCalloutsSublabel") : Loc.T("voiceCalloutsDisabledReason"), s.SoundOn));
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionNotifications"));
            Toggles(host,
                (Loc.T("notifSocialLabel"), s.NotifSocial, G.ToggleNotifSocial, Loc.T("notifSocialSublabel"), true),
                (Loc.T("notifLeaderboardLabel"), s.NotifLeaderboard, G.ToggleNotifLeaderboard, Loc.T("notifLeaderboardSublabel"), true),
                (Loc.T("notifDailyLabel"), s.NotifDaily, G.ToggleNotifDaily, Loc.T("notifDailySublabel"), true));
            Ui.Spacer(host, 16);

            // Its own section: the only switch here that changes what leaves the device. Not localised, as in Flutter.
            W.SectionLabel(host, "Privacy");
            Toggles(host, ("Usage & crash reports", s.AnalyticsOn, () => G.SetAnalytics(!s.AnalyticsOn),
                "Anonymous counts of hands played and crashes, so problems can be found and fixed. Never your name, your group code or your chat.", true));
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionHelp"));
            Links(host, null,
                (Loc.T("howToPlayLabel"), Loc.T("howToPlaySublabel"), null, (Action)(() => HowToPlaySheet.Show(Overlays))),
                (Loc.T("replayTutorialLabel"), Loc.T("replayTutorialSublabel", ("count", Tutorial.Rounds)), null, (Action)G.RestartTutorial));
            Ui.Spacer(host, 16);

            W.SectionLabel(host, Loc.T("settingsSectionAbout"));
            Links(host, (Loc.T("versionLabel"), Application.version),
                (Loc.T("termsOfServiceLabel"), Loc.T("termsOfServiceSublabel"), null, (Action)(() => LegalPage.Show(Overlays, LegalContent.Terms))),
                (Loc.T("privacyPolicyLabel"), Loc.T("privacyPolicySublabel"), null, (Action)(() => LegalPage.Show(Overlays, LegalContent.Privacy))),
                (Loc.T("moreGamesVideoPokerLabel"), Loc.T("moreGamesVideoPokerSublabel"), "style", (Action)OpenVideoPoker));
        }

        private void OpenVideoPoker()
        {
            if (!G.Services.Platform.OpenUrl(VideoPokerUrl)) G.ShowToast(Loc.T("moreGamesOpenFailed"));
        }

        private void Account(RectTransform host, AppState s)
        {
            var panel = W.Panel(host, Ui.Pad(16), 12);
            if (!s.SignedIn)
            {
                W.GoldButton(panel, Loc.T("signIn"), G.SignInGoogle);
                return;
            }
            var row = Ui.HStack(panel, 10, null, TextAnchor.MiddleLeft, false);
            var initial = s.DisplayName.Trim().Length == 0 ? "G" : s.DisplayName.Trim().Substring(0, 1).ToUpperInvariant();
            W.Avatar(row, initial, Theme.AvatarColorOf(s.AvatarColor), 44);
            var name = Ui.Text(row, s.DisplayName, 16, Theme.TextPrimary, FontKind.SoraBold, TextAlignmentOptions.Left, false);
            name.Shrink();
            name.rectTransform.FlexW();
            // Signing out drops a signed-in player back to guest and leaves the live group: confirm first.
            W.ActionPill(panel, Loc.T("signOut"), Theme.BorderStrong, Color.clear, Theme.TextPrimary,
                () => ConfirmDialog.Show(Overlays, Loc.T("signOutConfirmTitle"), Loc.T("signOutConfirmMessage"), Loc.T("signOut"), G.SignOutUser,
                    null, true), 17, 0, 16);
        }

        private void AvatarColors(RectTransform host, AppState s)
        {
            var panel = W.Panel(host, Ui.Pad(16), 0);
            var row = Ui.HStack(panel, 12, null, TextAnchor.MiddleLeft, false);
            var selected = Theme.AvatarColorOf(s.AvatarColor);
            foreach (var color in Theme.AvatarSwatches)
            {
                var c = color;
                var isSelected = Mathf.Approximately(c.r, selected.r) && Mathf.Approximately(c.g, selected.g) && Mathf.Approximately(c.b, selected.b);
                var ring = W.Dot(row, Theme.MinTarget, isSelected ? Theme.TextPrimary : Color.clear);
                var swatch = W.Dot(ring.transform, Theme.MinTarget - (isSelected ? 6 : 0), c);
                swatch.rectTransform.IgnoreLayout();
                swatch.rectTransform.PinCentre(Vector2.zero, new Vector2(Theme.MinTarget - (isSelected ? 6 : 0), Theme.MinTarget - (isSelected ? 6 : 0)));
                ring.rectTransform.MakePressable(() => G.SelectAvatarColor(Theme.ToArgb(c)));
                ring.raycastTarget = true;
            }
        }

        private void Languages(RectTransform host, AppState s)
        {
            Fonts.EnsureAllScripts();
            Fonts.Prewarm(string.Concat(Loc.Supported.Select(c => Loc.T("languageName" + char.ToUpperInvariant(c[0]) + c.Substring(1)))));
            var panel = W.Panel(host, Ui.Pad(16, 0), 0);
            var entries = new System.Collections.Generic.List<(string label, string code)> { (Loc.T("languageSystemDefault"), null) };
            foreach (var code in Loc.Supported) entries.Add((Loc.T("languageName" + char.ToUpperInvariant(code[0]) + code.Substring(1)), code));
            for (var i = 0; i < entries.Count; i++)
            {
                var (label, code) = entries[i];
                var selected = s.LanguageOverride == code;
                var row = Ui.HStack(panel, 8, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
                row.MinSize(null, Theme.MinTarget);
                var t = Ui.Text(row, label, 16, Theme.TextPrimary, FontKind.SoraSemiBold, TextAlignmentOptions.Left, false);
                t.rectTransform.FlexW();
                if (selected) W.Icon(row, "check", 24, Theme.Gold);
                var pick = code;
                row.MakePressable(() => G.SetLanguage(pick));
                row.Ensure<FlatImage>();
                if (i < entries.Count - 1) W.Divider(panel);
            }
        }

        private static void Toggles(RectTransform host, params (string label, bool on, Action toggle, string sub, bool enabled)[] rows)
        {
            var panel = W.Panel(host, Ui.Pad(16, 0), 0);
            for (var i = 0; i < rows.Length; i++)
            {
                var r = rows[i];
                var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
                var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
                col.FlexW();
                Ui.Text(col, r.label, 16, Theme.TextPrimary, FontKind.SoraSemiBold, TextAlignmentOptions.TopLeft, true);
                if (r.sub != null) Ui.Text(col, r.sub, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 6);
                W.Switch(row, r.on, r.toggle, r.enabled);
                // Dimming the whole row, so a disabled switch does not keep its gold and read as live.
                if (!r.enabled) row.Ensure<CanvasGroup>().alpha = 0.45f;
                if (i < rows.Length - 1) W.Divider(panel);
            }
        }

        private static void Links(RectTransform host, (string label, string value)? info,
            params (string label, string sub, string icon, Action tap)[] rows)
        {
            var panel = W.Panel(host, Ui.Pad(16, 0), 0);
            for (var i = 0; i < rows.Length; i++)
            {
                var r = rows[i];
                var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
                row.MinSize(null, Theme.MinTarget);
                if (r.icon != null) W.Icon(row, r.icon, 22, Theme.Gold);
                var col = Ui.VStack(row, 2, null, TextAnchor.MiddleLeft, true);
                col.FlexW();
                Ui.Text(col, r.label, 16, Theme.TextPrimary, FontKind.SoraSemiBold, TextAlignmentOptions.TopLeft, true);
                Ui.Text(col, r.sub, 13, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 6);
                W.Icon(row, "chevron_right", 22, Theme.TextFaint);
                row.MakePressable(r.tap);
                row.Ensure<FlatImage>();
                if (i < rows.Length - 1 || info.HasValue) W.Divider(panel);
            }
            if (info.HasValue)
            {
                var row = Ui.HStack(panel, 12, Ui.Pad(0, 15), TextAnchor.MiddleLeft, false);
                Ui.Text(row, info.Value.label, 16, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.Left, false).rectTransform.FlexW();
                Ui.Text(row, info.Value.value, 16, Theme.TextPrimary, FontKind.Mono, TextAlignmentOptions.Right, false);
            }
        }
    }
}
