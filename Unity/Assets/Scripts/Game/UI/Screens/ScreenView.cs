using UnityEngine;

namespace Blackjack.Game.UI
{
    /// <summary>One full screen. Built once, then refreshed in place as the state changes.</summary>
    public abstract class ScreenView
    {
        protected readonly GameController G;
        protected readonly Overlays Overlays;
        public RectTransform Root { get; protected set; }

        protected ScreenView(GameController controller, Overlays overlays)
        {
            G = controller;
            Overlays = overlays;
        }

        public abstract void Build(RectTransform parent);
        public abstract void Refresh(AppState state);

        /// <summary>Called every frame while the screen is showing (animations, countdowns).</summary>
        public virtual void Tick() { }

        public virtual void Dispose()
        {
            if (Root != null) Object.Destroy(Root.gameObject);
        }
    }
}
