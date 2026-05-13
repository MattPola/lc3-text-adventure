;*************************************************************************
; Matteo Coppola
; Description:
;   This program lets the user play a text-based escape room game
;
; Register Usage:
;   R0 reserve for TRAP
;   R1 Garbage register
;   R2 not used
;   R3 not used
;   R4 not used
;   R5 Used to check for program quit
;   R6 not used
;   R7 Reserved for PC
;************************************************************************
    .ORIG x3000
    AND R0, R0, #0
    AND R5, R5, #0
MainLoop

    JSR PrintCurrentRoom
    JSR PrintOptions
    JSR HandleInput
    LDI R5, QUIT_VALUE
    ADD R1, R5, #0
    BRp END
    
    BRnzp MainLoop
    
END    HALT

QUIT_VALUE .FILL QUIT_TRUE
;************************ClearScreen*****************************
;This routine repeatedly prints \n to "clear" screen
;
;R0 - Used to print
;R1 - Used as a loop counter
;R7 - return address from subroutine
;**************************************************************
ClearScreen
    ST R0, ClearR0
    ST R1, ClearR1
    ST R7, ClearR7
    
    LD R0, NEWLINE
    ADD R1, R0, #10 ;Sets counter to print 20 newlines
    
PrintLoop    TRAP x21
    ADD R1, R1, #-1
    BRp PrintLoop
    
    LD R0, ClearR0
    LD R1, ClearR1
    LD R7, ClearR7
    RET

ClearR0 .BLKW #1
ClearR1 .BLKW #1
ClearR7 .BLKW #1
NEWLINE .FILL #10
;**************************************************************
    
;************************PrintCurrentRoom*****************************
;This routine prints out info about current room
;
;R0 - Contains current room number/used for TRAP
;R1 - Temp register used for checking state
;R7 - return address from subroutine
;**************************************************************
PrintCurrentRoom
    ST R0, PrintR0
    ST R1, PrintR1
    ST R7, PrintR7
    
    JSR ClearScreen
    
    LDI R0, ROOM_PTR

;Checks for current room
    ADD R1, R0, #0
    BRz CELL
    
    ADD R1, R0, #-1
    BRz HALLWAY
    
    ADD R1, R0, #-2
    BRz STORAGE
    
    ADD R1, R0, #-3
    BRz OFFICE
    
    ADD R1, R0, #-4
    BRz EXIT

;Prints out info depending on room
CELL LD R0, CellInfoPtr
    TRAP x22
    BRnzp ExitPrint
    
HALLWAY LD R0, HallwayInfoPtr
    TRAP x22
    BRnzp ExitPrint
    
STORAGE LD R0, StorageInfoPtr
    TRAP x22
    BRnzp ExitPrint
    
OFFICE LD R0, OfficeInfoPtr
    TRAP x22
    BRnzp ExitPrint

;Exit has conditional info
EXIT LDI R0, POWER_ON_PTR
    ADD R1, R0, #0
    BRz NoPower
    
    LDI R0, KEYCARD_PTR
    ADD R1, R0, #0
    BRz NoKeycard
    
    LD R0, ExitInfoPtr
    TRAP x22
    BRnzp ExitPrint
    
NoPower LD R0, ExitInfoPowerPtr
    TRAP x22
    BRnzp ExitPrint
NoKeycard LD R0, ExitInfoKeycardPtr
    TRAP x22
    BRnzp ExitPrint
    
    
    

    
    
ExitPrint    LD R0, PrintR0
    LD R1, PrintR1
    LD R7, PrintR7
    RET

PrintR0 .BLKW #1
PrintR1 .BLKW #1
PrintR7 .BLKW #1   
;**************************************************************

;Pointer table for information
POWER_ON_PTR .FILL POWER_ON
KEYCARD_PTR .FILL HAS_KEYCARD

CellInfoPtr .FILL CellInfo
HallwayInfoPtr .FILL HallwayInfo
StorageInfoPtr .FILL StorageInfo
OfficeInfoPtr .FILL OfficeInfo
ExitInfoPowerPtr .FILL ExitInfoPower
ExitInfoKeycardPtr .FILL ExitInfoKeycard
ExitInfoPtr .FILL ExitInfo

    
;************************PrintOptions*****************************
;This routine prints out possible options to execute
;
;R0 - used for TRAP/checking current room
;R1 - Temp register used for checking state
;R7 - return address from subroutine
;**************************************************************
PrintOptions
    ST R7, OptionsR7
    ST R0, OptionsR0
    ST R1, OptionsR1
    
