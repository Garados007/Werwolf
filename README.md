# Werwolf

This is the web implementation of the popular group game Werwolves of Millers Hill. 
This project is not finnished but in parts playable. 

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
