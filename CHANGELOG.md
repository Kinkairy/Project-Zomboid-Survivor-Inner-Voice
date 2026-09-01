# Changelog

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
