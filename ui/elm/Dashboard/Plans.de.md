# Admin Dashboard

## Aufbau

Vom Prinzip her ähnlich zum Spiel selbst. Es gibt eine Vielzahl an Projekten, welche eine Vielzahl an Rubriken enthält.
Diese Aufteilung erfolgt schon im Menu selbst. Das Menu ist bei breiten Bildschirmen fest links angedockt, bei
Mobilgeräten wird es überlagert und ausgeblendet.
Die Leiste, die beim Spiel die einzelnen Lobbys enthielt wird mit Funktionen gefüllt.

```text
+--------------------------+----------------------------------------------------+\
| [ Add Module ]           |  [ Util 1 ]   [ Util 2 ]    [ Util 3 ]             |\
| v  Test Module           +----------------------------------------------------+\
|    > Info                |                                                    |\
|    > Roles               |                                                    |\
|    > Logic               |                                                    |\
|    > Language            |                                                    |\
|    > Test                |                                                    |\
| >  Game Module 1         |                                                    |\
| >  Game Module 2         |                                                    |\
|                          |                                                    |\
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
```

```text
+--------------------------+------------------+\
| [=] Menu                 |\ [ Util 3 ]  [=] |\
+--------------------------+\-----------------+\
| [ Add Module ]         |=|\                 |\
| v  Test Module         |=|\                 |\
|    > Info              |=|\                 |\
|    > Roles             |=|\                 |\
|    > Logic             |=|\                 |\
|    > Language          |=|\                 |\
|    > Test              | |\                 |\
| >  Game Module 1       | |\                 |\
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
```

Zusätzlich gibt es noch eine Footerleiste, die ein paar wichtige Informationen enthält:

- Information zur aktuell geöffneten Seite
  - Name, Projekt
- Speicher- und Syncstatus
- Servershortcuts
  - Maintenance mode
  - Rebuild (extra Seite)
  - DB Viewer

## Sicherheit

Die Pakete selbst werden nicht extra verschlüsselt (dies soll per Https sowieso der Fall sein). Stattdessen werden diese verifiziert.
Dazu werden 2 Faktoren berücksichtigt:

- Pakethash, Jsonstring des Pakets per MD5 gehasht
- Passwort

Der Trick dahinter ist einfach: Du Nutzer wird von der Oberfläche nach dem Passwort gefragt, dies verbleibt aber im Browser und wird nie übertragen.
Stattdessen wird es genutzt, um per AES den Pakethash zu verschlüsseln. Der Server überprüft diese Angabe und akzeptiert oder verwirft diese.
Bei AES wird permanent der Seed verändert, damit auch zwei gleiche Pakete immer unterschiedliche Werte erhalten.

Damit soll es schwerfallen, dass andere sich hier einklinken. Prinzipiell erlaubt der Server die Verwendung mehrere Passwörter und probiert diese
dann nach und nach aus.

Der Server darf unter keinen Umständen Daten herausrücken, falls der Token ungültig ist. Falls einmal ein Token ungültig ist, so wird sofort
die aktuelle Session in der Datenbank hinterlegt, damit sich versuchte Manipulation später besser nachweisen lässt. Dadurch wird es später
einfacher Blacklisten zu erstellen.

## Funktionen

### Module hinzufügen

Module lassen sich per Belieben erstellen und anlegen. Dazu wird ein Ordner unter `/modules` erstellt. Falls gewünscht, kann auch ein Github Repository geclont werden. Dann werden dessen Daten dort entpackt und eingebunden. Andernfalls wird einfach ein leeres Projekt erstellt.

Ein Modul lässt sich auch später zu Github hinzufügen. Die Erkennung erfolgt einzig und allein darauf, ob der Ordner `.git` existiert. Falls es ein GitHub Projekt ist, lässt es sich auch im Nachhinein aktualisieren.

### Modulinfo

Hier werden allgemeine Informationen und Optionen für ein Modul angeboten. Dazu zählen der Modulname, Modulbeschreibung und die Import- und Versionsdaten.

Falls es sich hier um ein Github Projekt handelt, so lässt es sich hierüber aktualisieren.