;Prints out map and current room
    LD R0, MapPtr
    TRAP x22
    LEA R0, Current
    TRAP x22

    LDI R0, ROOM_PTR
    ADD R1, R0, #0
    BRz CELL_2
    
    ADD R1, R0, #-1
    BRz HALLWAY_2
    
    ADD R1, R0, #-2
    BRz STORAGE_2
    
    ADD R1, R0, #-3
    BRz OFFICE_2
    
    ADD R1, R0, #-4
    BRz EXIT_2
    

CELL_2 LEA R0, CELL_LABEL
    TRAP x22
    BRnzp Next
    
HALLWAY_2 LEA R0, HALLWAY_LABEL
    TRAP x22
    BRnzp Next
    
STORAGE_2 LEA R0, STORAGE_LABEL
    TRAP x22
    BRnzp Next
    
OFFICE_2 LEA R0, OFFICE_LABEL
    TRAP x22
    BRnzp Next

EXIT_2 LEA R0, EXIT_LABEL
    TRAP x22
    BRnzp Next

;Prints out action options
Next LD R0, OptionsPtr
    TRAP x22
    




    LD R7, OptionsR7
    LD R1, OptionsR1
    LD R0, OptionsR0
    RET
    
OptionsR7 .BLKW #1
OptionsR0 .BLKW #1
OptionsR1 .BLKW #1
;**************************************************************

;More pointers and strings
OptionsPtr .FILL Options
MapPtr .FILL Map
Cell_LABEL .STRINGZ "Cell"
Hallway_LABEL .STRINGZ "Hallway"
Storage_LABEL .STRINGZ "Storage"
Office_LABEL .STRINGZ "Office"
Exit_LABEL .STRINGZ "Exit"
Current .STRINGZ "Current room: "
ROOM_PTR .FILL ROOM


;************************HandleInput*****************************
;This routine handles user input
;
;R0 - used for TRAP
;R1 - Temp register used for checking state
;R7 - return address from subroutine
;**************************************************************
HandleInput
    ST R7, InputR7
    ST R1, InputR1
    ST R0, InputR0
    LEA R0, Question

;Checks for correct input
InputError    TRAP x22
    TRAP x20
    TRAP x21
    LD R1, neg48
    ADD R0, R0, R1
    
    ADD R1, R0, #-1
    BRz MOVE
    
    ADD R1, R0, #-2
    BRz INTERACT
    
    ADD R1, R0, #-3
    BRz INVENTORY
    
    ADD R1, R0, #-4
    BRz QUIT_PROGRAM
    
    LEA R0, QuestionError
    BRnzp InputError
    
    
MOVE JSR MoveRooms
    BRnzp ExitInput
    
INTERACT JSR InteractCommand
    BRnzp ExitInput
    
INVENTORY JSR ShowInventory
    BRnzp ExitInput
    
QUIT_PROGRAM AND R1, R1, #0
    ADD R1, R1, #1
    STI R1, QUIT_PTR

ExitInput    LD R7, InputR7
    LD R0, InputR0
    LD R1, InputR1
    RET
    
InputR7 .BLKW #1
InputR0 .BLKW #1
InputR1 .BLKW #1
;**************************************************************
Question .STRINGZ "What would you like to do? (Enter 1-4) "
QuestionError .STRINGZ "\nInvalid entry, pick a number 1-4 "
neg48 .FILL #-48
QUIT_PTR .FILL QUIT_TRUE

;************************MoveRooms*****************************
;This routine handles movement between rooms
;
;R0 - used for TRAP
;R1 - Temp register used for checking state
;R2 - Holds current direction to check
;R7 - return address from subroutine
;**************************************************************
MoveRooms
    ST R7, MoveR7
    ST R0, MoveR0
    ST R1, MoveR1
    ST R2, MoveR2
    LDI R0, ROOM_PTR

