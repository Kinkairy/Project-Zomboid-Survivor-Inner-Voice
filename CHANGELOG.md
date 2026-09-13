# Changelog

## 0.3.5

- Frequency and vanilla-prompt sandbox changes now take effect for existing characters after the game synchronizes them.
- Future remaining waits are rescaled to the new frequency without rerolling randomness or clearing pending state and phrase history.

## 0.3.4

- Recovery lines now describe the remaining level, including full recovery and skipped levels.
- Every frequency merges outdated transitions; the queue is bounded by the 26 states and no longer sorted each scan.
- Corrected English recovery prose and cross-language meaning; made six food-related thoughts more natural.
- All six locale files are generated and checked against one complete trilingual catalog.
- Clarified that same-state reminder protection does not suppress new symptom changes.

## 0.3.3

- Fixes vanilla state prompts to the original `Small` halo font and darkens
  them to neutral gray RGB `(170,170,170)`; character-thought font size remains
  configurable and defaults to `Medium`.
- Adds the default-on `Show vanilla state prompts` sandbox option. Disabling it
  filters vanilla title/description slots before phrase selection, so normal
  thoughts continue without blank triggers or changed cooldowns.
- Renames the existing font setting to `Inner-voice font size` to make its
  scope explicit. The renderer, scheduler cadence, state reads, translations,
  and official Moodle icon path remain otherwise unchanged.

## 0.3.2

- Routes custom character lines through the vanilla halo-note renderer so full
  vanilla Moodle texture paths are accepted and the matching icon is visible;
  the character-chat renderer only accepts four hard-coded image names.
- Adds a `Small / Medium / Large / Massive` sandbox font setting, defaulting to
  Medium and applying to both system prompts and character thoughts.
- Displays vanilla system prompts as neutral-gray `<text>` with no icon or
  attempted italics, avoiding unsupported Chinese glyphs and font variants.
- Leaves two literal spaces before a character thought's official Moodle
  foreground texture so the icon no longer touches the final character.
- Replaces the uncommon Traditional Chinese variant `喫` with the familiar
  `吃` in all custom lines.
- Keeps the original halo anchoring, lifetime, outline/background, state
  scheduling, and texture loading; no custom font, renderer, queue, or icon
  asset is added.

## 0.3.1

- Keeps vanilla Moodle titles, descriptions, and special-state labels in the
  existing phrase rotation while displaying them as white official halo
  prompts prefixed by `※`, without arrows or parentheses.
- Keeps original character thoughts in the existing colored dialogue bubble
  channel without parentheses and appends the matching vanilla B42 Moodle icon.
- Reuses the game's built-in image markup and Moodle textures; no custom icon
  assets or renderer are added. Non-Moodle special states do not receive a
  fabricated icon.
- Does not add extra messages, scans, timers, queues, localization copies, or
  changes to state detection and scheduling.

## 0.3.0

- Covers 25 directly perceptible negative conditions plus the positive
  `FoodEaten` state, with 98 reachable state-and-severity groups.
- Adds separate reactions for a state appearing, worsening, improving, and
  fully clearing.
- Uses the game's own title and description for applicable vanilla phrase
  slots, then provides multiple original variants with matching meaning.
- Rewrites the Simplified Chinese corpus as natural self-talk instead of
  mechanical status announcements, while preserving Traditional Chinese and
  English localization.
- Colors negative reactions from pale red to deep red and positive or fully
  recovered reactions from pale green to deep green using the player's current
  vanilla highlight colors.
- Keeps one five-value frequency dropdown, randomized timing, an initial quiet
  period, recent-line avoidance, and a three-second minimum safety interval.
- Preserves every severity change in `Very Frequent` mode for observation and
  debugging; other modes keep only the latest pending change per state.
- Excludes hidden infection data and does not modify character stats, actions,
  items, world state, zombie attraction, or save data.
