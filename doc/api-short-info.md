# Short information about the API

## Get information about the current state

### Get all informations about all users from a group

**Returned Informations:**
- User
- UserStats
- Player
- Role (filtered)

**Require update after:**
- startup
- new day started
- voting completed
- game finished
- some time intervall:
    - last online check

**Approximated Json data:**
```json
[
    {
        "group": <int>,
        "user": <int>,
        "stats": {
            "userid": <int>,
            "firstGame": <int?>,
            "lastGame": <int?>,
            "gameCount": <int>,
            "winningCount": <int>,
            "moderatedCount": <int>,
            "lastOnline": <int>,
            "aiId": <int?>,
            "aiNameKey": <string?>
            //aiControlClass is dropped
        },
        "player": {
            "id": <int>,
            "game": <int>,
            "user": <int>,
            "alive": <bool>,
            "extraWolfLive": <bool>,
            "vars": <any[]>,
            "roles": [
                {
                    "roleKey": <string>,
                    "index": <int>
                }
                //roles are always filtered and only
                //visible ones are listed
            ]
        }
    }
]
```

### Get all informations about a group

**Returned Informations:**
- Group
- GameGroup

**Require update after:**
- startup
- enter group
- some time intervall:
    - day/phase check
    - game started check
    - game finished check

**Approximated Json data:**
```json
{
    "id": <int>,
    "name": <string>,
    "created": <int>,
    "lastTime": <int?>,
    "creator": <int>,
    "leader": <int>,
    "enterKey": <string>,
    "currentGame": { //optional
        "id": <int>,
        "mainGroupId": <int>,
        "started": <int>,
        "finished": <int?>,
        "phase": <string>,
        "day": <int>,
        "ruleset": <string>,
        "winningRoles": <string[]?>,
        "vars": <any[]>
    }
}
```

### Get all Informations about a chatroom

**Returned Informations:**
- ChatRoom
- ChatPermission
- VoteSetting

**Require update after:**
- startup
- new day started
- voting completed
- some time intervall:
    - vote start check
    - vote finished check

**Approximated Json data:**
```json
{
    "id": <int>,
    "game": <int>,
    "chatRoom": <string>,
    "permission": { //calculated for current user
        "enable": <bool>,
        "write": <bool>,
        "visible": <bool>,
        "player": <int[]> //other player in room
    },
    "voting": [ //contains only elements when enabled
        {
            "chat": <int>,
            "voteKey": <string>,
            "created": <int>,
            "voteStart": <int?>,
            "voteEnd": <int?>,
            "enabledUser": <int[]>,
            "targetUser": <int[]>,
            "result": <int?>
        }
    ]
}
```

### Get all Informations about a chat entry

**Returned Informations:**
- ChatEntry

**Require update after:**
- startup
- some time intervall:
    - new items

**Approximated Json data:**
```json
[
    {
        "id": <int>,
        "chat": <int>,
        "user": <int>,
        "text": <string>,
        "sendDate": <int>
    }
]
```

### Get all Informations about votes in a voting

**Returned Informations:**
- VoteEntry

**Require update after:**
- startup
- some time intervall:
    - changes

**Approximated Json data:**
```json
[
    //requires enable permission in ChatPermission
    {
        "setting": <int>,
        "voteKey": <string>,
        "voter": <int>,
        "target": <int>,
        "date": <int>
    }
]
```

## Convenient getter for information about current state

the convenient functions reduces the date for periodicaly calls to the api.

### Get LastOnline from users

**input:**
- group id

**process:**
- get the last online information from each user in the group

**output (approximated):**
```json
[
    //for each user as (userId, lastOnline)
    [<int>, <int>]
]
```

**normal workflow:**
- fetch all users from a group
- read `result[index].stats.lastOnline`

### Get Updated Group

**input:**
- group id
- lastChange as time stamp
- leader id
- phase, day (optional)

**process:**
- checks each time field of the group or currentGame if its newer

**output (approximated):**
nothing changed: `null`
something changed: `<complete group data>`

changes are:
- new game started (`result.lastTime`)
- leader changed (`result.leader`)
- currentGame added (`result.currentGame.started`)
- currentGame finished (`result.currentGame.finished`)
- phase changed (`result.currentGame.phase`, `result.currentGame.day`)

**normal workflow:**
- just fetch normal data
- more data to transport and check on client

### Get changed votings

**input:**
- game id
- lastChange as time stamp

**process:**
- checks each voting in the chats if some has newer fields