;Checks which room is current room
    ADD R1, R0, #0
    BRz CELL_3
    
    ADD R1, R0, #-1
    BRz HALLWAY_3
    
    ADD R1, R0, #-2
    BRz STORAGE_3
    
    ADD R1, R0, #-3
    BRz OFFICE_3
    
    ADD R1, R0, #-4
    BRz EXIT_3


;HANDLES CELL MOVEMENT
CELL_3 LD R0, CellMoveOptionsPtr
    TRAP x22
CELL_LOOP   TRAP x20
    TRAP x21
    
    LD R2, NORTH
    ADD R1, R0, R2
    BRz CELL_MOVE_NORTH
    LD R0, MoveErrorPtr
    TRAP x22
    BRnzp CELL_LOOP
    
CELL_MOVE_NORTH AND R1, R1, #0
    ADD R1, R1, #1
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE


;HANDLES HALLWAY MOVEMENT
HALLWAY_3 LD R0, HallwayMoveOptionsPtr
    TRAP x22
HALLWAY_LOOP TRAP x20
    TRAP x21
    
    LD R2, NORTH
    ADD R1, R0, R2
    BRz HALLWAY_MOVE_NORTH
    
    LD R2, SOUTH
    ADD R1, R0, R2
    BRz HALLWAY_MOVE_SOUTH
    
    LD R2, EAST
    ADD R1, R0, R2
    BRz HALLWAY_MOVE_EAST
    
    LD R2, WEST
    ADD R1, R0, R2
    BRz HALLWAY_MOVE_WEST
    
    LD R0, MoveErrorPtr
    TRAP x22
    BRnzp HALLWAY_LOOP
    
HALLWAY_MOVE_NORTH  AND R1, R1, #0
    ADD R1, R1, #4
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE

HALLWAY_MOVE_SOUTH  AND R1, R1, #0
    ADD R1, R1, #0
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE

HALLWAY_MOVE_EAST   AND R1, R1, #0
    ADD R1, R1, #3
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE

HALLWAY_MOVE_WEST   AND R1, R1, #0
    ADD R1, R1, #2
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE


;HANDLES STORAGE MOVEMENT
STORAGE_3 LD R0, StorageMoveOptionsPtr
    TRAP x22
STORAGE_LOOP   TRAP x20
    TRAP x21
    
    LD R2, EAST
    ADD R1, R0, R2
    BRz STORAGE_MOVE_EAST
    LD R0, MoveErrorPtr
    TRAP x22
    BRnzp STORAGE_LOOP
    
STORAGE_MOVE_EAST AND R1, R1, #0
    ADD R1, R1, #1
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE


;HANDLES OFFICE MOVEMENT
OFFICE_3 LD R0, OfficeMoveOptionsPtr
    TRAP x22
OFFICE_LOOP   TRAP x20
    TRAP x21
    
    LD R2, WEST
    ADD R1, R0, R2
    BRz OFFICE_MOVE_WEST
    LD R0, MoveErrorPtr
    TRAP x22
    BRnzp OFFICE_LOOP
    
OFFICE_MOVE_WEST AND R1, R1, #0
    ADD R1, R1, #1
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE


EXIT_MOVE    LD R7, MoveR7
    LD R0, MoveR0
    LD R1, MoveR1
    LD R2, MoveR2
    RET


;HANDLES EXIT MOVEMENT
EXIT_3 LD R0, ExitMoveOptionsPtr
    TRAP x22
EXIT_LOOP   TRAP x20
    TRAP x21
    
    LD R2, SOUTH
    ADD R1, R0, R2
    BRz EXIT_MOVE_SOUTH
    LD R0, MoveErrorPtr
    TRAP x22
    BRnzp EXIT_LOOP
    
EXIT_MOVE_SOUTH AND R1, R1, #0
    ADD R1, R1, #1
    STI R1, ROOM_PTR
    BRnzp EXIT_MOVE

MoveR7 .BLKW #1
MoveR0 .BLKW #1
MoveR1 .BLKW #1
MoveR2 .BLKW #1
;**************************************************************

NORTH .FILL #-78
SOUTH .FILL #-83
EAST .FILL #-69
WEST .FILL #-87

