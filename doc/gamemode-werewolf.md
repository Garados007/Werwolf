# Game Mode: Werewolf

This game mode is draft and under development

## Role template \<name>

\<info>

**Fraction:**

- \<fractions...>

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| |  | x | x | x |

**required phases:**

- \<phases>

**default visible for:**

- \<list>

**voting’s:**

\<details>

**game finished, winner:**

\<details>

## Werewolf

the werewolf is the main enemy in this game

**Fraction:**

- werewolf

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| werewolf | night: werewolf | x | x | x |
| werewolf | * ||||

**required phases:**

- night: werewolf

**default visible for:**

- werewolf

**voting’s:**

In the phase night: werewolf a voting in the chat werewolf would be created. Targets are all living villagers. Only werewolves are enabled to vote.
If a single target is selected, then this target is flagged. If more targets have the highest score, than a smaller voting is created with only those targets.

If the day changes to day, then the flagged target would be killed. If no flagged target exists, then nothing happens.

**game finished, winner:**

The wolves can only win, if they are the last fraction alive.

## Villager

The villager is everyone in the village even the wolves.

**Fraction:**

- villager
- pure villager (if villager is the only role the player has)

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| village | 1st day: major | x | x | x |
| village | day: village | x | x | x |
| village | * | | | |

**required phases:**

- day: major (only on first day)
- day: village

**default visible for:**

- everyone with role villager

**voting’s:**

1st day major: A voting is in chat village created. the living villager choose one major from all living villagers. If more than one selected then the voting restarts with the selected ones as targets. The target get the role major.

all day village: A voting in the chat village would be created. The living villager choose one victim from all living villagers. If more than one target is selected, then the voting restarts with the selected ones as targets. Only the major can vote in the restarted voting (if no major exists, then the whole living village can vote).
The selected target would be flagged as a victim. If the victim has a special role he performs his action. If he doesn't have a special role, so the victim is killed.

**game finished, winner:**

The game is finished if only pure villagers are left.

## Major

This special role can only be given from the villagers

**Fraction:**

- no real fraction

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| kill | night: night kill (only if player was killed at night) | x | x | x |
| kill | day: day kill (only if player was killed at day) | x | x | x |
| kill | * | | | |

**required phases:**

- day: village

**default visible for:**

- everyone

**voting’s:**

if the village has in day: village in room village more than one target selected, than a new voting would be created. Only the major can vote one. Thus, only one major exists only one victim can be selected now.

If a major would be killed a new voting starts. All living villagers except the major are targets. The major selects one as the next major. The current major loses its role as major.

**game finished, winner:**

Nothing special

## Seeress

This player can see the roles of other players.

**Fraction:**

- village

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| seeress | night: seeress | x | x | x |
| seeress | * | | | |

**required phases:**

- night: seeress

**default visible for:**

- seeress

**voting’s:**

every night the seeress can select one of the villagers except herself and death ones. All roles of the selected ones are revealed to the seeress. If more than one seeress exists, than they can reveal roles of only one player. The seeress can select a player twice but this has no special effect.

**game finished, winner:**

Seeress can only win if village wins.

## Hunter

The hunter can kill any player if the hunter itself was killed

**Fraction:**

- village

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| kill | night: night kill (only if hunter was killed) | x | x | x |
| kill | day: day kill (only if hunter was killed) | x | x | x |
| kill | * | | | |

**required phases:**

- night: night kill (only if hunter was killed)
- day: day kill (only if hunter was killed)

**default visible for:**

- hunter

**voting’s:**

If the hunter was killed he can select any living villager except himself and can kill him. If this player has a special effect than its effect starts immediately.

If a second one with special effect is in the same phase killed, then this phase restarts.

**game finished, winner:**

Can only win if village wins.

## Cupid

The cupid selects two amorous in the first night. Their lives are now connected together.

**Fraction:**

- village

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| cupid | 1st night: cupid | x | x | x |
| cupid | * | | | |

**required phases:**

- night: cupid (only first night)

**default visible for:**

- cupid

**voting’s:**

In the first night cupid select two players in two voting’s. In the first voting cupid can select any villager. In the second any villager except the first selected one. Both gets the role amorous.

If more than one cupid exists nothing special happens. Everyone votes for the first and second one together. If more than one is selected in one voting, than this voting restarts with the selected ones as targets.

**game finished, winner:**

cupid can only win if village wins.

## Amorous

They only exist two players with amorous or none at the same time.

The lives of the amorous player are connected together. If one player dies, the other player dies immediately.

**Fraction:**

- amorous (only if the amorous player belongs to different fractions)

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| amorous | 1st night: amorous | x | x | x |
| amorous | * | | | |

**required phases:**

- night: amorous (only 1st night)

**default visible for:**

- cupid
- amorous

**voting’s:**

nothing special

**game finished, winner:**

if only the amorous players are left, then the amorous players win

## Witch

The witchcraft has two potions. Each of them only once in the game. One potion can heal the victim from the wolves. The other one can kill any other player.

**Fraction:**

- village

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| witch | night: witch  | x | x | x |

**required phases:**

- night: witch

**default visible for:**

- witch

**voting’s:**

Heal potion: This voting has only one target - the victim from the wolves. If the witch selects this player, she lost her potion and the victim is saved (remove flag). If she doesn't select any, she can use her potion in the next round.

Kill potion: In this voting are all living villager except the witch and the wolf target targets. If one of them is selected he becomes flagged and killed later.

If a witch vote in any of these voting’s she lose the ability to vote here again (stored in extra user info).

If multiple witch exists this happens:

- Every witch loose the heal potion if used (they can only heal one)
- Every top selected player was killed, no extra voting
- Every witch that select the top selected player lose their potion, the other witches keep theirs

**game finished, winner:**

Can only win if village win

## Little Girl

The little girl can watch the round of the wolves (but cannot vote). She is invisible to the wolves.

**Fraction:**

- village

**Chatrooms:**

| Chat room | phase | read | write | visible |
|--|--|:--:|:--:|:--:|
| werewolf | night: werewolf | x |  |  |
| werewolf | * | | | |

**required phases:**

- night: werewolf (only if other werewolves exists)

**default visible for:**

- girl

**voting’s:**

No voting’s

**game finished, winner:**

Can only win if village win.
