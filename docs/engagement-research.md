# Playtime and retention for Blackjack 21: what to do, and what not to do

Written 2026-11-17 against branch `feat/1.8.6-consent` (HEAD `54cdb6c`). Research only: no code, test or build was changed for this report.

**Question:** how do we maximise playtime and retention in a free, play-money blackjack game, and in particular which cards or outcomes should the player get?

## 0. Short answer, and one finding you need to read first

1. **Do not decide the cards by player state without telling the player.** Deal fairly, and get retention from pacing, goals, rewards and social hooks.
2. **The shoe is not purely fair today.** The code already contains an undisclosed deal bias, "Comeback dealing" (`Core/Shoe.cs`, `Comeback`; called from `RoundEngine.Deal`). When the hero has fewer than 6 x the table minimum in chips, or has lost the last two hands, the hero's opening hand is the best of three candidate pairs drawn from the top of the shoe instead of one blind pair. It is described in `README.md` (developer docs) but **not in the in-app How to play, Settings, privacy text, store listing or any user-facing string** (I searched `Resources/`, `Scripts/Game/`, `hosting/` and `play-assets/`). So the "honest RNG" baseline in the brief does not hold. That is the single most important finding here, because section 2 ranks exactly this kind of mechanism last.
3. **It is not a small nudge.** In my simulation (section 1.3) the best-of-three opening pair moves the hero from about 43% hand wins and a -1.4% edge to about 60% wins and a +37% edge on those hands, with naturals going from 4.5% to 13%. It is applied to roughly one hand in five or six in normal play, more when short-stacked.
4. **Recommended direction:** keep the deal fair for everyone by default or make the help visible and controllable. Concretely: disclose Comeback dealing in How to play and the Play listing, put it behind a Settings switch (default decided by an A/B test, same wording in every arm), keep it out of the friends' leaderboard scoring, and invest the real retention effort in the non-deck levers in section 3. Plan in section 4.

## 1. What the game does today (read from the code)

### 1.1 Rules and payouts that matter

| Item | Value | Source |
|---|---|---|
| Shoe | 6 decks, Fisher-Yates, reshuffle below 15 cards | `Core/Shoe.cs` |
| Dealer | stands on all 17s | `TableCatalog.DealerHitsSoft17 = false` |
| Natural blackjack | pays 3:2 (`bet * 3 / 2`); both naturals push | `Core/Settlement.cs` |
| Win | 1:1; push returns the bet | `Settlement.cs` |
| Insurance | offered on a dealer ace; half-bet, pays 2:1 | `RoundEngine.cs` |
| Hero options | double, split (one split, pairs only), late surrender (half back, first two cards) | `RoundEngine.cs` |
| Tables | Bronze $25-$500, Silver $100-$1,000, VIP $500-$5,000 | `TableCatalog.cs` |
| Seats | hero plus 4 opponent seats; **hero acts last**, then dealer (1.8.6) | `RoundEngine`, `GameController.Round.cs` |
| Sweet / sweep pot | every opponent seat that busts or loses to the dealer forfeits its bet; the best surviving hand takes the pot. Hero takes it only if the hero won a hand **and** `heroBest >= rivalBest` (ties count). Added to hero net. | `Settlement.cs`, `TablePot.cs` |
| Stack | starts at 1,000 chips (play money, no purchase, no real-money prize) | `README.md` |

### 1.2 Reward, pacing and notification systems that exist

| System | What it does now | Source |
|---|---|---|
| Daily bonus ladder | 24 h cooldown; days 1-6 pay 250, day 7 pays 1,000; a claim within 48 h keeps the ladder | `DailyBonus` |
| Play-day streak | one hand per local calendar day extends it; adds +50 per streak day, capped at 5 days (+250) to the claim | `PlayStreak` |
| Rebuy | below the table minimum, a rebuy to 1,000 every 4 h | `Rebuy` |
| Rewarded ad | +500 chips, optional, once per hour | `AdReward` |
| Break (interstitial) ad | after the tutorial, every 5 hands **and** at least 4 min since the last; waits ~1 s after Next Hand, input blocked until it closes | `AdPacing`, `GameController.Ads.cs` |
| Evening gift (new, 1.8.6) | 20:00 local notification, +500 play chips once per local date, separate from the ladder | `EveningGift`, `GameController.Bonus.cs` |
| Other local notifications | "daily chips ready", "streak ends tonight" (20:00 if a streak is live and unplayed), friend and overtake alerts | `UnityNotifier`, `GameController.Bonus.cs` |
| Review prompt (new, 1.8.6) | after a big win, never in the first 24 h, 30-day cooldown, max 3 | `ReviewPrompt` |
| Social | friends groups by link or code, hourly/daily leaderboard (points = net chips), seats filled by real friends, table chat, referral rewards | `README.md` |
| Tutorial | three coached hands, dealt from the live shoe (not scripted) | `Tutorial.cs` |
| Comeback dealing | see section 0; best of 3 opening pairs when short-stacked or two losses down | `Shoe.cs` |