;************************InteractCommand*****************************
;This routine handles interacting with objects
;
;R0 - used for TRAP
;R1 - Temp register used for checking state
;R2 - Used to check multiple bools
;R7 - return address from subroutine
;**************************************************************
InteractCommand
    ST R7, InteractR7
    ST R1, InteractR1
    ST R0, InteractR0
    ST R2, InteractR2
    
    LD R0, ROOM

;Checks which room is current room
    ADD R1, R0, #0
    BRz CELL_4
    
    ADD R1, R0, #-1
    BRz HALLWAY_4
    
    ADD R1, R0, #-2
    BRz STORAGE_4
    
    ADD R1, R0, #-3
    BRz OFFICE_4
    
    ADD R1, R0, #-4
    BRz EXIT_4


;HANDLES CELL INTERACT
CELL_4 LD R0, HAS_BATTERY
    ADD R1, R0, #0
    BRp ALREADY_TAKEN
    LD R0, CellIntrPtr
    TRAP x22
    TRAP x20
    AND R1, R1, #0
    ADD R1, R1, #1
    ST R1, HAS_BATTERY
    BRnzp EXIT_INTERACT

;HANDLES HALLWAY INTERACT
HALLWAY_4 LD R0, HallwayIntrPtr
    TRAP x22
    TRAP x20
    BRnzp EXIT_INTERACT

;HANDLES STORAGE INTERACT
STORAGE_4 LD R0, HAS_KEYCARD
    ADD R1, R0, #0
    BRp ALREADY_TAKEN
    LD R0, StorageIntrPtr
    TRAP x22
    TRAP x20
    AND R1, R1, #0
    ADD R1, R1, #1
    ST R1, HAS_KEYCARD
    BRnzp EXIT_INTERACT

;HANDLES OFFICE INTERACT
OFFICE_4 LD R0, HAS_BATTERY
    ADD R1, R0, #0
    BRz NO_BATTERY
    ST R0, HAS_CODE
    ST R0, POWER_ON
    AND R0, R0, #0
    ST R0, HAS_BATTERY
    LD R0, OfficeIntr_POWER_ONPtr
    TRAP x22
    TRAP x20
    BRnzp EXIT_INTERACT

;HANDLES EXIT INTERACT
EXIT_4 AND R2, R2, #0
    LD R0, POWER_ON
    ADD R2, R0, R2
    LD R0, HAS_KEYCARD
    ADD R2, R0, R2
    LD R0, HAS_CODE
    ADD R2, R0, R2
    ADD R1, R2, #-3
    BRz EXIT_CONDITIONS
    LD R0, ExitIntrPtr
    TRAP x22
    TRAP x20
    BRnzp EXIT_INTERACT
    
ALREADY_TAKEN LD R0, IntrErrorPtr
    TRAP x22
    TRAP x20
    BRnzp EXIT_INTERACT

NO_BATTERY LD R0, OfficeIntr_POWER_OFFPtr
    TRAP x22
    TRAP x20
    BRnzp EXIT_INTERACT
    
EXIT_CONDITIONS JSR ExitCode
    BRnzp EXIT_INTERACT

EXIT_INTERACT    LD R7, InteractR7
    LD R1, InteractR1
    LD R0, InteractR0
    LD R2, InteractR2
    RET
    
InteractR7 .BLKW #1
InteractR0 .BLKW #1
InteractR1 .BLKW #1
InteractR2 .BLKW #1
;**************************************************************

;More pointer tables
MoveErrorPtr .FILL MoveError
CellMoveOptionsPtr .FILL CellMoveOptions
HallwayMoveOptionsPtr .FILL HallwayMoveOptions
StorageMoveOptionsPtr .FILL StorageMoveOptions
OfficeMoveOptionsPtr .FILL OfficeMoveOptions
ExitMoveOptionsPtr .FILL ExitMoveOptions

OfficeIntr_POWER_OFFPtr .FILL OfficeIntr_POWER_OFF
OfficeIntr_POWER_ONPtr .FILL OfficeIntr_POWER_ON
CellIntrPtr .FILL CellIntr
IntrErrorPtr .FILL IntrError
HallwayIntrPtr .FILL HallwayIntr
StorageIntrPtr .FILL StorageIntr
ExitIntrPtr .FILL ExitIntr

;Current room: Cell=0, Hallway=1, Storage=2, Office=3, Exit=4
ROOM .FILL #0

