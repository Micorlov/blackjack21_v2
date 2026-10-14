using NUnit.Framework;

namespace Blackjack.Core.Tests
{
    public class ArabicShaperTests
    {
        [Test]
        public void Shape_leavesNonArabicTextAlone() => Assert.AreEqual("Maya 1,250", ArabicShaper.Shape("Maya 1,250"));

        [Test]
        public void Shape_usesIsolatedFormsForSingleLetters() => Assert.AreEqual("ﺏ", ArabicShaper.Shape("ب"));

        [Test]
        public void Shape_joinsALetterToItsNeighbours()
        {
            // ب ب ب : initial, medial, final
            Assert.AreEqual("ﺑﺒﺐ", ArabicShaper.Shape("ببب"));
        }

        [Test]
        public void Shape_doesNotJoinAfterNonJoiningLetters()
        {
            // دب : dal never joins forward, so ب starts a new word — isolated.
            Assert.AreEqual("ﺩﺏ", ArabicShaper.Shape("دب"));
        }

        [Test]
        public void Shape_formsTheLamAlefLigature()
        {
            Assert.AreEqual("ﻻ", ArabicShaper.Shape("لا"), "isolated");
            Assert.AreEqual("ﺑﻼ", ArabicShaper.Shape("بلا"), "joined to a previous letter");
        }

        [Test]
        public void Shape_ignoresDiacriticsWhenDecidingAJoin()
        {
            // بَب : the fatha between the letters must not stop the join.
            Assert.AreEqual("ﺑَﺐ", ArabicShaper.Shape("بَب"));
        }

        [Test]
        public void Shape_handlesASpaceAsAWordBreak()
        {
            Assert.AreEqual("ﺏ ﺏ", ArabicShaper.Shape("ب ب"));
        }
    }

    public class BidiTests
    {
        [Test]
        public void Visual_leavesLeftToRightTextAlone() => Assert.AreEqual("Hello 12", Bidi.Visual("Hello 12"));

        [Test]
        public void Visual_reversesAHebrewWord() => Assert.AreEqual("תירבע", Bidi.Visual("עברית"));

        [Test]
        public void Visual_keepsANumberReadingLeftToRightInsideRtlText()
        {
            // "שלום 125" → the digits stay 125, but the number goes to the left of the word.
            Assert.AreEqual("125 םולש", Bidi.Visual("שלום 125"));
        }

        [Test]
        public void Visual_keepsCurrencyAndSeparatorsWithTheirNumber()
        {
            var visual = Bidi.Visual("שלום $1,250");
            Assert.IsTrue(visual.StartsWith("$1,250 "), visual);
        }

        [Test]
        public void Visual_keepsAnEmbeddedLatinWordIntact()
        {
            var visual = Bidi.Visual("שלום Maya שלום");
            StringAssert.Contains("Maya", visual);
        }

        [Test]
        public void Visual_putsTheFirstLogicalWordOnTheRight()
        {
            // two Hebrew words: the first in reading order ends up on the right.
            var visual = Bidi.Visual("אב גד");
            Assert.AreEqual("דג בא", visual);
        }

        [Test]
        public void Visual_mirrorsBrackets() =>
            Assert.AreEqual("(בא)", Bidi.Visual("(אב)"));

        [Test]
        public void ContainsRtl_detectsHebrewAndArabic()
        {
            Assert.IsTrue(Bidi.ContainsRtl("א"));
            Assert.IsTrue(Bidi.ContainsRtl("ا"));
            Assert.IsFalse(Bidi.ContainsRtl("abc 123"));
        }
    }
}