Wenn der Server sich im Maintenance Mode befindet, so kann das Modul gebaut und veröffentlich werden. Das heißt, alle notwendigen Dateien werden aus dem Projekt erstellt und in den Spieleserver eingebunden. Unter Umständen wird auch die Ausführung der Setup-Routine empfohlen.

Zusätzlich lässt sich hier ein Optionsmenü für die Spielerstellung konfigurieren. Die Werte aus den Optionen können schließlich bei der Logik genutzt werden.

Ein extra Kapitel nehmen die Spielphasen ein. Hierüber wird der eigentliche Ablauf des Spiels bestimmt.

### Rollen

Hier werden einfach die Rollen angelegt und verwaltet. Die Rollen bekommen hier auch ihre Logik versehen. Dazu gibt es einen einfachen Codebuilder, der es einem sicher erlaubt die Logik zu erstellen, ohne schwer zu debuggenden Fehler zu erstellen.

Die Rollen an sich können in unterschiedliche Kategorien eingeteilt werden: Verwaltung und Spielerrollen. Die Verwaltungsrollen bekommen die Spieler normalerweise nicht zu Gesicht und können auch selbst dem Spielleiter verborgen werden. Manchmal stellen sie nur bestimmte Zustände da, z.B. ob man noch bestimmte Fähigkeiten hat oder nicht. Hierüber wird es der Logik leicht erlaubt an den Nutzern bestimmte Informationen zu hängen.

Die Spielerrollen dienen mehr dazu um die Spieler an sich zu identifizieren. Diese geben die hauptsächliche Rollenverteilung bekannt und die lassen sich auch bei einer Spielerstellung vom Spielleiter verteilen.

Eine besondere Art von Verwaltungsrollen sind die Fraktionen: Hierrüber lassen sich Spieler einer Gemeinschaft zuordnen. Das macht vor allem dann Sinn, wenn es darum geht zu ermitteln, wer gewonnen hat.

In der Rollenverwaltung nimmt auch ein zentrales Element die Sichtbarkeit dieser an. Über einer Matrix lässt sich einstellen, welche Rolle welchem Spieler von Anfang an sichtbar sein sollte. Über Programmlogik lässt sich diese Sichtbarkeit auch im Nachhinein ändern.

Außerdem lässt sich hier festlegen welche Rollen welche Phasen benötigen. Dadurch lässt sich der Spielablauf dynamisch an den Phasen anpassen.

### Logik

Hier wird die Programmlogik aus dem Kapitel **Rollen** eingestellt.

### Language

Jedes Modul erlaubt es seine eigenen Sprachpakete mitzuliefern. Im fertigen Build existiert für jede Sprache und Modul nur eine Sprachdatei. So etwas lässt sich leider nur sehr schwer für einen Nutzer verwalten. Von daher wird das hier je nach Anwendungsgebieten aufgeteilt:

- Modulname, -beschreibung
- Rollennamen, -beschreibung
- Chatname
- Votingnamen
- Dialoge (der Logik ist es erlaubt bestimmte Nachrichten abzusenden)
- Optionen
- Spielphasen

Ein einfaches Übersetzungstool erlaubt einem eine schnelle manuelle Übersetzung der einzelnen Einträge.

### Tests

Die Test werden anhand der Rollenlogik im Browser ausgeführt. Dazu gibt es zwei hauptsächliche Kategorien von Tests: Manuell und automatisch. Bei automatischen Tests wird durch zuvor festgelegten Szenarien der Test durchgeführt und verglichen, ob auch der erwartete Wert herauskommt. Für die Tests wird generell mit Seeds für zufällige Sachen gearbeitet, weshalb die sich immer reproduzieren lassen.

Manuelle Tests erfordern dagegen mehr Arbeit. Hier muss zuerst eine Umgebung definiert werden, die bestimmt mit welchen Daten der Test arbeitet. Dann wird bestimmt welche Ereignisse in welcher Reihenfolge auftreten würden. Die Oberfläche gibt dann zu jeden Schritt an, wie sich der Zustand ändern würde. Dem Nutzer ist es somit überlassen, zu ermitteln, ob das gewünschte herauskommt oder nicht.