**output (approximated):**
```json
[
    //each changed voting
    <votingdata>
]
```

changes are:
- new voting created (`created`)
- voting started (`voteStart`)
- voting ended (`voteEnd`)

Finished votings exist until a new phase starts with one exception:
A finished voting can be replaced by a newer one with the same key. The client get a new voting (`created`) with the same key as the old one. This method is usefull to propagate changes from the other fields.

**normal workflow:**
- fetch all chatrooms
- determine changes in this chatrooms

### Get new Chat Entrys

**input:**
- chat id
- lastChange as time stamp

**process:**
- search for newer chats

**output (approximated):**
List of chat entrys

**normal workflow:**
- fetch all chat entrys
- search for newer ones

### Get new votes

**input:**
- vote setting id + vote key
- lastChange as time stamp

**process:**
- search for newer votes

**output (approximated):**
List of newer vote objects

**normal workflow:**
- fetch all votes from voting
- determine newer ones

## Control methods

### Create Group

**permission:**
- everybody
- becomes the new leader of this group

### Join Group

**permission:**
- everybody
- becomes a new member of this group

**actions:**
- if no game exists, nothing happens
- if a game exists:
    - the new user is a guest
    - no player object is created
    - cannot see any roles
    - can see only public chats (story,main)
- next game: normal member

### Start new Game

**permission:**
- need to be group leader
- no game exists

**actions:**
- start game
- game object created
- for each member a player is created
- assign roles
- create chats
- change to first phase
- leader becomes story teller

**transmitted data:**
- game options
- role list

### Change Group Leader

**permission:**
- no game exists
- need to be be group leader
- new leader need to be group member

**actions:**
- change the leader of this group

**transmitted data:**
- new group leader

### Goto next phase

**permission:**
- need to be story teller
- game exists

**actions:**
- finish old votings
- delete old votings
- check for game termination
- change to next valid phase
- update permissions
- create votings

### Post Chat

**permission:**
- need to be a player
- player need to be alive
- require write permission for this chat

**actions:**
- just add chat

**transmitted data:**
- chat content

### Start voting

**permission:**
- need to be story teller
- (can be done automaticly)
- voting exists and is not startet yet

**actions:**
- modify start time of voting

### Finish voting

**permission:**
- need to be story teller
- voting exists and is startet

**actions:**
- set finish time to current time (closed)
- get votes and create a rank
- move the ranking to the scripts (perform actions)
    - create new voting
    - kill player
    - ...

### Vote

**permission:**
- need to be a member of this group
- voting exists and is startet but not finished
- own id is listed in enables of voting
- target id is listed in targets of voting

**actions:**
- add or replace vote

**transmitted data:**
- target id

## Info methods

This methods provides extra data for scripting the different methods

### Installed game types

provides a list of options that can be selected in create game menu.

```json
[
    // for each option name
    <string>
]
```

### Create options

Provides the option configuration for the create menu.

**Global Frame:**
```json
{
    "chapter": <string>,
    "box": [ <box> ]
}
```

**Box:**
```json
{
    //key need to be unique in box
    "key": <string>,
    "type": <type>,
    //this title is appended to this control (depends on its type)
    "title": <string>
    //additional values depends on type
}
```

| type | values | type | description |
|---|---|---|---|
| box ||| add a additional box with different settings |
| | `box` | Box | the data for the sub box (required) |
| desc ||| add a descriptive text, no data is stored in value storage |
| | `text` | string | visible text (required) |
| num ||| a number value input |
| | `min` | number | Minimum value (default `-4294967296`) |
| | `max` | number | Maximum value (default `4294967295`) |
| | `digits` | int | Number of Digits (default `0`) |
| | `default` | number | Default Value (default `0`) |
| text ||| add a text input box |
| | `default` | string | Default value (default `""`) |
| | `regex` | string | Match pattern (default `.*`) |
| check ||| checkbox for options |
| | `default` | bool | Default value (default `false`) |
| list ||| a list of option which one is selectable |
| | `options` | [string,string] | List of options. First entry is the key, second is the visible text (required) |


**Value Storage (submit to server):**
Every box or Frame is a json group. The key value is
the key in the parent group to this group. Values are
putted directly.

For example:
```json
{
    "option1": 16,
    "box1": {
        "option2": "abc",
        "box2": {
            "option3": false
        }
    }
}
```

### Installed roles for a given game type

provides a list of roles for the specific game type

```json
[
    // for each role
    <string>
]
```