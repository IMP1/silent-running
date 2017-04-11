# RoadMap

### mvp
  - [X] move square around
  - [X] have other player(s) move other square(s) around
  - [X] have single level with terrain across network.

## 0.1.0
<sup>the mvp branch done</sup>

This is the Minimum Viable Product. It's something playable that can then be iterated upon.

### core/stealth
  - [ ] have terrain and other squares only draw on passive pings (and fade out)
  - [ ] implement silent running (everything invisible but with active pings)

### core/levels
  - [ ] procedurally generated levels (have cheat code to see the terrain)
      * terrain
      * starting positions

### core/battle
  - [ ] have torpedos be firable.
  - [ ] have torpedos damage the player (and cause a noise?)

## 0.2.0
<sup>all the above core/* branches done</sup>

This is the core game. The basic mechanics are implemented.

### core/winloss
  - [ ] win conditions on all enemies destroyed
  - [ ] loss condition on submarine being destroyed

### core/lobby
  - [ ] option to start game or join game

## 0.3.0
<sup>all the above core/* branches done</sup>

### juice/movement
  - [ ] have player movement feel good

### juice/impact
  - [ ] have hitting an enemy feel good (screenshake?)
  - [ ] have being hit by an enemy feel bad (screenshake!)

## 0.4.0
<sup>all the above juice/* branches done</sup>

This is an improved version of the core game, but still with placeholder assets.

### polish/input
  - [ ] configurable keybindings
  - [ ] game controllers working

### polish/graphics
  - [ ] slick graphics

### polish/audio
  - [ ] atmospheric sound effects
  - [ ] minimal soundtrack

### polish/menu
  - [ ] title screen
  - [ ] settings
  - [ ] better looking lobby
  
### polish/localisation
  - [ ] refactored internationalisation
  - [ ] English 'translation'

## 1.0.0
<sup>all the above polish/* branches done</sup>

This is the finished game, releasable.

# Ideas

## Map Features
  * something that the submarine can traverse through, but pings bounce off (seaweed?)
  * fish/aquatic mammals
  * mines (explosive)
  * ping mines
  * depth charges (for firing down)