**Not present:** achievements, missions or quests, a shop, loot boxes, variable-reward chests. `grep` finds none, and `README.md` says "no shop".

### 1.3 What the numbers look like (my simulation, not game telemetry)

I ran a Monte Carlo (`python3`, 400,000 hands per row, 6 decks, dealer stands on 17, simple strategy: double 10/11 against a dealer 2-9, otherwise hit hard totals to 11, hit 12-16 against dealer 7+, hit soft totals to 17, no split, no surrender, no sweep pot, one bet unit, 3:2 naturals). Treat the figures as an approximation of this game's rules, not as measurements.

| Opening hand | Hand wins (incl. naturals) | Naturals | Push | Hand losses | Edge per unit bet |
|---|---|---|---|---|---|
| Blind pair (normal) | 43.2% | 4.5% | 8.6% | 48.2% | -1.4% |
| Best of 3 pairs (Comeback) | 59.8% | 13.2% | 11.1% | 29.1% | +37% |

A rough Markov estimate of how often Comeback is active from the loss-streak rule alone (loss chance 48% normally and 29% under Comeback): about 18% of hands, plus every hand while short-stacked. Blended edge is then roughly +5% per unit bet before the sweep pot, so **the hero is slightly favoured overall once Comeback is counted**. That is fine for play money, but it is not "a fair shoe", and it makes the friends' leaderboard (points = net chips) tilt toward whoever happens to be on a losing run.

The sweep pot adds a second, honest source of upside: with four opponents, at least one seat forfeits most hands (roughly 1 - 0.52^4 = 93% by a coarse estimate), and the hero takes it when winning with the best surviving total. I have not measured how often that happens; the `hand_played` event already carries `swept` (section 4 uses it).

## 2. Options for the deck, ranked by player trust and policy risk

| Rank | Option | Trust | Policy / reputation risk | Verdict |
|---|---|---|---|---|
| 1 | **Fair RNG shoe, no state-dependent dealing** | Highest. Simple to say, easy to audit, matches "learn blackjack" | Lowest | Default recommendation for anything not explicitly labelled |
| 2 | **Disclosed beginner / "lucky table" mode** (a named, opt-in mode with a friendlier deck; the screen and How to play say so) | High if labelled and optional | Low. Nothing is hidden; the player chooses it | Good fit for new players and for the existing Comeback logic, if renamed and exposed |
| 3 | **Disclosed dynamic difficulty** (a visible "Comeback deal / catch-up" setting, or a stated rule such as "after two losses you get the best of three") | Medium-high; players accept catch-up rules in games when they can see them | Low-medium; must be accurate and must not bleed into competitive scoring | Acceptable if disclosed and controllable; this is what Comeback should become |
| 4 | **Undisclosed deck manipulation** (hidden streak-breaking, hidden win-rate targeting, "ghost" loss streaks) | Lowest; it is exactly the story a one-star review writes | **High.** See below | Do not do this. **Comeback dealing, as shipped today without disclosure, is in this bucket**, although it is player-favouring |

Why option 4 is dangerous, specifically:

- **Google Play deceptive behavior.** Play's policies prohibit apps that mislead users or behave differently from how they are presented. A game described as blackjack that quietly changes the deal by player state can be read as that. A mild, player-favouring bias is a smaller risk than a player-hostile one, but "undisclosed" is the problem, not the direction.
- **Simulated gambling expectations.** The game's content-rating and store framing treat it as simulated card gambling with play money. Players and reviewers of that genre expect the odds to be the real ones (casino blackjack math). A hidden bias breaks the one thing the genre promises, and a hostile bias would look like a "rigged" game with an ad-and-reward loop on top.
- **Review backlash.** Blackjack players count cards and track streaks. "It always gives me 20 after I lose twice" is easy to notice and easy to screenshot. Fairness complaints are the main reason casino-style apps get one-star waves.
- **Conflict with the product positioning.** The game says "learn as you play". A tutorial that teaches strategy against a deck that is not the real deck teaches wrong odds: with Comeback, a player who splits, doubles and stands "by the book" sees a 60% win rate on those hands and learns the wrong lesson.
- **Social fairness.** Friends race on net chips. A bias that only helps players who are behind distorts the one number friends compare.

**Do not recommend, and this report does not recommend, secretly rigging the shoe in either direction.**

## 3. What correlates with longer sessions and better retention here

This section separates what I know from this game's code from what is general retention practice. There is **no GA4 data in the repo**, so every claim about what works is a hypothesis to test, not a result.

### 3.1 (a) Card and outcome patterns

What I can ground in the rules:

- **Win-rate pacing is mostly pre-decided by the math.** A normal hand is ~43% win, ~9% push, ~48% loss; with the sweep pot and the 3:2 natural the player-friendly outcomes are more than the headline win rate. Over a 5-10 minute session (about 10-20 hands, since a hand takes 30-40 s with four bots and the hero acting last) the variance is large, so sessions that "feel good" or "feel bad" are mostly luck, not design.
- **Bankroll is not the churn driver.** With 1,000 chips and a $25 minimum, a player has 40 minimum bets; the rebuy (1,000 every 4 h), the rewarded ad (+500 per hour), the daily ladder (250-1,000 plus up to +250 streak) and the evening gift (+500) mean running out is recoverable. The sharper moments are the **gap** between "I ran out" and "next rebuy in 3h 12m", and long unlucky stretches on a table that is too expensive for the stack. `TableRecommendation` already points players to a table their stack covers four times over.
- **Early-session wins.** The three tutorial hands are dealt from the live shoe, not scripted, so the first session can open with three losses at ~11% probability (0.48^3). That is a real churn moment. It can be softened honestly, for example by seating new players at Bronze with the smallest bet pre-selected, by making the coach copy about the process ("good decision") rather than the result, and by showing the sweep pot early because it is a second way to win a hand you lose to the dealer. It does not need a stacked deck.
- **Loss-streak breaking.** Today that is Comeback dealing (hidden). Honest equivalents: a "Comeback bonus" in chips after N losses (visible, small), a suggested lower table or bet after two losses, a visible "take a break" nudge, or a **disclosed** catch-up deal.
- **Comeback moments.** The emotionally strong outcomes in this ruleset are all legitimate: the natural (4.5%, pays 3:2), the double on 10/11, and the **sweep pot**, which turns a modest win into 2-5x the bet. They already trigger celebration and haptics. The cheapest lever is **making them visible and shareable**, not making them more frequent.
- **Sweet Pot frequency.** The pot exists on most hands; the hero collects it on a subset. I would not tune it by dealing. If a **measured** rate looks low, the honest levers are table composition (how many bots are seated), a clearer pot display, and the hero-acts-last change that already helps the hero decide with full information.

### 3.2 (c) Non-deck levers: what exists vs what would be new

| Lever | Exists today | New or to extend |
|---|---|---|
| Daily bonus + 7-day ladder | Yes | Show tomorrow's reward on the lobby; keep the ladder separate from the evening gift |
| Play-day streak | Yes (+50/day to +250) | Optional "streak freeze" earned by play; must not be sold or loss-framed |
| Achievements | **No** | New. Small, skill-framed (first split, 10 sweeps, 5-hand win run), play-chip rewards only |
| Missions / daily goals | **No** | New. 2-3 short daily goals; no timers that punish, no random chests |
| Progressive Sweet Pot | Pot is per hand, from forfeited bets | A visible "pot sits at the table" carry-over would be new and needs design and disclosure |
| Chip refills | Rebuy (4 h), rewarded ad (1 h), daily, evening gift | Surface the next refill time on the table when stack is low (the rebuy countdown exists) |
| Friends race | Yes | A weekly friends board; keep Comeback out of points |
| Notification timing | 20:00 evening gift, 20:00 streak reminder, "daily chips ready" at unlock | **Cap at one scheduled notification per day** (priority: evening gift, then streak, then bonus). Today a player can get three |
| Ad pacing vs churn | Every 5 hands and at least 4 min; none during the tutorial | Test 7-8 hands and "no break ad in the first session". Ads are the most likely churn cost; measure before changing |
| Review prompt | Big win, 24 h in, 30 days, max 3 | Done; keep neutral and official-API-only |

