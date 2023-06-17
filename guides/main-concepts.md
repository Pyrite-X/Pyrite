# **Learn about some of the concepts behind Pyrite!**

Pyrite works by checking a user's username, display name (if set), and their nickname (also if set). I'll refer to these there as a user's name interchangeably.

It does this either when you run a `/scan`, when users join the server, or when guild members are updated (such as changing their nickname, profile picture, and so on).

## **Checks**

### - **Bot List**

There are two types of checks. The first is referred to as the **bot list**. This list consists of the names of various large bots that exist on Discord, as well as bots that appear to be commonly mimicked.

With bot list checking enabled, Pyrite will compare the name(s) of the user against each of the bots in the list.

### - **Rules**

Alternatively, Pyrite also supports the creation of rules! 

These rules allow you to create custom names or matches in your server that Pyrite will check. 

This means that if I made a rule with a pattern set as Nub, it would match my display name (which is also Nub) and then would moderate me depending on what you set when making the rule.

<br>

---


## **Fuzzy Matching (Bot list only)**

One of the crucial differences between rules and the bot list, is that the bot list supports a feature known as **fuzzy matching**! 

What this means is that Pyrite will match users based on how close their name is to the name of a bot. 

If I configured the fuzzy matching percentage to be 80%, that would mean that if 80% of a user's username matches a bot's name, the bot will consider that a match, and will moderate that user. 

If the fuzzy matching is set to 100%, the bot will only match if the user's name exactly matches the bot name (which is the default action).

<br>

## **RegEx (Rules only)**

Comparatively, Rules support patterns that are regular expressions, or RegEx. This is a powerful way of making custom matches in your server, and requires careful strategizing to make sure you don't accidentally apply the rule to the wrong people.

The type of RegEx that Pyrite supports is ECMAScript.

You can read about RegEx [here](https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html#zz-2.) if you're curious to learn more! But remember, this is a powerful tool & you likely won't need it unless you know what it does!