Es ist relativ einfach aus einem manuellen Test einen automatischen zu erstellen. Dazu wird einfach nur npch zusätzlich angegeben, wie der Zielzustand aussehen müsste. Der automatische Test meldet somit, ob die Tests Erfolg versprechend sind oder nicht.

Genauso gut lässt sich aus einem automatischen einen manuellen Test erstellen, hierzu muss gar nichts mehr gemacht werden, da alle Daten schon vorhanden sind.

## Dateiprototypen

### Projektdatei

Die Projektdatei wird im JSON Format hinterlegt und zur Verfügung gestellt. Ein grober Entwurf wäre wie folgt:

```json
{
    "version": "1.0",
    "name": "testmodule",
    "author": "anonymous",
    "license": "CC0",
    "comment": "demo module configuration",
    "roles": [
        {
            "key": "leader",
            "type": "user",
            "comment": "required user",
            "initCanView": [
                "leader"
            ],
            "reqPhases": [
                "d:voting"
            ],
            "leader": true,
            "fraction": null,
            "canStartNewRound": true,
            "canStartVotings": true,
            "canStopVotings": true,
            "permissions": {
                "d:voting": {
                    "main": {
                        "read": true,
                        "write": true,
                        "visible": true
                    }
                }
            },
            "winTogether": [],
            "canVote": {
                "main": []
            }
        }
    ],
    "rolesets": [
        {
            "key": "villager",
            "roles": [ "villager", "fvillage" ]
        }
    ],
    "phases": [
        {
            "key": "voting",
            "day": true,
            "comment": "Voting round",
            "start": true
        }
    ],
    "chats": [
        {
            "key": "main",
            "comment": "Main talk chat",
            "clearPermissions": true
        }
    ],
    "options": {
        "chapter": "options",
        "box": []
    }
}
```

### Logikdatei

Die Logikdatei enthält alle Logiken zu einer Rolle. Die Logiken sind nach verschiedenen Szenarien eingeteilt und bieten daher unterschiedliche Eingaben und Ausgaben an. Innerhalb eines Szenarios können unterschiedliche Bausteine genutzt werden, um den Code zu repräsentieren. Die Bausteine sind streng typisiert. Die Typen werden nach Typklassen verarbeitet. Und Generika sind auch erlaubt.

Die Typen werden als Liste eingeteilt: `["Type1", "Type2"]`. Normalerweise hat diese Liste ein Element. Falls es mehrere hat, so ist der Typ generisch und erlaubt, dass einzelne Element `null` sein dürfen. Hier kann jeder beliebige Typ eingesetzt werden.
Ist die Liste leer `[]`, so hat dies keinen Typ und darf nicht als Rückgabewert verwendet oder zugewiesen werden (`if` Statement hätte sowas z.B.).

Außerdem gibt es eine interne Liste, zu der sich Typen in Gruppen zusammenfassen lassen. Nur Eingaben lassen sich veralgemeinern. Ausgaben lassen sich nicht nicht spezialisieren.

| Gruppe | Spezialiserte Typen |
|-|-|
| `num` | `int`, `float` |
| `concatable` | `int`, `float`, `string` |
| `comparable` | `int`, `float`, `string`, `bool`, `PlayerId` |
| `string` | `RoleKey`, `PhaseKey`, `ChatKey`, `VotingKey` |

```json
{
    "onStartRound": {},
    "onLeaveRound": {},
    "needToExecuteRound": {},
    "isWinner": {},
    "canVote": {},
    "onVotingCreated": {},
    "onVotingStops": {},
    "onGameStarts": [],
    "onGameEnds": []
}
```

#### onStartRound

*Grouped by `phase`.*

| Parameter | Typ | Beschreibung |
|-|-|-|
| `round` | `['int']` | Die aktuelle Nummer der Spielrunde |

Wird immer aufgerufen, falls eine Runde vom bestimmten Type gestartet wurde.
Geeigneter Zeitpunkt um Votings zu erstellen.

#### onLeaveRound

