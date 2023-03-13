## Pyrite
Pyrite is your next anti-phishing Discord bot for removing users who mimic popular Discord bots!

By default, this is done through matching a person's username or nickname to a name of a well known Discord bot, as defined [here](https://github.com/Pyrite-X/Bot-List).

Along with this, there is an included rule system, allowing you to remove any users from your server who may match that rule.

---
###  Invite
Are you interested yet? If so, check out the bot for yourself!

**[Invite Pyrite!](https://discord.com/api/oauth2/authorize?client_id=1022370218489692222&permissions=1374926720198&scope=bot%20applications.commands)**

---
### Self Hosting
Although I would much appreciate if you use the hosted version instead, it is possible to self-host Pyrite!

Pyrite is fully self contained in Docker files, but it requires you to build it yourself. A `docker-compose.yml` is included in the repository which can be used to run all the necessary services (other than MongoDB) for the bot.

The docker compose is setup so that it can work with Portainer, so the environment file is expected to be named `stack.env`. Make sure to change this if you don't want your env file to be named `stack.env`. 

To run the bot then, clone this repository to your local system, and create a file named `stack.env` in the root of the cloned directory. <br> - You can base this off of the example env file in `bin/example.env`. <br> - With this docker compose setup, your redis host variable will be `redis`, and the port number can be the default port for Redis.

Before you can run the bot, you will need a MongoDB instance that you can connect to, with the connection URL set accordingly in your .env file. This is up to you to setup.

Then do `docker compose up -d` which will start downloading the necessary containers, and building the ones that need to be built. From there, the bot should be fully self contained and running! Other than for the database, which you will need a MongoDB instance for.

Pyrite receives interactions via HTTP POST requests, rather than over the gateway. Because of this, you will need to have your port for the `pyrite_http` container published. This port by default is 8008, but can be changed by modifying `bin/pyrite_http.dart` and the `docker-compose.yml` accordingly. 
> Interactions are recieved on `/ws` rather than root, so for example `127.0.0.1:8008/ws`, if there was a domain it would be `example.com:8008/ws`, would be the URL to put into the endpoint URL on Discord.

---
### Donations
If Pyrite has helped you or your server, please send a donation my way! <br> I have no integrations for payments or premium upgrades at this time, so any money will give me motivation to keep the bot up-to-date for all to use! (Along with my desire to simply improve the community, but money helps me cover hosting costs!)

There are no methods at this time to donate though, so unless you're really keen on donating, please hold onto your money lol.