;Inventory/game states
HAS_KEYCARD .FILL #0
HAS_BATTERY .FILL #0
HAS_CODE .FILL #0
POWER_ON .FILL #0
QUIT_TRUE .FILL #0

;************************ShowInventory*****************************
;This routine handles movement between rooms
;
;R0 - used for TRAP
;R1 - Temp register used for checking state
;R7 - return address from subroutine
;**************************************************************
ShowInventory
    ST R7, InvenR7
    ST R1, InvenR1
    ST R0, InvenR0
    LEA R0, INVENTORY_PROMPT
    TRAP x22

    LD R0, HAS_KEYCARD
    ADD R1, R0, #0
    BRz SKIP_KEYCARD
    LEA R0, KeycardStr
    TRAP x22
    
SKIP_KEYCARD LD R0, HAS_BATTERY
    ADD R1, R0, #0
    BRz SKIP_BATTERY
    LEA R0, BatteryStr
    TRAP x22
    
    
SKIP_BATTERY LD R0, HAS_CODE
    ADD R1, R0, #0
    BRz SKIP_CODE
    LEA R0, CodeStr
    TRAP x22

SKIP_CODE   LEA R0, INVENTORY_PROMPT_2
    TRAP x22
    TRAP x20
    LD R7, InvenR7
    LD R1, InvenR1
    LD R0, InvenR0
    RET
InvenR7 .BLKW #1
InvenR0 .BLKW #1
InvenR1 .BLKW #1
;**************************************************************
INVENTORY_PROMPT .STRINGZ "\nInventory:\n"
INVENTORY_PROMPT_2 .STRINGZ "\nPress enter to continue\n"
KeycardStr .STRINGZ "Keycard\n"
BatteryStr .STRINGZ "Battery\n"
CodeStr .STRINGZ "Code: 415\n"


;************************ExitCode*****************************
;This routine handles the win condition for the game
;
;R0 - used for TRAP
;R1 - Temp register used for checking state
;R2 - Used to count remaining attempts
;R3 - Contains current digit to check
;R7 - return address from subroutine
;**************************************************************
ExitCode
    ST R7, ExitR7
    ST R0, ExitR0
    ST R2, ExitR2
    ST R1, ExitR1
    ST R3, ExitR3
    
    AND R2, R2, #0
    ADD R2, R2, #3
    LEA R0, EXIT_PROMPT
    TRAP x22

;Checks digit 1
CODE_LOOP    LEA R0, CODE_1
    TRAP x22
    TRAP x20
    TRAP x21
    LD R3, ASCII_4
    ADD R1, R0, R3
    BRz SKIP_1
    ADD R2, R2, #-1
    BRnzp WRONG

;Checks digit 2
SKIP_1  LEA R0, CODE_2
    TRAP x22
    TRAP x20
    TRAP x21
    LD R3, ASCII_1
    ADD R1, R0, R3
    BRz SKIP_2
    ADD R2, R2, #-1
    BRnzp WRONG

;Checks digit 3
SKIP_2  LEA R0, CODE_3
    TRAP x22
    TRAP x20
    TRAP x21
    LD R3, ASCII_5
    ADD R1, R0, R3
    BRz GAME_WON
    ADD R2, R2, #-1
    BRnzp WRONG


;Handles incorrect code
WRONG ADD R1, R2, #0
    BRz GAME_OVER

    LEA R0, INCORRECT_PROMPT
    TRAP x22
    LD R3, pos48
    ADD R0, R2, R3
    TRAP x21
    BRnzp CODE_LOOP

;Handles game over/game won
GAME_OVER LD R0, DEATH_PROMPT_PTR
    TRAP x22
    TRAP x20
    AND R1, R1, #0
    ADD R1, R1, #1
    ST R1, QUIT_TRUE
    BRnzp EXIT_SR

GAME_WON LEA R0, WIN_PROMPT
    TRAP x22
    TRAP x20
    AND R1, R1, #0
    ADD R1, R1, #1
    ST R1, QUIT_TRUE
    BRnzp EXIT_SR

EXIT_SR    LD R7, ExitR7
    LD R0, ExitR0
    LD R2, ExitR2
    LD R1, ExitR1
    LD R3, ExitR3
    RET