*Grouped by `phase`.*

| Parameter | Typ | Beschreibung |
|-|-|-|
| `round` | `['int']` | Die aktuelle Nummer der Spielrunde |

Wird immer aufgerufen, falls eine Runde vom bestimmten Type beendet wurde.
Geeigneter Zeitpunkt um Votings zu löschen.

#### needToExecuteRound

*Grouped by `phase`.*

| Parameter | Typ | Beschreibung |
|-|-|-|
| `round` | `['int']` | Die aktuelle Nummer der Spielrunde |

Wird aufgerufen, um zu bestimmen ob die Runde ausgeführt werden soll. Dieser Code ersetzt die Logik, die in den Projekteinstellungen (`true`/`false`) stattgefunden hatte.

#### isWinner

*Grouped by `role`.*

Wird aufgerufen, um zu entscheiden, ob man doch noch gewonnen hat. Dieser Code ersetzt die Logik, die sonst durch die Projekteinstellungen stattgefunden hätte.

#### canVote

*Grouped by `room`,`name`.*

Wird aufgerufen, um zu entscheiden, ob man berechtigt ist zu wählend. Der Code ersetzt die Logik, die sonst durch die Projekteinstellungen stattgefunden hätte.

#### onVotingCreated

*Grouped by `room`,`name`.*

Löst Aktionen aus, wenn ein Voting an sich erstellt wurde.

#### onVotingStarts

*Grouped by `room`,`name`.*

Löst Aktionen aus, wenn ein Voting vom Leiter gestaret wurde.

#### onVotingStops

*Grouped by `room`,`name`.*

| Parameter | Typ | Beschreibung |
|-|-|-|
| `result` | `['list',['tuple','PlayerId','int']]` | Die aktuellen Ergebnisse des Votes |
| `voter` | `['dict','PlayerId',['list','PlayerId']]` | Die Leute die gewählt haben. |

Löst Aktionen aus, wenn ein Voting beendet wurde.

#### onGameStarts

| Parameter | Typ | Beschreibung |
|-|-|-|
| `round` | `int` | Die aktuelle Runde (sollte immer 0 sein) |
| `phase` | `PhaseKey` | Die aktuelle Phase (sollte immer die Startphase sein) |

Löst Aktionen aus, wenn ein Spiel gestarted wurde.

#### onGameEnds

| Parameter | Typ | Beschreibung |
|-|-|-|
| `round` | `int` | Die aktuelle Runde (sollte immer 0 sein) |
| `phase` | `PhaseKey` | Die aktuelle Phase (sollte immer die Startphase sein) |
| `teams` | `['list','RoleKey']` | Alle Rollen, die jetzt gewonnen haben |

Löst Aktionen aus, wenn ein Spiel beendet wurde.

## Codeblöcke

Jeder Codeblock hat eine Liste von Eingaben und maximal eine Ausgabe. Dann wird während der Arbeit etwas ausgeführt. Codeblöcke können selbst wieder eine oder mehrere Bereiche für Codeblöcke enthalten.

Die inneren Bereiche stellen wieder eine Liste an Variablen zur Verfügung. Im Gegensatz zur Sektion können hier die Variablennamen geändert werden. Die Typen bleiben aber bestehen. Die inneren Bereiche können eine Rückgabe besitzen. Diese Variable wird gleich am Anfang des Bereiches festgelegt. Jede Zuweisung setzt also dessen Wert. Diese Variable hat aber den speziellen Effekt, dass von ihr **nicht** gelesen werden kann.

Codeblöcke besitzen die Fähigkeit die Typen der Variablen je nach Eingabe anzupassen.

Eine besondere Eigenschaft besitzt der Typ `VarName`. Vom Prinzip her ist das nichts anderes als ein Zeiger auf eine Variable. Sofern der Typ vom Zeiger mit dem Ziel übereinstimmt oder sich anpassen lässt, lässt sich der Zeiger setzen. Andernfalls darf der Zeiger nicht genutzt werden. Manche Zeiger sind nur les- oder schreibbar. Selbstdefinierte Variablen können beides. Falls ein Codeblock explizit einen `VarName` verlangt, so dürfen **nur** `VarName` Zeiger gesetzt werden.

