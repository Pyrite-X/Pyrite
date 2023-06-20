## **How does Pyrite's fuzzy matching work?**

Pyrite's fuzzy matching works through a percentage that you set when configuring the bot.
By default this percentage is at 100%, meaning that no fuzzy matching happens.

At any value other than 100% (minimum 75%, max 100%), Pyrite uses the [string_similarity](https://pub.dev/packages/string_similarity) package, which checks the similarity of two strings based on [Dice's Coefficient](https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient).

The bot then decides to remove the user or not based on the found similarity. It is important to not set the similarity % too low, since that can result in more potential false-positives.

My personal rule of thumb is to set the percentage at 85% and have the bot log some alerts for a while, or run a scan where matches will only be logged. 

Based on that output I'd personally decide if it seems like there are a bunch of false positives or not, and if there is I would raise the percentage. If not, I would leave it as is. If there are not as many matches I was expecting, I would consider lowering.


<br>

## **How does Pyrite's rule matching work?**

The rule matching feature only has two types. Absolute matching and RegEx pattern matching.

Absolute matching, as it sounds, only matches names that exactly match the entire pattern/string given when setting up the rule. This means that if I have a pattern "Nub" but my name is "Nu", that rule will not match.

RegEx matching, alternatively, allows a user to make custom rules that will be matched against. This can be used to create partial matches, match against a certain name suffix or prefix, and more. It requires much more testing though, and must be carefully used to prevent overzealous matching.

A popular site that I like to use to check RegEx patterns is [Regex101](https://regex101.com/). Dart uses RegEx patterns that match JavaScript's flavor, aka ECMAScript, so be sure to set that on the site as the flavor used.
