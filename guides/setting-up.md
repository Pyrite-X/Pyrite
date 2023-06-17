# **Setting up Pyrite!**


Welcome! You just invited the bot to your server and now you're wondering 
> "What do I do? How does this bot work? Is it going to ban everyone?!?!"

Rest assured, the bot won't do anything off the bat - but here are a few setup steps I recommend when you first invite the bot!

<br>


## **1. Set your log channel!**

The first thing, and one of the most important ones in my opinion, is to set your log channel.

This can be done through the `/config logchannel` slash command.

In addition to the Discord audit logs, setting a log channel will let you easily see what Pyrite does on a regular basis! Don't worry if the channel seems rather empty - that means your server doesn't have any suspicious people!

<br>

## **2. Set the action for Bot list matches!**

As the primary feature of Pyrite, it is important that you set what should happen when people who have usernames which match the names of a bot in the bot list.

This can be set through the `/config bot_list` slash command, and you will need to set the `action` option.

There are a few options available, which are:
- Logging the match
- Kicking the user
- Banning the user
- Logging & Kicking the user
- Logging & Banning the user

<br>

## **2.1 Adjust the fuzzy match percentage (OPTIONAL)**

> If you don't know what the fuzzy match percentage is, see the `main-concepts.md` file [here!](https://github.com/Pyrite-X/Pyrite/blob/main/guides/main-concepts.md)

If you wish to make it so that a name may not have to exactly match a bot name for a match, adjusting the match percentage is a good idea. 

This can also be done through the `/config bot_list` slash command, and you will be setting the `fuzzy_match` option.

Be careful though! The lower the match, the more likely there will be false positives - resulting in the possibility that normal people may be removed! Unfortunately this is due to the nature of fuzzy matching, and can only be avoided by either not kicking or banning users automatically, or by setting a higher percentage.

My recommendation is to start at 90-100%, any lower than that and you should carefully monitor the matches to ensure there aren't false positives.

<br>


## **3. Create some Rules! (OPTIONAL)**

If you want, you can even moderate some people based on some custom rules that you make!

The `main-concepts.md` guide has some good information on what features rules provide [here](https://github.com/Pyrite-X/Pyrite/blob/main/guides/main-concepts.md). 

To create a rule, use the `/rules add` slash command.

The bot will then require two arguments, the first is a `pattern`, which is a fancy way of saying what name you want the rule to match against. The second one is the action you want taken against people who match this rule. 

These are the same actions as listed earlier, so you can log the match, kick or ban the user, or do a combination of logging and kicking or banning the user.

<br>

## **And that's it!**

Pyrite is rather easy to setup and hard to mess up! The worst thing you can do is set your fuzzy percentage too low, which would result in a bunch of false positives! So **don't** do that.

Hopefully this guide helped you in getting started with removing fake bot users in your server!