### set-to

| Parameter | Typ | Beschreibung |
|-|-|-|
| `input` | *a* | Eingabewert |
| `output` | `['VarName',a]` | Ausgabevariable |
| *return* | `[]` | Rückgabe |

Setzt eine Benutzerdefinierte Variable. Falls die Variable nicht existiert, wird sie erstellt. Der Typ der Variable lässt sich nach Definition **nicht** ändern.

### math

| Parameter | Typ | Beschreibung |
|-|-|-|
| `a` | `['num']` | Wert a |
| `operator` | `['Operator']` | Operator. Es steht nur die unten aufgelisteten Möglichkeiten zur Auswahl |
| `b` | `['num']` | Wert b |
| *return*  | `['num']` | Rückgabe |

Berechnet eine mathematische Operation. Sobald beide Eingabetypen feststehen, wird der Ausgabetyp automatisch angepasst.

| Operator | Beschreibung |
|-|-|
| `+` | Addition |
| `-` | Subtraktion |
| `*` | Multiplikation |
| `/` | Division |

### compare

| Parameter | Typ | Beschreibung |
|-|-|-|
| `a` | `['comparable']` | Wert a
| `operator` | `['Operator']` | Operator. es stehen nur die unten aufgelisteten Möglichkeiten zur Auswahl |
| `b` | `['comparable']` | Wert b |
| *return* | `['bool']` | Rückgabe |

Vergleicht zwei Werte miteinander. `a` und `b` haben zwingend den gleichen Typ.

| Operator | Beschreibung |
|-|-|
| `=` | Gleichheit |
| `!=` | Ungleichheit |
| `<` | Kleiner als |
| `<=` | Kleiner gleich |
| `>` | Größer als |
| `>=` | Größer gleich |

### bool-op

| Parameter | Typ | Beschreibung |
|-|-|-|
| `a` | `['bool']` | Wert a
| `operator` | `['Operator']` | Operator. es stehen nur die unten aufgelisteten Möglichkeiten zur Auswahl |
| `b` | `['bool']` | Wert b |
| *return* | `['bool']` | Rückgabe |

Führt eine boolesche Operation aus.

| Operator | Beschreibung |
|-|-|
| `and` | and |
| `or` | or |
| `xor` | xor |
| `nand` | nand |
| `xnor` | xnor |
| `nor` | nor |

### concat

| Parameter | Typ | Beschreibung |
|-|-|-|
| `a` | `['concatable']` | Wert a |
| `b` | `['concatable']` | Wert b |
| *return* | `['string']` | Rückgabe |

Verkettet zwei Strings zueinander.

### list-get

| Parameter | Typ | Beschreibung |
|-|-|-|
| `list` | `['list',a]` | Liste |
| `index` | `['int']` | nullbasierte Index |
| *return* | `['maybe',a]` | Rückgabe |

Ruft einen Wert aus einer Liste ab.

### dict-get

| Parameter | Typ | Beschreibung |
|-|-|-|
| `dict` | `['dict',a,b]` | Wörterbuch |
| `key` | `[a]` | Schlüssel |
| *return* | `['maybe',b]` | Rückgabe |

Ruft einen Wert aus einem Wörterbuch ab.

### tuple-first

| Parameter | Typ | Beschreibung |
|-|-|-|
| `tuple` | `['tuple',a,null]` | Tupel |
| *return* | `[a]` | Rückgabe |

Ruft den ersten Wert aus einem Tupel ab.

### tuple-second

| Parameter | Typ | Beschreibung |
|-|-|-|
| `tuple` | `['tuple',null,a]` | Tupel |
| *return* | `[a]` | Rückgabe |

### unwrap-maybe

| Block | Beschreibung |
|-|-|
| `just` | Wert existierte |
| `nothing` | Wert war nicht verfügbar |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `maybe` | `['maybe',a]` | gekappselter Wert |
| `just` | `value` | `[a]` | existierender Wert |
| - | *return* | `[]` | Rückgabe |

