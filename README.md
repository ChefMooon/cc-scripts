# cc-scripts

A collection of scripts for Computers and Turtles from [CC:Tweaked](https://modrinth.com/mod/cc-tweaked). 

A small idea I had that got big. Explore at your own risk. Currently Testing and doing a full rewrite.

## Testing
- digOS
- todoOS

## Planned
- mooonOSUpdate(digOSUpdate refactor)
- digOSRemote
- winchOS

## DigOS
This program was designed to enable players without Lua programming knowledge to effectively use Turtles. Shout out PotatoMads.

A GUI provides an interface to do most basic turtle commands as well as call and run other programs with the GUI arguments while sending/receiving updates

Features:
- GUI created with [Basalt](https://github.com/Pyroxenium/Basalt)
- Basic Turtle Controls
    - Turtle Slot Selection
        - can use/place, dig, drop selected slot
        - arrows and buttons 1-16
    - Turtle Refuel
        - 1 item and whole stack from selected slot
    - Turtle Movement
        - selectable distance and option to dig while moving
        - forward, back, up, down, turn left, turn right, shift left, shift right
- Run digOS programs
    - GUI arguments are used to call and run other programs (see data structure below)
        - dig programs are seperate .lua files that can be make to accept the arguments as Args
        - loads all files in the mooonOS/digOS/digPrograms/ directory that start with "digOS-" and end with ".lua"
        - [digOSUtil.lua](https://github.com/ChefMooon/cc-scripts/blob/mooonOS/mooonOS/digOS/digOSUtil.lua) can be used to help encode/decode digOS arguments
    - 5 Preset slots
        - Save, Load, Reset arguments that persist across shutdowns

Note: Paired with digOSRemote on a computer/pocket computer with a wireless router you can connect to and control multiple turtles at once. (pending the digOSRemote refactor)

** Data Structure **
```
digArgs = {
    program,
    command,
    length,
    width,
    height,
    offsetDir,
    torch = {
        torch,
        torchDistance,
        torchSlot
    },
    chest = {
        chest,
        chestSlot
    },
    rts,
    ignoreInventory,
    ignoreFuel,
    noPickup,
    blockWhiteList,
    blockBlackList
}
```

### Screenshots
![home_1](/img/mooonOS/digOS/home_1.png)
![home_2](/img/mooonOS/digOS/home_2.png)
![home_3](/img/mooonOS/digOS/home_3.png)
![home_3](/img/mooonOS/digOS/home_3.png)
![control](/img/mooonOS/digOS/control.png)
![settings](/img/mooonOS/digOS/settings.png)
![info](/img/mooonOS/digOS/info.png)