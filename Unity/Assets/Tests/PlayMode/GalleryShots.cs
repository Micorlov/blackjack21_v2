using System.Collections;
using Blackjack.Game.UI;
using NUnit.Framework;
using TMPro;
using UnityEngine;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace Blackjack.PlayTests
{
    public class GalleryShots
    {
        [UnityTest]
        public IEnumerator Gallery_rendersSpritesTextAndLayout()
        {
            var stage = Shots.Create();
            var page = Ui.VStack(stage.Root.Safe, 16, Ui.Pad(20, 40)).Fill();

            Ui.Text(page, "Blackjack 21", 40, Theme.TextPrimary, FontKind.SerifItalic);
            Ui.Text(page, "Big, readable cards. Learn as you play, one hand at a time.", 15, Theme.TextMuted);

            var card = Ui.Card(page, Theme.Panel, 16, Theme.Border, 1, Ui.Pad(16), 8);
            Ui.Text(card, "SWEEP POT", 13, Theme.TextFaint, FontKind.SoraSemiBold);
            Ui.Text(card, "$1,250", 32, Theme.Gold, FontKind.MonoBold);

            var suits = Ui.HStack(page, 16);
            foreach (var s in new[] { "♠", "♥", "♦", "♣" })
            {
                var img = Ui.Box(suits, s == "♥" || s == "♦" ? Theme.CardRed : Theme.CardBlack, 0, s);
                img.sprite = Sprites.Suit(s);
                img.rectTransform.Size(96, 96);
            }

            var btn = Ui.Box(page, Theme.Gold, 16, "Button");
            btn.rectTransform.Size(null, 56);
            var label = Ui.Text(btn.transform, "DEAL", 17, Theme.GoldInk, FontKind.SoraBold, TextAlignmentOptions.Center);
            label.rectTransform.Fill();

            yield return Shots.Capture(stage, "gallery");
            Shots.Destroy(stage);
            Assert.Pass();
        }
    }
}
