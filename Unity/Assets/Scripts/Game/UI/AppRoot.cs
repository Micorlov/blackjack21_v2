using System;
using System.Collections.Generic;
using Blackjack.Core;
using UnityEngine;
using UnityEngine.UI;

namespace Blackjack.Game.UI
{
    /// <summary>
    /// Hosts the screens: shows the one the state names, keeps the bottom navigation, toasts and overlays,
    /// and routes the Android back button. Screens are built lazily and kept, so tabs switch instantly.
    /// </summary>
    public sealed class AppRoot : MonoBehaviour
    {
        private UiRoot _ui;
        private GameController _g;
        private Overlays _overlays;
        private ToastLayer _toasts;
        private RectTransform _screenHost, _navHost;
        private Dyn _nav;
        private readonly Dictionary<AppScreen, ScreenView> _screens = new Dictionary<AppScreen, ScreenView>();
        private AppScreen? _shown;
        private AppState _state;
        private bool _rebuildForLanguage;

        public GameController Controller => _g;
        public UiRoot Ui => _ui;

        /// <summary>Builds the whole UI under <paramref name="ui"/> and wires it to <paramref name="controller"/>.</summary>
        public static AppRoot Attach(UiRoot ui, GameController controller)
        {
            var app = ui.gameObject.AddComponent<AppRoot>();
            app._ui = ui;
            app._g = controller;
            app.Build();
            return app;
        }

        private void Build()
        {
            var column = Blackjack.Game.UI.Ui.VStack(_ui.Safe, 0, null, TextAnchor.UpperCenter, true, "Shell").Fill();
            _screenHost = Blackjack.Game.UI.Ui.Node("Screens", column);
            _screenHost.Flex();
            _navHost = Blackjack.Game.UI.Ui.VStack(column, 0, null, TextAnchor.UpperLeft, true, "Nav");
            _navHost.Ensure<LayoutElement>().flexibleHeight = 0;
            _nav = new Dyn(_navHost);

            _overlays = new Overlays(_ui.Overlay);
            _toasts = new ToastLayer(_ui.Overlay);
            _g.OverlayBack = () => _overlays.CloseTop();
            _g.Changed += OnState;
            Loc.Changed += OnLanguageChanged;
            OnState(_g.State);
        }

        private ScreenView Create(AppScreen screen) => screen switch
        {
            AppScreen.Onboarding => new OnboardingScreen(_g, _overlays),
            AppScreen.Lobby => new LobbyScreen(_g, _overlays),
            AppScreen.Table => new TableScreen(_g, _overlays),
            AppScreen.Stats => new StatsScreen(_g, _overlays),
            AppScreen.Friends => new FriendsScreen(_g, _overlays),
            AppScreen.Settings => new SettingsScreen(_g, _overlays),
            _ => throw new ArgumentOutOfRangeException(nameof(screen)),
        };

        private void OnState(AppState s)
        {
            _state = s;
            if (_shown != s.Screen)
            {
                if (_shown.HasValue && _screens.TryGetValue(_shown.Value, out var old)) old.Root.gameObject.SetActive(false);
                _overlays.CloseAll();
                if (!_screens.TryGetValue(s.Screen, out var view))
                {
                    view = Create(s.Screen);
                    view.Build(_screenHost);
                    _screens[s.Screen] = view;
                }
                view.Root.gameObject.SetActive(true);
                _shown = s.Screen;
            }
            _screens[s.Screen].Refresh(s);
            _toasts.Apply(s);
            RefreshNav(s);
        }

        private void RefreshNav(AppState s)
        {
            var show = s.Screen != AppScreen.Table && s.Screen != AppScreen.Onboarding;
            _navHost.gameObject.SetActive(show);
            if (!show) return;
            _nav.Update($"nav{s.Screen}|{Loc.Code}", host => BuildNav(host, s.Screen));
        }

        private void BuildNav(RectTransform host, AppScreen current)
        {
            var bar = Blackjack.Game.UI.Ui.Card(host, Theme.NavSurface, 0, null, 0, Blackjack.Game.UI.Ui.Pad(4, 8, 4, 8), 0, true, "NavBar");
            var line = Blackjack.Game.UI.Ui.Box(bar, Theme.Border, 0, "TopLine");
            line.rectTransform.IgnoreLayout();
            line.rectTransform.PinTop(1);
            var row = Blackjack.Game.UI.Ui.HStack(bar, 0, null, TextAnchor.MiddleCenter, true);
            NavItem(row, AppScreen.Lobby, "home", Loc.Or("navHome", "Home"), current, _g.GoLobby);
            NavItem(row, AppScreen.Stats, "bar_chart", Loc.Or("navStats", "Stats"), current, _g.GoStats);
            NavItem(row, AppScreen.Friends, "people", Loc.Or("navFriends", "Friends"), current, _g.GoFriends);
            NavItem(row, AppScreen.Settings, "settings", Loc.Or("navSettings", "Settings"), current, _g.GoSettings);
        }

        private static void NavItem(RectTransform row, AppScreen screen, string icon, string label, AppScreen current, Action onTap)
        {
            var active = current == screen;
            var color = active ? Theme.TextPrimary : Theme.TextFaint;
            var item = Blackjack.Game.UI.Ui.VStack(row, 4, Blackjack.Game.UI.Ui.Pad(0, 6), TextAnchor.MiddleCenter, false, "Item_" + screen);
            item.FlexW();
            W.Icon(item, icon, 24, color);
            Blackjack.Game.UI.Ui.Text(item, label, 12, color, active ? FontKind.SoraBold : FontKind.SoraSemiBold, TMPro.TextAlignmentOptions.Center, false);
            item.MakePressable(onTap);
        }

        // Direction, alignment and every label depend on the language, so a language change rebuilds the whole UI.
        private void OnLanguageChanged() => _rebuildForLanguage = true;

        private void RebuildForLanguage()
        {
            _rebuildForLanguage = false;
            _overlays.CloseAll();
            foreach (var view in _screens.Values) view.Dispose();
            _screens.Clear();
            _shown = null;
            _nav.Invalidate();
            for (var i = _navHost.childCount - 1; i >= 0; i--) Destroy(_navHost.GetChild(i).gameObject);
            OnState(_g.State);
        }

        private void Update()
        {
            if (_rebuildForLanguage) RebuildForLanguage();
            if (_shown.HasValue && _screens.TryGetValue(_shown.Value, out var view)) view.Tick();
            _toasts?.Tick();
            // Android's back button arrives as Escape. At the lobby there is nothing left to close: leave the app.
            if (Input.GetKeyDown(KeyCode.Escape) && !_g.HandleBack()) Application.Quit();
        }

        private void OnDestroy()
        {
            Loc.Changed -= OnLanguageChanged;
            if (_g != null) { _g.Changed -= OnState; _g.OverlayBack = null; }
        }
    }
}
