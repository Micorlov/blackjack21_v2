using System;
using Blackjack.Game.Services;

namespace Blackjack.Game
{
    /// <summary>
    /// Where optional integrations plug in. The Firebase assembly only exists when the Firebase SDK has been
    /// imported (see <c>Unity/tools/install_firebase.sh</c>); it registers itself here before the game starts, and
    /// without it the game runs offline with practice bots.
    /// </summary>
    public static class ServiceFactories
    {
        public static Func<ISocialService> Social = () => new NullSocial();
        public static Func<IAnalytics> Analytics = () => new NullAnalytics();
        public static Func<IReviewPrompter> Review = () => new NullReview();
    }
}
