# Werwolf

> In favour of https://github.com/Garados007/Werewolf is this project no longer developed and maintained. Any suggestions and ideas can be implemented there. The official live server of this project will be closed down in near future.

This hobby project of mine is a web implemantion of one of my favorite games: Werwolves of Millers Hill (in german Werwölfe von Düsterwald). In this project I will experiment a lot and currently it is partly playable.

At this time I prepare the next step to the first public release `1.0`. My plans for it you can find [here](https://github.com/Garados007/Werwolf/blob/master/doc/version-1.0/plans.md).

## What about this project?

- it is possible to create, join and manage groups
- the player can write chats in this groups
- the game can be managed (phases, ...)
- victims, group leader can be selected
- much more

## What are future plan?

- implement different game modes
- add admin dashboard to control the platform
- add a game mode with a full list of all public roles
- easy role editor
- public stats
- better homepage
- much more

## What is the main idea behind this project?

The server part runs on a central apache web server and all clients use the webpage to access this game with their webbrowser.
All communications are done via text chat. Currently there is no idea how to manage voice chats (it was discussed to use third party apps like discord, teamspeak or skype but all of them doesn't meet the requirements). The game itself is controled by the game leader.

## Requirements

- Apache Webserver >= 2.4
- Php >= 7.2 
- Elm 0.19
- MySQL
- external user authentification (not managed by the project itself)

## Installation

A list of detailed steps are avaible in the wiki.

# Problems and Errors

Create a ticket and write all important stuff to it. If you want you can fork this project and extend features on your own. Good and helpfull submits will be included in this project.
