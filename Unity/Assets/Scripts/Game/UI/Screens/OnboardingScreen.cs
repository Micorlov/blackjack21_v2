using Blackjack.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The first screen: play now as a guest, or continue with Google. The voice switch is offered up front.</summary>
    public sealed class OnboardingScreen : ScreenView
    {
        private Dyn _body;
        private RectTransform _host;
        private ScrollRect _scroll;

        public OnboardingScreen(GameController g, Overlays o) : base(g, o) { }

        public override void Build(RectTransform parent)
        {
            Root = Ui.Node("Onboarding", parent).Fill();
            var bg = W.Raw(Root, Gfx.Room(), "Background");
            bg.rectTransform.Fill();

            // Faint decorative suits: background chrome only.
            var spade = Ui.Box(Root, Color.white.WithAlpha(0.03f), 0, "Spade");
            spade.sprite = Sprites.Suit("♠"); spade.type = Image.Type.Simple;
            spade.rectTransform.Pin(new Vector2(0, 1), new Vector2(0, 1), new Vector2(-30, 40), new Vector2(200, 200));
            spade.rectTransform.localRotation = Quaternion.Euler(0, 0, 15);
            var diamond = Ui.Box(Root, Theme.Gold.WithAlpha(0.05f), 0, "Diamond");
            diamond.sprite = Sprites.Suit("♦"); diamond.type = Image.Type.Simple;
            diamond.rectTransform.Pin(new Vector2(1, 0), new Vector2(1, 0), new Vector2(40, -60), new Vector2(220, 220));
            diamond.rectTransform.localRotation = Quaternion.Euler(0, 0, -12);

            var scroll = W.Scroll(Root, Ui.Pad(28, 24, 28, 12), 0, true, false, out var sr);
            scroll.Fill();
            _scroll = sr;
            _host = Ui.VStack(sr.content, 0, null, TextAnchor.MiddleCenter, true, "Body");
            _body = new Dyn(_host);
        }

        public override void Tick()
        {
            // Centre the column on tall screens; it scrolls instead when the viewport is short.
            var viewport = _scroll.viewport.rect.height - 36f;
            if (viewport > 0) _host.Ensure<LayoutElement>().minHeight = viewport;
        }

        public override void Refresh(AppState s)
        {
            var sig = $"{s.VoiceOn}|{Loc.Code}";
            _body.Update(sig, host => BuildBody(host, s));
        }

        private void BuildBody(RectTransform host, AppState s)
        {
            host.gameObject.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            host.gameObject.GetComponent<VerticalLayoutGroup>().childForceExpandWidth = false;

            var badge = Ui.Box(host, Theme.Gold, Theme.RadiusXxl, "Badge");
            badge.rectTransform.Size(88, 88);
            var t = Ui.Text(badge.transform, "21", 33, Theme.GoldInk, FontKind.MonoBold, TextAlignmentOptions.Center, false);
            t.rectTransform.Fill();
            Ui.Spacer(host, 22);
            Ui.Text(host, "Blackjack 21", 40, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Center, false);
            Ui.Spacer(host, 10);
            var benefit = Ui.Text(host, Loc.T("welcomeBenefit"), 17, Theme.TextPrimary.WithAlpha(0.85f), FontKind.Sora,
                TextAlignmentOptions.Top, true, 0, 18);
            benefit.rectTransform.Size(280);
            Ui.Spacer(host, 40);

            var playNow = W.GoldButton(host, Loc.T("playNow"), G.PlayNow);
            playNow.Size(300);
            Ui.Spacer(host, 12);
            GoogleButton(host).Size(300);
            Ui.Spacer(host, 24);
            VoiceToggle(host, s.VoiceOn).Size(300);
            Ui.Spacer(host, Theme.Sm);

            var consent = Ui.Text(host, Loc.Or("consentLine", "By continuing you agree to the Terms & Privacy Policy."), 13,
                Theme.TextPrimary.WithAlpha(0.7f), FontKind.Sora, TextAlignmentOptions.Top, true);
            consent.rectTransform.Size(300);
            var links = Ui.HStack(host, Theme.Sm, null, TextAnchor.MiddleCenter, false);
            W.TextLink(links, Loc.Or("terms", "Terms"), () => LegalPage.Show(Overlays, LegalContent.Terms), Theme.Gold, 14);
            W.TextLink(links, Loc.Or("privacy", "Privacy"), () => LegalPage.Show(Overlays, LegalContent.Privacy), Theme.Gold, 14);
        }

        private RectTransform GoogleButton(RectTransform host)
        {
            var card = Ui.Card(host, Color.white, Theme.RadiusMd, null, 0, Ui.Pad(0, Theme.Lg), 0, true, "Google");
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            var row = Ui.HStack(card, 10, null, TextAnchor.MiddleCenter, false);
            var g = Ui.Box(row, Color.white, 0, "G");
            g.sprite = Sprites.Circle; g.type = Image.Type.Simple;
            g.rectTransform.Size(20, 20);
            Ui.Text(g.transform, "G", 15, Theme.GoogleBlue, FontKind.SoraBold, TextAlignmentOptions.Center, false).rectTransform.Fill();
            Ui.Text(row, Loc.T("continueGoogle"), 17, Theme.PillInk, FontKind.SoraBold, TextAlignmentOptions.Center, false);
            card.MakePressable(G.SignInGoogle);
            card.GetComponent<Image>().raycastTarget = true;
            return card;
        }

        private RectTransform VoiceToggle(RectTransform host, bool on)
        {
            var card = Ui.Card(host, Color.black.WithAlpha(0.22f), Theme.RadiusMd, null, 0, Ui.Pad(Theme.Md, Theme.Sm, Theme.Sm, Theme.Sm), 0, true, "Voice");
            card.MinSize(null, Theme.MinTarget);
            var row = Ui.HStack(card, 10, null, TextAnchor.MiddleLeft, false);
            W.Icon(row, on ? "volume_up" : "volume_off", 20, on ? Theme.Gold : Theme.TextPrimary.WithAlpha(0.55f));
            var label = Ui.Text(row, Loc.T("voiceCalloutsLabel"), 15, Theme.TextPrimary.WithAlpha(on ? 0.95f : 0.6f), FontKind.SoraBold,
                TextAlignmentOptions.Left, true);
            label.rectTransform.FlexW();
            // The card is the target; the switch only shows the state.
            W.Switch(row, on, null);
            card.MakePressable(G.ToggleVoice);
            card.GetComponent<Image>().raycastTarget = true;
            return card;
        }
    }

    /// <summary>The Terms and Privacy pages, shown as full-screen overlays.</summary>
    public static class LegalPage
    {
        public static void Show(Overlays overlays, LegalDoc doc)
        {
            overlays.Page((safe, close) =>
            {
                var col = Ui.VStack(safe, 0, null, TextAnchor.UpperLeft, true, "Legal").Fill();
                var head = Ui.HStack(col, Theme.Xs, Ui.Pad(Theme.Sm, Theme.Sm, Theme.Xl, Theme.Sm), TextAnchor.MiddleLeft, false);
                W.CircleIconButton(head, "chevron_left", close, 26).GetComponent<Image>().color = Color.clear;
                var title = Ui.Text(head, doc.Title, 32, Theme.TextPrimary, FontKind.SerifItalic, TextAlignmentOptions.Left, true, 0, -10);
                title.rectTransform.FlexW();

                var scrollRoot = W.Scroll(col, Ui.Pad(Theme.Xl, 0, Theme.Xl, Theme.Xxl), 0, true, false, out var sr);
                scrollRoot.Flex();
                Ui.Text(sr.content, doc.Updated, 12, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true);
                Ui.Spacer(sr.content, Theme.Md);
                Ui.Text(sr.content, doc.Intro, 15, Theme.TextPrimary, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 20);
                foreach (var section in doc.Sections)
                {
                    Ui.Spacer(sr.content, Theme.Xl);
                    Ui.Text(sr.content, section.Heading, 17, Theme.Gold, FontKind.SoraBold, TextAlignmentOptions.TopLeft, true);
                    Ui.Spacer(sr.content, Theme.Xs);
                    Ui.Text(sr.content, section.Body, 15, Theme.TextMuted, FontKind.Sora, TextAlignmentOptions.TopLeft, true, 0, 20);
                }
            });
        }
    }
}
