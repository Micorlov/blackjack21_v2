using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>The Seat's controls: the table's gold, leather, felt and loss buttons, and its outline pills.</summary>
    public static partial class W
    {
        /// <summary>The finish of a Seat button.</summary>
        public enum Finish
        {
            /// <summary>Brass gold with dark ink: the move the table is waiting for (HIT, DEAL, INSURE).</summary>
            Gold,
            /// <summary>Padded leather with ivory: the quieter choice (STAND, CLEAR, NO THANKS).</summary>
            Leather,
            /// <summary>Felt green with a gold rim and gold type: an extra move (DOUBLE, SPLIT).</summary>
            Felt,
            /// <summary>An outline in the loss colour: a move that gives something up (SURRENDER).</summary>
            Loss,
        }

        public const float SeatButtonTall = 64f;
        public const float SeatButtonShort = 52f;
        private const float Lip = 4f;

        // Leather's rim is lighter than the leather so the button's edge keeps 3:1 against the dark room.
        private static readonly Color LeatherFill = Theme.Hex(0xFF4A1F0F);
        private static readonly Color LeatherRim = Theme.Hex(0xFFA8683C);
        private static readonly Color LeatherLip = Theme.Hex(0xFF1E0A03);
        private static readonly Color GoldFill = Theme.Hex(0xFFE2C686);
        private static readonly Color GoldLip = Theme.Hex(0xFF7E5E24);
        private static readonly Color GoldInkDeep = Theme.Hex(0xFF241608);
        private static readonly Color FeltFill = Theme.Hex(0xFF184F38);

        /// <summary>
        /// A Seat button: <paramref name="label"/> in caps (as <c>en.json</c> writes it) with an optional
        /// <paramref name="sub"/> line under it, sitting on a darker lip so it reads as something to press.
        /// </summary>
        public static RectTransform SeatButton(Transform parent, string label, string sub, Finish finish, Action onClick,
            bool enabled = true, float height = SeatButtonTall, string name = "SeatButton")
        {
            var (fill, rim, lip, ink) = finish switch
            {
                Finish.Gold => (GoldFill, (Color?)null, GoldLip, GoldInkDeep),
                Finish.Leather => (LeatherFill, (Color?)LeatherRim, LeatherLip, Theme.Ivory),
                Finish.Felt => (FeltFill, (Color?)Theme.Gold, Color.clear, Theme.Gold),
                _ => (Color.clear, (Color?)Theme.LoseOnPanel.WithAlpha(0.6f), Color.clear, Theme.LoseOnPanel),
            };

            var root = Ui.Node(name, parent);
            root.Size(null, height + (lip.a > 0 ? Lip : 0));
            if (lip.a > 0)
            {
                var under = Ui.Box(root, lip, Theme.RadiusMd, "Lip");
                under.rectTransform.IgnoreLayout();
                under.rectTransform.Fill(0, Lip, 0, 0);
            }
            var face = Ui.Box(root, fill, Theme.RadiusMd, "Face");
            face.rectTransform.IgnoreLayout();
            face.rectTransform.Fill(0, 0, 0, lip.a > 0 ? Lip : 0);
            if (rim.HasValue)
            {
                var outline = Ui.Box(face.transform, rim.Value, 0, "Rim");
                Ui.StyleRing(outline, rim.Value, Theme.RadiusMd, finish == Finish.Felt ? 1.5f : 1f);
                outline.rectTransform.Fill();
                // The outline is this button's edge against the room, so the audit holds it to 3:1.
                outline.gameObject.AddComponent<ControlBorder>();
            }

            var text = Ui.VStack(face.transform, 0, null, TextAnchor.MiddleCenter, false, "Label");
            text.Fill(Theme.Xs, 0, Theme.Xs, 0);
            var big = height >= SeatButtonTall ? 20f : 15f;
            Ui.Text(text, label, new TextStyle(big, FontKind.SoraBold, height >= SeatButtonTall ? 8f : 4f), ink, TextAlignmentOptions.Center, false).Shrink();
            if (!string.IsNullOrEmpty(sub))
                Ui.Text(text, sub, Type.Caption.WithFont(FontKind.Sora), ink, TextAlignmentOptions.Center, false).Shrink();

            var p = root.MakePressable(onClick);
            p.Interactable = enabled;
            return root;
        }

        /// <summary>A rounded outline pill at least 48 tall: ALL IN, the quick-chat chips.</summary>
        public static RectTransform OutlineChip(Transform parent, string label, Action onClick, Color border, Color fill, Color ink,
            float fontSize = 14f, FontKind font = FontKind.SoraSemiBold, float minWidth = 0f, bool enabled = true)
        {
            var card = Ui.Card(parent, fill, Theme.RadiusPill, border, 1, Ui.Pad(Theme.Lg, 0), 0, false, "Chip");
            var shell = (RectTransform)card.parent;
            shell.MinSize(minWidth > 0 ? minWidth : (float?)null, Theme.MinTarget);
            card.MinSize(null, Theme.MinTarget - 2f);
            card.GetComponent<VerticalLayoutGroup>().childAlignment = TextAnchor.MiddleCenter;
            shell.Ensure<ControlBorder>();
            Ui.Text(card, label, new TextStyle(fontSize, font), ink, TextAlignmentOptions.Center, false);
            var p = shell.MakePressable(onClick);
            p.Interactable = enabled;
            shell.GetComponent<Image>().raycastTarget = true;
            return shell;
        }
    }
}