Erlaubt es einen maybe zu entpacken und entsprechend darauf zu reagieren.

### if

| Block | Beschreibung |
|-|-|
| `then` | Bedingung traf ein |
| `else` | Bedingung traf nicht ein |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `condition` | `['bool']` | Bedingung |
| - | *return* | `[]` | Rückgabe |

Fallunterscheidung.

### for

| Block | Beschreibung |
|-|-|
| `loop` | Schleife |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `start` | `['num']` | Startwert inklusive |
| - | `step` | `['num']` | Schrittweite |
| - | `stop` | `[]` | Endwert inklusive |
| `loop` | `i` | `['num']` | Aktueller Wert |
| - | *return* | `[]` | Rückgabe |

Führt eine Schleife eine bestimmte Anzahl mal durch. Der Typ der Schleifenvariable passt sich automatisch an den Kopf an. Bei `step` wird geprüft, ob es einen sinnvollen Wert hat.

### while

| Block | Beschreibung |
|-|-|
| `loop` | Schleife |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `condition` | `['bool']` | Bedingung |
| - | *return* | `[]` | Rückgabe |

Führt diese anfangsgeprüfte Schleife solange aus, bis `condition` `false` wird. Es erfolgt eine Überprüfung, ob die Schleife die Ursprungsvariablen von `condition` ändert. Falls es keine Möglichkeit gibt, dass `condition` in der Schleife ungültig werden kann, dann wird dies als Fehler in der Eingabe angesehen.

### break

| Parameter | Typ | Beschreibung |
|-|-|-|
| *return* | `[]` | Rückgabe |

Bricht die nächst höhere Schleife ab. Dieser Befehl darf nur verwendet werden, wenn auch so eine Schleife existiert.

### foreach-list

| Block | Beschreibung |
|-|-|
| `loop` | Schleife |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `list` | `['list',a]` | Liste |
| `loop` | `element` | `[a]` | Eintrag |
| - | *return* | `[]` | Rückgabe |

Iteriert jeden Eintrag aus einer Liste durch und führt den Befehl aus.

### foreach-dict

| Block | Beschreibung |
|-|-|
| `loop` | Schleife |

| Block | Parameter | Typ | Beschreibung |
|-|-|-|-|
| - | `list` | `['dict',a,b]` | Wörterbuch |
| `loop` | `key` | `[a]` | Schlüssel |
| `loop` | `element` | `[b]` | Eintrag |
| - | *return* | `[]` | Rückgabe |

Iteriert jeden Eintrag aus einem Wörterbuch durch und führt den Befehl aus.

### end-game

| Parameter | Typ | Beschreibung |
|-|-|-|
| *return* | `[]` | Rückgabe |

Informiert, dass das Spiel beendet werden soll und setzt die eigene Rolle als Gewinner.

### just

| Parameter | Typ | Beschreibung |
|-|-|-|
| `value` | `a` | Wert |
| *return* | `['maybe',a]` | Rückgabe |

Kappselt einen Wert.

### nothing

| Parameter | Typ | Beschreibung |
|-|-|-|
| *return* | `['maybe',null]` | Rückgabe |

Sagt, dass die Kappselung keinen Wert enthält.

### list

| Parameter | Typ | Beschreibung |
|-|-|-|
| `values...` | `a` | Alle Werte für die Eingabe |
| *return* | `['list',a]` | Rückgabe |

Erzeugt eine neue Liste.

Der Typ richtet sich nach der ersten Eingabe. Falls keine Eingabe existiert, so ist der Typ `null` (beliebig). Dieser Block erweitert sich automatisch, je nachdem wie viele Werte eingebeben wurden.

### put

| Parameter | Typ | Beschreibung |
|-|-|-|
| `list` | `['VarName',['list',a]]` | Die anfängliche Liste |
| `value` | `[a]` | Das neue Element |
| *return* | `[]` | Rückgabe |

Fügt den Wert direkt an das Ende einer bestehenden Liste hinzu.

### get-player