### 3.3 The 8 PM evening gift in context

- It is a fixed, honest, play-chip gift, not a random reward, and it asks for no purchase. That is the right shape.
- Android delivers the alarm inexactly, so it may arrive a few minutes after 20:00 (observed on the emulator).
- It stacks with the streak reminder, which also fires at 20:00. Two notifications in the same minute from one app is a likely opt-out trigger. Merge them: if a streak is live and unplayed, send one notification mentioning both.
- The permission request now follows a won hand after five hands played. Track grant rate; Android 13+ typically has far fewer grants than earlier versions, so the gift will reach only a minority of installs. That is a reason to also show the gift in-app on the lobby (a card "Evening gift ready after 8 PM"), which is not built.
- A local calendar-date key means flying across time zones can occasionally allow two gifts in 24 hours or none for a day. Harmless for play money, but note it in analysis.

## 4. Recommended plan

### 4.1 Principles

1. The deal is fair unless the player can see and control a rule that changes it.
2. Retention comes from goals, pacing, social and rewards; chips are play money and the copy says so.
3. No dark patterns: no variable-ratio chests, no fake scarcity or countdowns, no loss-framed guilt, no hidden difficulty, no reward for ratings.
4. Measure first; every change below ships behind a flag and is A/B tested.

### 4.2 Steps (in order)

1. **Resolve Comeback dealing (before any new growth work).** Pick one: (a) remove it; (b) rename it "Comeback deal", describe it in How to play, the Play listing description and the privacy/help text ("after two losses or when your stack is low, your opening hand is the best of three"), add a Settings switch, and exclude comeback hands from the friends' leaderboard points. I recommend (b), with the default decided by the test below, because it keeps the value for newer players without hiding it.
2. **Instrument.** Add the events in 4.3. Two weeks of baseline with no changes.
3. **Fix the cheap, honest wins.** One notification per day cap (merge evening gift and streak); an in-app "Evening gift" card; early-session gentleness (Bronze, smallest chip pre-selected); a visible chip-refill timer when the stack is low.
4. **Add two small goal systems:** achievements (skill and milestone framed) and 2-3 daily goals, play-chip rewards only, no randomness, no purchases.
5. **Tune ads** after baseline: test 5 vs 8 hands between interstitials and "none in the first session".
6. **Re-read the numbers** and drop anything that raised D1/D7 at the cost of reviews, opt-outs or ad revenue per user.

### 4.3 What to track in GA4

Already logged (from `AnalyticsEvent` and the code): `onboarding_entry_selected`, `onboarding_complete`, `first_hand_completed`, `ten_hands_completed`, `tutorial_completed`, `tutorial_skipped`, `hand_played` (params `result`, `stake`, `net`, `swept`, `blackjack`), `table_entered` (`stake`), `daily_bonus_claimed` (`day`, `reward`), `rebuy`, `ad_reward_earned`, `break_ad_shown`, `invite_shared`, `review_prompted`, `review_request_result`, `evening_gift_claimed`, `notif_permission_asked`. `out_of_chips` (fired when the out-of-chips sheet opens). GA4 supplies `first_open`, `session_start`, and engagement time automatically.

Add:

| Event or parameter | Why |
|---|---|
| `hand_played.comeback` (0/1) and `hand_played.bet` | Needed to measure Comeback's effect honestly, and the real hand outcomes it produces |
| `hand_played.hands_in_session`, `session_hand_index` | Hands per session without custom BigQuery work |
| `session_summary` on pause (hands, net, minutes, tables) | Session shape; flags "left while losing" vs "left while winning" |
| `loss_streak` at lengths 3, 5, 8 | Loss-streak churn |
| `rebuy_blocked` (countdown shown), and the stack size on `out_of_chips` | Dry-spell churn |
| `evening_gift_shown`, `notif_tap` (source), `notif_permission_result` | Gift funnel, permission grant rate |
| `notif_toggle` (Daily reminder off/on) | Opt-out guardrail |
| User properties: `variant_*`, `days_since_install`, `notif_granted` | Cohort cuts |

Core metrics: session length (engagement time per session), hands per session, sessions per user per day, **D1 / D7 retention by calendar day** (as `docs/growth/README.md` defines it), activation funnel (first open to entry to table to first hand to ten hands), rewarded-ad opt-in rate, ad impressions per DAU, review velocity and rating, notification opt-outs.

### 4.4 A/B tests (Firebase)

**What exists:** feature flags are booleans in the Firestore document `config/features`, read through `ISocialService.LoadFeatureFlags` (`FeatureFlag.ReviewPrompt = "reviewPromptEnabled"`, `ReferralRewards = "referralRewardsEnabled"`). A missing flag means on. They are global on/off switches. **Firebase Remote Config is not wired in code** (no use found), so experiments with variants need Remote Config plus the Firebase A/B Testing console added, or a deterministic bucket from the Firebase installation id on top of the Firestore flags. Both are small additions; do not change Remote Config defaults without a flag for it.

| Parameter (Remote Config key) | Variants | Tests |
|---|---|---|
| `comeback_default` | on / off. A Settings switch with **identical text in every arm**; only the default differs | Whether the disclosed catch-up deal improves D1/D7 and session length |
| `evening_gift_hour` | 20 / 19 / 21 (and `evening_gift_chips` 500 / 250) | Best notification time and reward size |
| `notif_cap` | 3 notifications / 1 merged per day | Opt-out and retention trade-off |
| `break_ad_hands` | 5 / 8 (and `first_session_no_ads` on/off) | Ad pressure vs D1/D7 and revenue per user |
| `daily_goals_enabled`, `achievements_enabled` | off / on | New goal systems (once built) |
| `new_player_table_hint` | off / "start at Bronze" | Early-session experience |

**Design:**

- Unit: new installs (Firebase installation id), 50/50 split, randomised once, sticky for the life of the install. One experiment per surface; do not stack experiments on the same cohort.
- Primary metrics: D1 retention, D7 retention, and mean engaged minutes in days 0-7. Secondary: hands per session, sessions per day, rewarded-ad opt-in.
- Guardrails (stop and investigate on a regression): crash-free users, rating and review velocity, notification opt-out rate, ad impressions per DAU, support or review-text complaints about fairness.
- Sample size (assumptions, replace with the measured baseline): with D1 around 28%, detecting +3 points at 80% power and alpha 0.05 needs about 3,500 installs per arm; D7 around 8%, detecting +1.5 points needs about 5,100 per arm. At low install volume run one experiment at a time, longer, and accept only large effects.
- Run length: at least 14 days after the last cohort enters, so D7 is fully observed; only fully observed cohorts count (as in `docs/growth/README.md`).
- Success criteria written before launch: ship a variant only if the primary metric improves with the interval clear of zero **and** no guardrail worsens beyond its pre-agreed bound. A `comeback_default` result that raises D1 but lowers review rating or raises fairness complaints is a fail.
- Honesty rule for every arm: the copy the player sees must be true for that arm. Never test an undisclosed difference in the deal.

## 5. Caveats

- All performance numbers in section 1.3 come from my own simulation of a simplified strategy and the printed rules (no split, surrender or sweep pot); they are an estimate of the shape, not telemetry from the game.
- Retention baselines (D1 28%, D7 8%) are assumptions for sample sizing, not data from this app.
- I did not measure how often the hero takes the sweep pot; log it before drawing conclusions.
- Comeback dealing's exact trigger is the code in `Shoe.cs` at HEAD; the README describes it as "so sessions last longer", i.e. it was added as a retention mechanic.
- Store-policy statements are summarised at the level of the published principles (deceptive behavior, simulated-gambling content rating); check the current Play policy text and the app's content-rating questionnaire before shipping a disclosure change.
