# App Store submission kit

Everything you need to paste into App Store Connect.

## App information

| Field | Value |
|---|---|
| Name | Focus Crew |
| Subtitle (30) | Focus timer & app blocker |
| Category | Productivity (secondary: Health & Fitness) |
| Age rating | 4+ (no objectionable content) |
| Price | Free |
| Bundle ID | `com.focuscrew.app` (change in `Configs/Shared.xcconfig`) |
| Privacy policy URL | https://tomasbeja2007.github.io/focus-mascots/privacy.html |
| Support URL | https://tomasbeja2007.github.io/focus-mascots/support.html |
| Marketing URL | https://tomasbeja2007.github.io/focus-mascots/ |
| Copyright | 2026 Focus Crew |

## Promotional text (170)

Meet Orbit, Spark, Leaf, Pebble and Blob: five tiny companions that block your distracting apps and keep you focused. Free during early access!

## Description

Put your phone down and get things done, with a little help from your friends.

Focus Crew pairs you with one of five adorable companions who focus with you, block the apps that steal your time and celebrate every win.

MEET THE CREW
• Orbit, the Focus Companion: calm, steady deep work
• Spark, the Motivation Boost: quick sprints that beat procrastination
• Leaf, the Rest Guardian: real breaks and a phone-free wind-down
• Pebble, the Discipline Coach: strict sessions you can't skip
• Blob, the Progress Tracker: streaks, stats and charts

A quick quiz matches you with the companion that fits how you work. You can switch any time.

BLOCK DISTRACTIONS
• Block apps, whole categories and websites with Apple's Screen Time
• Focus sessions lock your distractions until the timer ends
• Schedules block apps automatically during work, study or bedtime
• Strict mode for the days you need a firm hand
• Blocked apps show a friendly reminder from your crew

FOCUS WITH A FRIEND
• Beautiful focus timer with breaks and ambient sounds (rain, ocean, brown noise)
• Live Activity on the Lock Screen and in the Dynamic Island
• Home Screen and Lock Screen widgets
• Start sessions from Control Center, Siri or Shortcuts
• Mac companion that shows your session right next to the notch

WATCH YOURSELF GROW
• Daily focus goal, streaks and a weekly chart
• See your screen time and top apps
• 16 badges to collect
• Grow your bond level with your companion

PRIVATE BY DESIGN
No account. No ads. No tracking. Your Screen Time data never leaves your iPhone, and not even we can see which apps you block.

Everything is free during early access.

## Keywords (100)

focus,timer,app blocker,screen time,pomodoro,productivity,study,habit,detox,block apps,deep work

## What's new (1.0)

Welcome to Focus Crew! Meet your companion, block your distractions and start your first focus session.

## App Privacy (nutrition label)

Choose **Data Not Collected**. The app has no analytics, no accounts and no servers. Screen Time data is processed on device by Apple's frameworks; the optional Mac sync uses the user's own iCloud key-value storage.

## App Review notes

> Focus Crew uses Apple's Screen Time API (FamilyControls, ManagedSettings, DeviceActivity) with the Family Controls (Distribution) entitlement to let people block their own distracting apps during focus sessions and on schedules. Authorization uses `.individual` mode.
>
> How to test:
> 1. Complete onboarding (about 2 minutes). On "Let Pebble guard your apps", tap Connect Screen Time and approve.
> 2. On "Which apps distract you?", choose a few apps or a category such as Social.
> 3. On the Focus tab, tap Start focusing. Opening a blocked app shows the Focus Crew shield.
> 4. The Live Activity appears on the Lock Screen and in the Dynamic Island.
> 5. Blocks tab: create a schedule from a template to test recurring blocking.
>
> No account or login is required. All features are free; there are no in-app purchases in this version. Background audio is only used to play the optional ambient focus sounds during a session.

## Screenshots

CI renders every screen on an iPhone 17 Pro simulator (`ci/screens.txt`); the images land on the `ci-screenshots` branch. Recommended set (6.9" and 6.3"):

1. `ob-welcome`: "Meet your Focus Crew"
2. `home`: "Focus with a friend"
3. `session`: "Block distractions while you work"
4. `live-activity`: "Your crew on the Lock Screen"
5. `insights`: "Watch your focus grow"
6. `crew`: "Five companions, one goal"
7. `widgets`: "Widgets for every screen"

## Before you submit

- [ ] Request the **Family Controls (Distribution)** entitlement for the app *and every extension*: https://developer.apple.com/contact/request/family-controls-distribution (development builds work without it).
- [ ] Set `DEVELOPMENT_TEAM` and your bundle IDs in `Configs/Shared.xcconfig`.
- [ ] In the Apple Developer portal, enable App Groups (`group.com.focuscrew.app`), Family Controls, iCloud (key-value storage) and Time Sensitive Notifications on the App IDs (Xcode's automatic signing does this for you).
- [ ] Turn on GitHub Pages (Settings › Pages › Deploy from branch › `main` › `/docs`) so the privacy and support URLs work.
- [ ] Archive the `FocusCrew` scheme (Product › Archive) and upload. Archive `FocusCrewMac` separately for the Mac App Store.