| Parameter | Typ | Default | Beschreibung |
|-|-|-|-|
| `role` | `['maybe',['list','RoleKey']]` | `null` | Alle Spieler müssen diese Rolle haben. |
| `onlyAlive` | `['bool']` | `true` | Ob nur aktuell lebende Spieler gesucht werden sollen. |
| *return* | `['list','Player']` | - | Rückgabe |

Ruft eine Liste von Spielernobjekten ab.

### set-room-permission

| Parameter | Typ | Beschreibung |
|-|-|-|
| `room` | `['ChatKey']` | Der zu setzende Raum |
| `enable` | `['bool']` | Das Betreten ist erlaubt. |
| `write` | `['bool']` | Das Schreiben im Chat ist erlaubt. |
| `visible` | `['bool']` | Man ist selbst im Chat sichtbar. |
| *return* | `[]` | Rückgabe |

Definiert die Zugriffsregeln für einen Chat für alle Mitspieler dieser Rolle. Für diese Matrix sind nur folgende Zustände erlaubt. Andernfalls wird das als Fehler markiert.

| enable | write | visible |
|-|-|-|
| 0 | 0 | 0 |
| 1 | 0 | 0 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

### inform-voting

| Parameter | Typ | Beschreibung |
|-|-|-|
| `room` | `['ChatKey']` | Der Chatraum in dem das ausgelöst wird |
| `name` | `['VoteKey']` | Das Voting, dass erstellt wird. |
| `targets` | `['list','Player']` | Die möglichen Ziele. |
| *return* | `[]` | Rückgabe |

Erstellt ein neues Voting mit der Liste an Zielen. Das Voting ist noch nicht gestartet.

### add-role-visibility

| Parameter | Typ | Beschreibung |
|-|-|-|
| `user` | `['list','Player']` | Die Liste die Einsicht erhalten |
| `targets` | `['list','Player']` | Die Liste deren Rolle aufgedeckt wird |
| `roles` | `['list','RoleKey']` | Die Rollen die aufgedeckt werden |
| *return* | `[]` | Rückgabe |

Ermöglicht den Spielern die Einsicht in die Rollen anderer. Das funktioniert auch nur, wenn die anderen Spieler die Rolle auch zu diesen Zeitpunkt haben.

### filter-top-score

| Parameter | Typ | Beschreibung |
|-|-|-|
| `score` | `['list',['tuple','PlayerId','int']]` | Aktuelle Scoretabelle |
| *return* | `['list','Player']` | Rückgabe |

Filtert die Scoretabelle und gibt alle Spieler zurück, dessen Score maximal ist.

### filter-player

| Parameter | Typ | Beschreibung |
|-|-|-|
| `players` | `['list','Player']` | Liste an zu filterenden Spielern |
| `include` | `['list','RoleKey']` | Liste an Rollen die die Spieler haben müssen |
| `exclude` | `['list','RoleKey']` | Liste an Rollen die die Spieler nicht haben dürfen |
| *return* | `['list','Player']` | Rückgabe |

Filtert die Spieler und sucht alle heraus, dessen aktuelle Rollen die Bedingungen erfüllen.

### player-id

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| *return* | `['PlayerId']` | Rückgabe |

Ruft die Spieler-ID eines Spielers ab.

### player-alive

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| *return* | `['bool']` | Rückgabe |

Ruft ab, ob der Spieler noch am Leben ist.

### player-extra-wolf-live

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| *return* | `['bool']` | Rückgabe |

Ruft ab, ob der Spieler 2 Leben hat, wenn er durch einen Wolf getötet wird.

### player-has-role

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| `role` | `['RoleKey']` | Rolle |
| *return* | `['bool']` | Rückgabe |

Ermittelt, ob der Spieler eine bestimmte Rolle besitzt.

### player-add-role

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| `role` | `['RoleKey']` | Rolle |
| *return* | `[]` | Rückgabe |

Fügt einem Spieler eine Rolle hinzu.

### player-remove-role

| Parameter | Typ | Beschreibung |
|-|-|-|
| `player` | `['Player']` | Spieler |
| `role` | `['RoleKey']` | Rolle |
| *return* | `[]` | Rückgabe |

Nimmt einem Spieler die Rolle wieder weg.
