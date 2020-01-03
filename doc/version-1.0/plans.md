# Version 1.0

After almost 4 years of development, many experiments, fails and success I plan to release my first version 1.0. For this the whole project get a new facelift. 

During the major changes that will happen it could be that the backward compability will be destroyed. But I will try my best to restore old games.

The following are the main steps that will be changed/added/ or whatever:

## GraphQL API

The REST Api is dead. It is realy difficult to maintain, not flexible, new features costs plenty of time, and syncronisation is slow. For the old Api I have written so much Elm and PHP code. It is a real monster! It works but it isn't nice because I need several requests to get the data I need. The server could know what I need and bundle it, but this take extra endpoints. I created multi request endpoints to batch many requests - but this isn't nice too.

For the GraphQL API I have only one endpoint and the UI can tell the server what it needs and sends everything at once. New features can be added easily.

For that purpose I selected the following librarys. I will try to change it to them in time.

- PHP side: [https://github.com/webonyx/graphql-php](https://github.com/webonyx/graphql-php)
- Elm side: [https://github.com/dillonkearns/elm-graphql](https://github.com/dillonkearns/elm-graphql)

## Easier Database Access

The second part of the project that consumes to much time is the database access. For that I have handwritten many classes, methods and so on. Prety much redudancy. It is not easy to extend or change something here.

For the future I want to take use of my project: [https://github.com/Garados007/DataLayout](https://github.com/Garados007/DataLayout). This will reduce the work from this side and make this port of project more easy to manage.

## Online Workbench

I want to create an online tool to manage the background of the projects. This are some of the features this will provide (some are explained later in detail):

- setup the server
- change configuration
- load and setup external modules
- manage existing games
- create character logic
- sandbox

## Game charater logic

A small thing in the project code but a realy big thing to debug: the game character logic. I got so many bugs in there in past. Some bugs are found months later or never (but the bugs are experienced during the game).

Therefore an editor will be added to the online workbench. This will reduce the most stuff or errors and make testing easier.

For the design I have done some experiments but this is not realy finished.

## Sandbox

A realy great thing for testing this monster. It is realy painful to do this by hand. The sandbox should contain an automatic test feature to test againt predefined use cases.

The sandbox should entirely work in Elm and shouldn't rely on the server. Therefore it must be guaranteed that everything works in the sandbox as like as work on a real server.

## Modules

A new module system should be introduced that can provide lots of features like game modes, character definitions, sprites and so on. The main package will provide only a small debug module (deactivated on a runtime system) and a basic module. 

The modules come from git (Github, Gitlab), ZIP or is provided directly. 

Modules can provide own data for the database but this will be handled as extensions of existing types (new types that inherits the basic type).

Therefore modules are required to be build with the main configuration.

## New Setup system

Until now the setup is a single script that will be executed at once. Because my main websever only supports php (and no git, npm, ...) I was required to build partialy on another computer and upload the created stuff.

The new setup system should support 3 modes:

- **Normal Build**: The current machine is suitable to build and is used as the runtime server.
- **Build Server**: The current machine is for building only and should bundle all the stuff the runtime needs for its execution.
- **Runtime Build**: The current machine cannot build anything and is only for the server. This build will only unpack the stuff from the build server and finish the stuff.

Finaly the setup will be splitted in different phases. Because most php environments has an execution time limit and the build could become more time consuming. The steps depends on the selected build mode and are executed in order by the build manager.

The build could also be managed by the online workbench or command line. But the first build has to be done via command line (because the online workbench is not builded).

Additionaly I plan to add a build pipeline to automaticly submit the build package from the build server to the runtime build. But for this there is more security required (no manipulation from outside).

## LESS CSS Preprocessor

To write the styles in css is a little difficult. In future I want to use a php implementation of a less css preprocessor [https://github.com/leafo/lessphp](https://github.com/leafo/lessphp). 

These files will also precompiled during the setup routine.

## Reorganisation of the repository paths

The paths will be reorganised in a better logical structure. Currently the different projects are somehow merged and are not realy separated.

## Result

If I look at the main changed above there will be pretty much changed. The whole php code will be reorganized and restructed. Most parts of it will be replaced. The DB system will be completly replaced and now managed through a separated system. The ui get a complete new network logic. The setup system will be completly replaced. And a new online workbench will be created.

As result the whole project will be changed.

But after these changed I will accept it as my first main version of this project.

## Develop

First I want to make some plans and refine my decissions. A new branch `develop-version-1` will be created and completly restructed.

Because this is my hobby free time project this will take some time. I hope I can finish these changes at the end of 2020.

The old tickets will not be deleted. Instead new ones will created.