ExitR7 .BLKW #1
ExitR0 .BLKW #1
ExitR1 .BLKW #1
ExitR2 .BLKW #1
ExitR3 .BLKW #1

ASCII_4 .FILL #-52
ASCII_1 .FILL #-49
ASCII_5 .FILL #-53

pos48 .FILL #48
;**************************************************************
DEATH_PROMPT_PTR .FILL DEATH_PROMPT
EXIT_PROMPT .STRINGZ "\nYou swipe the keycard but now the exit door needs a code!\n"
INCORRECT_PROMPT .STRINGZ "\nWrong! Remaining attempts: "
CODE_1 .STRINGZ "\nEnter digit 1: "
CODE_2 .STRINGZ "\nEnter digit 2: "
CODE_3 .STRINGZ "\nEnter digit 3: "
WIN_PROMPT .STRINGZ "\nThe blast door unlocks and slowly opens.\n\nFresh air fills your lungs as you step out of the facility.\n\nYOU ESCAPED\n"
DEATH_PROMPT .STRINGZ "\nACCESS DENIED\n\nMAXIMUM FAILED ATTEMPTS EXCEEDED\n\nFACILITY SECURITY RESPONSE ACTIVATED\n\nA red laser locks onto your chest.\n\nYOU DIED\n"

;Interact strings
OfficeIntr_POWER_OFF .STRINGZ "\nLooks like there is a spot for a battery here. Maybe you can find one nearby.\nPress enter to continue\n"
OfficeIntr_POWER_ON .STRINGZ "\nYou placed the battery in the slot and the power turned back on!\nWith the lights on, you can read the code on the sticky note.\nCode: 415. This might be important later...\nPress enter to continue\n"
CellIntr .STRINGZ "\nYou found a battery!\nPress enter to continue\n"
IntrError .STRINGZ "\nYou have already taken this\nPress enter to continue\n"
HallwayIntr .STRINGZ "\nThere is nothing to interact with. Maybe you should search another room\nPress enter to continue\n"
StorageIntr .STRINGZ "\nYou found a keycard!\nPress enter to continue\n"
ExitIntr .STRINGZ "\nYou must turn the power on, find the keycard, and find the code before attempting to exit\nPress enter to continue\n"

;Room Descriptions
CellInfo .STRINGZ "A dim emergency light flickers overhead.\nThe cell door is open.\nSomething metallic lies beneath the bed."
HallwayInfo .STRINGZ "A long hallway stretches through the facility.\nMost systems appear offline.\nDoors lead EAST and WEST.\nA reinforced exit door sits to the NORTH."
StorageInfo .STRINGZ "Dusty shelves line the room.\nA red keycard hangs beside a toolbox."
OfficeInfo .STRINGZ "Dark monitors cover the walls.\nA backup generator sits in the corner.\nA note is taped beside a terminal."
ExitInfoPower .STRINGZ "The exit panel is dark. The power is still offline.\n"
ExitInfoKeycard .STRINGZ "The panel lights up, but a keycard is required.\n"
ExitInfo .STRINGZ "Looks like the panel is ready for a code.\n"

;Other Strings
Map .STRINGZ "\n\n          Exit\n            |\nStorage - Hallway - Office\n            |\n           Cell\n"
Options .STRINGZ "\n\n1. Move\n2. Interact\n3. Inventory\n4. Quit\n\n"

;Movement Strings
MoveError .STRINGZ "\nInvalid direction, enter a valid value: "
CellMoveOptions .STRINGZ "\n\nPossible directions\n********************\nN - Hallway\n********************\n\nEnter a direction: "
HallwayMoveOptions .STRINGZ "\n\nPossible directions\n********************\nN - Exit\nS - Cell\nE - Office\nW - Storage\n********************\n\nEnter a direction: "
StorageMoveOptions .STRINGZ "\n\nPossible directions\n********************\nE - Hallway\n********************\n\nEnter a direction: "
OfficeMoveOptions .STRINGZ "\n\nPossible directions\n********************\nW - Hallway\n********************\n\nEnter a direction: "
ExitMoveOptions .STRINGZ "\n\nPossible directions\n********************\nS - Hallway\n********************\n\nEnter a direction: "

    .END