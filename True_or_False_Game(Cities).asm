;Assembly code for True of False game regarding Capital Cities
;Author       : Daniel Mullings
;Adapted from : GuessingGame.asm (5004CEM_Sessions/Session3/Task2/GuessingGame.asm)

;Game functions as follows:
;- Displays question regarding capital cities, Question retrieved from Array
;- Prompts Player 1 and Player 2 to submit answer as single 'T' or 'F' char, stored in variables
;- Compares Player 1 and Player 2 answers stored in variables against question answer, Question Answer stored in Array
;- Displays results of Player 1 and Player 2 answers (i.e. Correct or Incorrect)

;- NOTE: Program Loops through multiple Arrays simultaneously, each responsible for storing Question, Question Length or Question Answer



;Macro: Print messages to screen 
;       !REFERENCE: Macro adapted from: print.asm (5004CEM_Sessions/Session3/AssemblyCode/print.asm)
;%1 = Message, %2 = Message length
%macro print_string 2                                                          ;Start of macro w/ 2 Arguments
  mov edx, %2                                                                  ;Message length
  mov ecx, %1                                                                  ;Message to write
  mov ebx, 1                                                                   ;File descriptor ("stdout")
  mov eax, 4                                                                   ;System call number ("sys_write") to print to the screen
  int 0x80                                                                     ;Invoke interrupt and OS check registers to print message
%endmacro                                                                      ;End of macro

;Macro: Print integers to screen 
;%1 = Variable containing integer, %2 = Variable to store/print binary integer converted ASCII
%macro print_int 1                                                             ;Start of macro w/ 2 Arguments
  mov rax, [%1]                                                                ;Move the "%1" variable value into "rax" register
  call ConvertIntegerToString
%endmacro                                                                      ;End of macro

;Macro: Retrieve and store user input
;       !REFERENCE: Macro adapted from: letterInput.asm (5004CEM_Sessions/Session3/AssemblyCode/letterInput.asm)
;%1 = Variable used to store user input
%macro store_input 1                                                           ;Start of macro w/ 1 Argument
  mov eax, 3                                                                   ;System call number ("sys_read") to read from keyboard
  mov ebx, 2                                                                   ;"stdout" for reading from keyboard
  mov ecx, %1                                                                  ;Move the input entered by the user into the "%1" variable
  mov edx, 1                                                                   ;Size of input is 1 byte
  int 0x80                                                                     ;Invoke interrupt and OS check registers, then read from keyboard
%endmacro                                                                      ;End of macro

;Macro: Get player answer
;%1 = Player # answer request message, %2 = Player # answer request message length, %3 = Variable to store Player # answer
%macro get_player_ans 3                                                        ;Start of macro w/ 3 Arguments
  print_string %1, %2                                                          ;"print_string" responsible for displaying message
  store_input %3                                                               ;"store_input" responsible for receiving and storing user input
  
  call ClearLine
  
  ;!TERMINATES PROGRAM IMMEDIATELY IF GET 'E' CHAR AS PLAYER # ANSWER
  mov eax, [%3]                                                                ;Move the "%3" variable value into "eax" register
  cmp eax, 'E'                                                                 ;Compare 'E' (Exit code) with value in "eax" register
  je Terminate                                                                 ;IF "eax" == 'E' : Jump to "Terminate"
%endmacro                                                                      ;End of macro

;Macro: Sets game mode via variable storing game mode code
;%1 = Game mode code value
%macro set_game_mode 1                                                         ;Start of macro w/ 1 Arguments
  mov eax, %1                                                                  ;Move the "%1" variable value into "eax" register
  mov [gameMode], eax                                                          ;Move the value in "eax" register into "gameMode" variable
%endmacro                                                                      ;End of macro

;Macro: Set "player#_isAlive" to "False (0)"
;%1- Variable storing Player # "_isAlive" state
%macro set_player_dead 1                                                       ;Start of macro w/ 1 Arguments
  mov eax, 0                                                                   ;Move the "0" value into "eax" register
  mov [%1], eax                                                                ;Move the value in "eax" register into "%1" variable
%endmacro                                                                      ;End of macro

;Macro: Check player answer
;%1 = Variable storing Player # answer, %2 = Subroutine name to call if Player # answer correct, %3 = Subroutine name to call if Player # answer incorrect
%macro check_player_ans 3                                                      ;Start of macro w/ 3 Arguments
  mov eax, [%1]                                                                ;Move the "%1" variable value into "eax" register
  cmp eax, [r10]                                                               ;Compare "[r10] (Pointing to element of current answer in array)" with value in "eax" register
  je %2                                                                        ;IF "eax" == "[r10]": Jump to "%2"
  call %3                                                                      ;ELSE               : Call "%3"
  
%endmacro                                                                      ;End of macro

;Macro: Check player streak
;%1 = Variable storing Player # streak, %2 = Subroutine name to call if Player # streak == Streak threshold
%macro check_player_streak 2                                                   ;Start of macro w/ 2 Arguments
  mov eax, [%1]                                                                ;Move the "%1" variable value into "eax" register 
  cmp eax, [streakThreshold]                                                   ;Compare "streakThreshold" variable value with value in "eax" register
  je %2                                                                        ;IF "eax" == "streakThreshold": Jump to "%2"
%endmacro                                                                      ;End of macro

;Macro: Check how many lives Player has and call subrountine to set Player "_isAlive" state to "dead" if "player#Lives" == "playerLivesThreshold"
;%1 = Variable storing Player # lives count, %2 = Subroutine name to call if Player # is dead
%macro check_player_lives 2                                                    ;Start of macro w/ 2 Arguments
  mov eax, [%1]                                                                ;Move the "%1" variable value into "eax" register
  cmp eax, [playerLivesThreshold]                                              ;Compare "playerLivesThreshold" variable value with value in "eax" register
  je %2                                                                        ;IF "eax" == "playerLivesThreshold": Jump to "%2"
%endmacro                                                                      ;End of macro

;Macro: Reset player streak
;%1 = Variable storing player # streak
%macro reset_player_streak 1                                                   ;Start of macro w/ 1 Arguments
  mov eax, 0                                                                   ;Move the value "0" into "eax" register
  mov [%1], eax                                                                ;Move the value in "eax" register into "%1" variable
%endmacro                                                                      ;End of macro

;Macro Verify game mode dependent on Player 1 is alive state and set appropriate game mode
;%1 = Subroutine name to call if Player 1 is dead, %2 = Subroutine name to call if Player 1 is alive
%macro verify_game_mode 2                                                      ;Start of macro w/ 1 Arguments
  mov eax, [player1_isAlive]                                                   ;Move the "%1" variable value into "eax" register
  cmp eax, 0                                                                   ;Compare value in "eax" register with "0"
  je %1                                                                        ;IF "0" == "eax": Jump to "%1"
  call %2                                                                      ;ELSE           : Call "%2"
%endmacro                                                                      ;End of macro



section	.data
  ;Welcome message and border
  welcomeMsg db "          Welcome to this Capital Cities True or False game"  ;Message - Welcome message
  welcomeMsgLen equ $-welcomeMsg                                               ;Message Length
  
  welcomeMsgBorder db "---------------------------------------------------------------------"
                                                                               ;Message - Welcome message border
  welcomeMsgBorderLen equ $-welcomeMsgBorder                                   ;Message Length

  ;Welcome message notices
  terminateMsg db "NOTE: Enter 'E' to Exit Program"                            ;Message - Notice: Input 'E' to terminate game
  terminateMsgLen equ $-terminateMsg                                           ;Message Length

  singleCharMsg db "NOTE: Single Character Input Valid, Subsequent Characters Disregarded"
                                                                               ;Message - Notice: Input valid single character, additional discarded
  singleCharMsgLen equ $-singleCharMsg                                         ;Message Length

  ;Player 1 related requests/responses
  player1AnswerReq db "Player 1: "                                             ;Message - Player 1 input prompt
  player1AnswerReqLen equ $-player1AnswerReq                                   ;Message Length

  player1CorrectMsg db "Player 1 is Correct"                                   ;Message - Player 1 answer correct
  player1CorrectMsgLen equ $-player1CorrectMsg                                 ;Message Length

  player1IncorrectMsg db "Player 1 is Incorrect"                               ;Message - Player 1 answer incorrect
  player1IncorrectMsgLen equ $-player1IncorrectMsg                             ;Message Length
  
  player1ScoreMsg db "Player 1 score is: "                                     ;Message - Player 1 score
  player1ScoreMsgLen equ $-player1ScoreMsg                                     ;Message Length

  player1StreakWinMsg db "Player 1 on a 5 Score Streak, You Win a Prize!"      ;Message - Player 1 score streak
  player1StreakWinMsgLen equ $-player1StreakWinMsg                             ;Message Length

  player1OutOfLivesMsg db "Player 1: Out of Lives (0/3)"                       ;Message - Player 1 out of lives
  player1OutOfLivesMsgLen equ $-player1OutOfLivesMsg                           ;Message Length

  ;Player 2 related requests/responses
  player2AnswerReq db "Player 2: "                                             ;Message - Player 2 input prompt
  player2AnswerReqLen equ $-player2AnswerReq                                   ;Message Length

  player2CorrectMsg db "Player 2 is Correct"                                   ;Message - Player 2 answer correct
  player2CorrectMsgLen equ $-player2CorrectMsg                                 ;Message Length

  player2IncorrectMsg db "Player 2 is Incorrect"                               ;Message - Player 2 answer incorrect
  player2IncorrectMsgLen equ $-player2IncorrectMsg                             ;Message Length

  player2ScoreMsg db "Player 2 score is: "                                     ;Message - Player 2 score
  player2ScoreMsgLen equ $-player2ScoreMsg                                     ;Message Length
  
  player2StreakWinMsg db "Player 2 on a 5 Score Streak, You Win a Prize!"      ;Message - Player 2 score streak
  player2StreakWinMsgLen equ $-player2StreakWinMsg                             ;Message Length

  player2OutOfLivesMsg db "Player 2: Out of Lives (0/3)"                       ;Message - Player 2 out of lives
  player2OutOfLivesMsgLen equ $-player2OutOfLivesMsg                           ;Message Length
  
  ;Player 1 and 2 related requests/responses
  player1and2CorrectMsg db "Both Player 1 & 2 are Correct"                     ;Message - Player 1 and 2 answer correct
  player1and2CorrectMsgLen equ $-player1and2CorrectMsg                         ;Message Length

  player1and2IncorrectMsg db "Both Player 1 & 2 are Incorrect"                 ;Message - Player 1 and 2 answer incorrect
  player1and2IncorrectMsgLen equ $-player1and2IncorrectMsg                     ;Message Length
  
  player1and2StreakWinMsg db "Player 1 and 2 on a 5 Score Streak, You both Win a Prize!"  
                                                                               ;Message - Player 1 and 2 score streak
  player1and2StreakWinMsgLen equ $-player1and2StreakWinMsg                     ;Message Length

  ;Questions, Question lengths and Question underline
  question1 db "Question 1: The capital of the United Kingdom is London?"      ;Message - Question 1
  question1Len equ $-question1                                                 ;Message Length

  question2 db "Question 2: The capital of Australia is Canberra?"             ;Message - Question 2
  question2Len equ $-question2                                                 ;Message Length

  question3 db "Question 3: The capital of the United States of America is Washington, D.C.?"
                                                                               ;Message - Question 3
  question3Len equ $-question3                                                 ;Message Length

  question4 db "Question 4: The capital of Thailand is Bangkok?"               ;Message - Question 4
  question4Len equ $-question4                                                 ;Message Length

  question5 db "Question 5: The capital of China is Shanghai?"                 ;Message - Question 5
  question5Len equ $-question5                                                 ;Message Length

  question6 db "Question 6: The capital of Afghanistan is Kandahar?"           ;Message - Question 6
  question6Len equ $-question6                                                 ;Message Length

  question7 db "Question 7: The capital of Iran is Tehran?"                    ;Message - Question 7
  question7Len equ $-question7                                                 ;Message Length

  question8 db "Question 8: The capital of Scotland is Glasgow?"               ;Message - Question 8
  question8Len equ $-question8                                                 ;Message Length

  question9 db "Question 9: The capital of India is New Delhi?"                ;Message - Question 9
  question9Len equ $-question9                                                 ;Message Length

  question10 db "Question 10: The capital of Italy is Sicily?"                 ;Message - Question 10
  question10Len equ $-question10                                               ;Message Length

  ;Misc Messages
  outOfMsg db " out of "                                                       ;Message - Score "out of" #
  outOfMsgLen equ $-outOfMsg                                                   ;Message Length
  
  programTerminatedMsg db "Program Terminated"                                 ;Message - Program Terminated
  programTerminatedMsgLen equ $-programTerminatedMsg                           ;Message Length

  gameEndMsg db "End of Quiz, Thanks for Playing"                              ;Message -  End of Quiz
  gameEndMsgLen equ $-gameEndMsg                                               ;Message Length

  ;Array: To store questions answer in 8 bytes
  arrayQuestionsAns dq 'F', 'T', 'T', 'T', 'F', 'F', 'T', 'F', 'T', 'F', 0

  ;Array: To store pointers to questions in 8 bytes
  arrayQuestions dq question1, question2, question3, question4, question5, question6, question7, question8, question9, question10

  ;Array: To store pointers to questions length in 8 bytes
  arrayQuestionsLen dq question1Len, question2Len, question3Len, question4Len, question5Len, question6Len, question7Len, question8Len, question9Len, question10Len

  player1Score dq 0                                                            ;Variable to store Player 1 score in 1 byte
  player2Score dq 0                                                            ;Variable to store Player 2 score in 1 byte

  player1Streak dq 0                                                           ;Variable to store Player 1 streak in 8 bytes
  player2Streak dq 0                                                           ;Variable to store Player 2 streak in 8 bytes
  streakThreshold dq 5                                                         ;Variable to store streak threshold in 8 bytes
  
  player1Lives dq 3                                                            ;Variable to store Player 1 lives in 8 bytes
  player2Lives dq 3                                                            ;Variable to store Player 2 lives in 8 bytes
  playerLivesThreshold dq 0                                                    ;Variable to store lives threshold in 8 bytes
  
  player1_isAlive dq 1                                                         ;Variable to store Player 1 isAlive state in 8 bytes
  player2_isAlive dq 1                                                         ;Variable to store Player 2 isAlive state in 8 bytes

  
  questionsRemainingCounter dq 10                                              ;Variable to store questions remaining count in 1 byte
  questionsCompletedCounter dq 0                                               ;Variable to store questions completed count in 1 byte

  gameMode dq 'a'                                                              ;Variable to store current game mode code in 8 bytes
  
  newLineChar db 10                                                            ;For creating a NewLine (C++ std::endl equivalent)



section .bss
  player1Ans resq 1                                                            ;Variable to store Player 1 answer in 8 bytes
  player2Ans resq 1                                                            ;Variable to store Player 2 answer in 8 bytes
  
  integerAsString resb 100                                                     ;Variable to store buffer (Integer being converted to string via repetitive division of 10) of integer as string in 100 bytes
  integerAsStringDigitPos resb 8                                               ;Variable to store pointer to position of each digit in "integerAsString" in 8 bytes
  
  clean resb 1

section	.text
  global _start                                                                ;Must be declared for linker (ld)



_start:
;             !REFERENCE: Subroutine adapted from: 5004CEM - Operating Systems and Security - 2223JANMAY, Assembly Code Short Course, Simple Game Example: Simple Guessing Game (File Name: GuessingGame.asm)
  call DisplayWelcome
  
  mov r8, arrayQuestions                                                       ;Point to first question
  mov r9, arrayQuestionsLen                                                    ;Point to first question length
  mov r10, arrayQuestionsAns                                                   ;Point to first question answer



;Sub-Routine: Main, Program core, Responsible for calling other subroutines
;             !REFERENCE: Subroutine adapted from: GuessingGame.asm (5004CEM_Sessions/Session3/Task2/GuessingGame.asm)
Top:
  call VerifyGameMode
  call RunGameMode

  inc byte [questionsCompletedCounter]

  call DisplayScore
  call CheckPlayerStreak
  call CheckPlayerLives

  add r8, 8                                                                    ;Add on 8 bytes (Using "dq" Datatype) to point at the next element (arrayQuestions)
  add r9, 8                                                                    ;Add on 8 bytes (Using "dq" Datatype) to point at the next element (arrayQuestionsLen)
  add r10, 8                                                                   ;Add on 8 bytes (Using "dq" Datatype) to point at the next element (arrayQuestionsAns)

  dec byte [questionsRemainingCounter]                                         ;Decrement "questionsRemainingCounter"
  jnz Top                                                                      ;IF "questionsRemainingCounter" != 0: Jump to "Top" (i.e. Loop)
  call GameEnd                                                                 ;ELSE                               : Call "GameEnd"



;--- GAME MODES SUBROUTINES SECTION ----
;Sub-Routine: Verify Player 1 is alive state == Player 2 is alive state 
VerifyGameMode:
  mov eax, [player1_isAlive]                                                   ;Move the "player1_isAlive" variable value into register "eax"
  cmp eax, [player2_isAlive]                                                   ;Compare "player2_isAlive" variable value with value in "eax" register
  je VerifyGameMode_Coupled                                                    ;IF "eax" == "player2_isAlive": Jump to "VerifyGameMode_Coupled"
  call VerifyGameMode_Uncoupled                                                ;ELSE                         : Call "VerifyGameMode_Uncoupled"
  ret

;Sub-Routine: Check Player 1 is alive state
;           & NOTE: Coupled = Single player is alive state evaluated and game mode set (i.e. Both Player 1 and 2 alive or dead)
;           & NOTE: Subroutine only called if Player 1 answer == Player 2 answer
VerifyGameMode_Coupled:
  verify_game_mode SetGameMode_d, SetGameMode_a
  ret

;Sub-Routine: Check Player 1 is alive state
;           & NOTE: Uncoupled = Single player is alive state evaluated and game mode set (i.e. Either Player 1 alive and Player 2 dead OR Player 1 alive and Player 2) 
;           & NOTE: Subroutine only called if Player 1 is alive state != Player 2 is alive state  (i.e. If Player # is alive states differ, then one MUST be alive, one MUST be dead)
VerifyGameMode_Uncoupled:
  verify_game_mode SetGameMode_b, SetGameMode_c
  ret

;Sub-Routine: Call subroutines for running appropriate game mode depending on current game mode code
RunGameMode:
  call DisplayQuestion
  
  mov eax, [gameMode]
  
  cmp eax, 'a'                                                                 ;(All) Player 1 and 2 alive
  je StandardGameMode
  
  cmp eax, 'b'                                                                 ;Player 1 dead and player 2 alive
  je Player1DeadGameMode
  
  cmp eax, 'c'                                                                 ;Player 1 alive and player 2 dead
  je Player2DeadGameMode
  
  cmp eax, 'd'                                                                 ;(Dead) Player 1 and 2 dead
  je Player1andPlayer2DeadGameMode
  ret

;Sub-Routine: Call subroutines for running game with Player 1 and 2 alive
StandardGameMode:
  call GetPlayerAns
  call NewLine
  
  call CheckPlayerAns
  call NewLine
  ret

;Sub-Routine: Call subroutines for running game with Player 1 dead and 2 alive
Player1DeadGameMode:
  call DisplayPlayer1OutOfLives
  
  call GetPlayer2Ans
  call NewLine
  
  call CheckPlayer2Ans
  call NewLine
  ret

;Sub-Routine: Call subroutines for running game with Player 1 alive and 2 dead
Player2DeadGameMode:
  call GetPlayer1Ans
  
  call DisplayPlayer2OutOfLives
  call NewLine
  
  call CheckPlayer1Ans
  call NewLine
  ret

;Sub-Routine: Call subroutines for running game with Player 1 dead and 2 dead
Player1andPlayer2DeadGameMode:
  call DisplayPlayer1OutOfLives
  call DisplayPlayer2OutOfLives
  call Terminate
  ret



;--- GET PLAYER ANSWERS SUBROUTINES SECTION ----

;Sub-Routine: Get Player 1 and 2 answers via keyboard input
GetPlayerAns:
  call GetPlayer1Ans
  call GetPlayer2Ans
  ret
  
;Sub-Routine: Get Player 1 answer via keyboard input
GetPlayer1Ans:
  get_player_ans player1AnswerReq, player1AnswerReqLen, player1Ans
  ret

;Sub-Routine: Get Player 2 answer via keyboard input
GetPlayer2Ans:
  get_player_ans player2AnswerReq, player2AnswerReqLen, player2Ans
  ret
  
  

;--- SET GAME MODE AND PLAYER ALIVE STATE SUBROUTINES SECTION ---

;Sub-Routine: Set "gameMode" variable value to 'a'
;           & Game Mode A: Player 1 and 2 alive
SetGameMode_a:
  set_game_mode 'a'
  ret

;Sub-Routine: Set "gameMode" variable value to 'b'
;           & Game Mode B: Player 1 dead and Player 2 alive
SetGameMode_b:
  set_game_mode 'b'
  ret

;Sub-Routine: Set "gameMode" variable value to 'c'
;           & Game Mode C: Player 1 alive and Player 2 dead
SetGameMode_c:
  set_game_mode 'c'
  ret

;Sub-Routine: Set "gameMode" variable value to 'd'
;           & Game Mode D: Player 1 and 2 dead
SetGameMode_d:
  set_game_mode 'd'
  ret

;Sub-Routine: Set "player1_isAlive" variable to dead ("0 (False)")
SetPlayer1_Dead:
  set_player_dead player1_isAlive
  ret
  
;Sub-Routine: Set "player2_isAlive" variable to dead ("0 (False)")
SetPlayer2_Dead:
  set_player_dead player2_isAlive
  ret



;--- CHECK PLAYER ANSWERS/STREAKS SUBROUTINES SECTION ----

;Sub-Routine: Check Player 1 answer == Player 2 answer
CheckPlayerAns:
  mov eax, [player1Ans]                                                        ;Move the "player1Ans" variable value into register "eax"
  cmp eax, [player2Ans]                                                        ;Compare "player2Ans" variable value with value in "eax" register
  je CheckPlayerAns_Coupled                                                    ;IF "eax" == "player2Ans": Jump to "CheckPlayerAns_Coupled"
  call CheckPlayerAns_Uncoupled                                                ;ELSE                    : Call "CheckPlayerAns_Uncoupled"
  ret

;Sub-Routine: Check Player 1 answer
;           & NOTE: Coupled = Single answer evaluated and single message displayed
;           & NOTE: Subroutine only called if Player 1 answer == Player 2 answer
CheckPlayerAns_Coupled:
  check_player_ans player1Ans, DisplayPlayer1AndPlayer2Correct, DisplayPlayer1AndPlayer2Incorrect                
  ret

;Sub-Routine: Check Player 1 and 2 answers
;           & NOTE: Uncoupled = Answers evaluated and messages displayed individually
;           & NOTE: Subroutine only called if Player 1 answer != Player 2 answer
CheckPlayerAns_Uncoupled:
  call CheckPlayer1Ans
  call CheckPlayer2Ans
  ret

;Sub-Routine: Check Player 1 answer and display relevant message
CheckPlayer1Ans:
  check_player_ans player1Ans, DisplayPlayer1Correct, DisplayPlayer1Incorrect
  ret

;Sub-Routine: Check Player 2 answer and display relevant message
CheckPlayer2Ans:
  check_player_ans player2Ans, DisplayPlayer2Correct, DisplayPlayer2Incorrect
  ret


;Sub-Routine: Check Player 1 streak counter == Player 2 streak counter
CheckPlayerStreak:
  mov eax, [player1Streak]                                                     ;Move the "player1Streak" variable value into register "eax"
  cmp eax, [player2Streak]                                                     ;Compare "player2Streak" variable value with value in "eax" register
  je CheckPlayerStreak_Coupled                                                 ;IF "eax" == "player2Streak": Jump to "CheckPlayerStreak_Coupled"
  call CheckPlayerStreak_Uncoupled                                             ;ELSE                       : Call "CheckPlayerStreak_Uncoupled"
  ret

;Sub-Routine: Check Player 1 streak counter
;           & NOTE: Coupled = Single streak counter evaluated and single message displayed
;           & NOTE: Subroutine only called if Player 1 streak counter == Player 2 streak counter
CheckPlayerStreak_Coupled:
  check_player_streak player1Streak, DisplayPlayer1and2StreakWin           
  ret

;Sub-Routine: Check Player 1 and 2 streak counter
;           & NOTE: Uncoupled = Streak counters evaluated and messages displayed individually
;           & NOTE: Subroutine only called if Player 1 streak counter != Player 2 streak counter
CheckPlayerStreak_Uncoupled:
  call CheckPlayer1Streak
  call CheckPlayer2Streak
  ret

;Sub-Routine: Check Player 1 streak counter reaches 5
;           & Display Player 1 streak win message if streak counter reaches 5
CheckPlayer1Streak:
  check_player_streak player1Streak, DisplayPlayer1StreakWin
  ret

;Sub-Routine: Check Player 2 streak counter reaches 5
;           & Dislay Player 2 streak win message if streak counter reaches 5
CheckPlayer2Streak:
  check_player_streak player2Streak, DisplayPlayer2StreakWin
  ret

;Sub-Routine: Check Player 1 and 2 lives
CheckPlayerLives:
  call CheckPlayer1Lives
  call CheckPlayer2Lives
  ret

;Sub-Routine: Check Player 1 lives and set "player#_isAlive" to "0 (False)" if "player1Lives" == "playerLivesThreshold"
CheckPlayer1Lives:
  check_player_lives player1Lives, SetPlayer1_Dead
  ret

;Sub-Routine: Check Player 2 lives and set "player#_isAlive" to "0 (False)" if "player2Lives" == "playerLivesThreshold"
CheckPlayer2Lives:
  check_player_lives player2Lives, SetPlayer2_Dead
  ret



;--- INCREMENT SCORES/STREAKS, DECREMENT/RESET LIVES/STREAK COUNTERS SUBROUTINES SECTION ----

;Sub-Routine: Increment Player 1 score and streak counter
IncrementPlayer1ScoreAndStreak:
  inc byte [player1Score]
  inc byte [player1Streak]
  ret

;Sub-Routine: Increment Player 2 score and streak counter
IncrementPlayer2ScoreAndStreak:
  inc byte [player2Score]
  inc byte [player2Streak]
  ret

;Sub-Routine: Reset Player 1 streak counter to 0
ResetPlayer1Streak:
  reset_player_streak player1Streak
  ret
  
;Sub-Routine: Reset Player 2 streak counter to 0
ResetPlayer2Streak:
  reset_player_streak player2Streak
  ret
  
;Sub-Routine: Decrement Player 1 lives counter
DecrementPlayer1Lives:
  dec byte [player1Lives]
  ret
  
;Sub-Routine: Decrement Player 2 lives counter
DecrementPlayer2Lives:
  dec byte [player2Lives]
  ret



;--- DISPLAY MESSAGES SUBROUTINES SECTION ----

;Sub-Routine: Display welcome to game border message
;           & Welcome message
;           & Notice message
DisplayWelcome:
  call NewLine
  
  print_string welcomeMsgBorder, welcomeMsgBorderLen
  call NewLine
  print_string welcomeMsg, welcomeMsgLen
  call NewLine
  print_string welcomeMsgBorder, welcomeMsgBorderLen
  call NewLine
  
  print_string terminateMsg, terminateMsgLen
  call NewLine
  print_string singleCharMsg, singleCharMsgLen
  call NewLine
  
  print_string welcomeMsgBorder, welcomeMsgBorderLen
  call NewLine
  ret

;Sub-Routine: Display questions message
DisplayQuestion:
  call NewLine
  print_string [r8], [r9]                                                      ;[r8] Pointer to array element containing question (arrayQuestions), 
                                                                               ;[r9] Pointer to array element containing question length (arrayQuestionsLen)
  call NewLine
  call NewLine
  ret

;Sub-Routine: Display Player 1 correct message and increment score
;           & Increment Player 1 score and streak counter
DisplayPlayer1Correct:
  call IncrementPlayer1ScoreAndStreak
  
  print_string player1CorrectMsg, player1CorrectMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 2 answer correct message
;           & Increment Player 2 score and streak counter
DisplayPlayer2Correct:
  call IncrementPlayer2ScoreAndStreak
  
  print_string player2CorrectMsg, player2CorrectMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 1 and 2 answer correct message
;           & Increment Player 1 and 2 score and streak counter
DisplayPlayer1AndPlayer2Correct:
  call IncrementPlayer1ScoreAndStreak
  call IncrementPlayer2ScoreAndStreak
  
  print_string player1and2CorrectMsg, player1and2CorrectMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 1 answer incorrect message
;           & Reset Player 1 streak counter
DisplayPlayer1Incorrect:
  call ResetPlayer1Streak
  call DecrementPlayer1Lives
  
  print_string player1IncorrectMsg, player1IncorrectMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 2 answer incorrect message
;             & Reset Player 2 streak counter
DisplayPlayer2Incorrect:
  call ResetPlayer2Streak
  call DecrementPlayer2Lives
  
  print_string player2IncorrectMsg, player2IncorrectMsgLen
  call NewLine
  ret
  
;Sub-Routine: Display Player 1 and 2 answer incorrect message
;           & Reset Player 1 and 2 streak counter
DisplayPlayer1AndPlayer2Incorrect:
  call ResetPlayer1Streak
  call ResetPlayer2Streak
  
  call DecrementPlayer1Lives
  call DecrementPlayer2Lives
  
  print_string player1and2IncorrectMsg, player1and2IncorrectMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 1 and 2 scores
DisplayScore:
  call DisplayPlayer1Score
  call NewLine
  
  call DisplayPlayer2Score
  call NewLine
  call NewLine
  ret

;Sub-Routine: Display Player 2 score message
;           & Display Player 2 score integer
;           & Display out of message
;           & Display Completed questions counter integer
DisplayPlayer1Score:
  print_string player1ScoreMsg, player1ScoreMsgLen
  print_int player1Score
  print_string outOfMsg, outOfMsgLen
  print_int questionsCompletedCounter
  ret

;Sub-Routine: Display Player 1 score message
;           & Display Player 1 score integer
;           & Display out of message
;           & Display completed questions counter integer
DisplayPlayer2Score:
  print_string player2ScoreMsg, player2ScoreMsgLen
  print_int player2Score
  print_string outOfMsg, outOfMsgLen
  print_int questionsCompletedCounter
  ret

;Sub-Routine: Display Player 1 answer correct 5 consecutive times message
;           & Reset Player 2 streak counter
DisplayPlayer1StreakWin:
  call ResetPlayer1Streak
  
  print_string player1StreakWinMsg, player1StreakWinMsgLen
  call NewLine
  call NewLine
  ret

;Sub-Routine: Display Player 2 answer correct 5 consecutive times message 
;           & Reset Player 2 streak counter
DisplayPlayer2StreakWin:
  call ResetPlayer2Streak
  
  print_string player2StreakWinMsg, player2StreakWinMsgLen
  call NewLine
  call NewLine
  ret
  
;Sub-Routine: Display Player 1 and 2 answer correct 5 consecutive times message 
;           & Reset Player 1 and 2 streak counter
DisplayPlayer1and2StreakWin:
  call ResetPlayer1Streak
  call ResetPlayer2Streak
  
  print_string player1and2StreakWinMsg, player1and2StreakWinMsgLen
  call NewLine
  call NewLine
  ret

;Sub-Routine: Display Player 1 out of lives message
DisplayPlayer1OutOfLives:
  print_string player1OutOfLivesMsg, player1OutOfLivesMsgLen
  call NewLine
  ret

;Sub-Routine: Display Player 2 out of lives message
DisplayPlayer2OutOfLives:
  print_string player2OutOfLivesMsg, player2OutOfLivesMsgLen
  call NewLine
  ret


;--- INTEGER TO STRING SUBROUTINES SECTION ---

;NOTE: !REFERENCE: Subroutine section implemented using following tutorial 
;      Kupala. (2016, October 1). x86/64 Linux Assembly - Subroutine to Print Integers. YouTube. 
;      Retrieved February 13, 2023, from
;      https://www.youtube.com/watch?v=XuUD0WQ9kaE&amp;list=PLetF-YjXm-sCH6FrTz4AQhfH6INDQvQSn&amp;index=9&amp;ab_channel=kupala 

;Sub-Routine: Breaks down and stores integer as string backwards
ConvertIntegerToString:
  mov rcx, integerAsString                                                     ;Move the "integerAsString" variable pointer into "rcx" register
  mov [rcx], rbx                                                               ;Move the value in "rxb" register into memory location pointed to by "rcx" register

  mov [integerAsStringDigitPos], rcx                                           ;Move the value in "rcx" register into "integerAsStringDigitPos" value

;Sub-Routine: Breaks down, converts and stores integer as string backwards
;             NOTE: Integer being converted is divided by 10, remainder converted to ASCII numerical equiv. and pushed on top of "integerAsString" variable value
;             NOTE: Steps repeated until integer being converted to string is divided by 10 to produce 0 w/ any remainder being processed as all previous remainders 
ConvertIntegerToStringLoop_Reversed:
  mov rdx, 0                                                                   ;Move the "0" value into "rdx" register (Prevent concatination of "rax" and "rdx" register, act as a 128 Bit register together)
  mov rbx, 10                                                                  ;Move the "10" value into "rbx" register
  div rbx                                                                      ;Divide value in "rax" register by value of "rbx" register (Value of "rax" register is variable value passed in from macro "convertDecimalToInteger")
  push rax                                                                     ;Go forward in stack
  add rdx, 48                                                                  ;Add "48" to value in "rdx" register (Which contains remainder of division) to convert to ASCII numerical equiv.

  mov rcx, [integerAsStringDigitPos]                                           ;Move the "integerAsStringDigitPos" variable value into "rcx" register
  mov [rcx], dl                                                                ;Move lower 8 bytes into "rcx" value (Moves character in "rdx" register) into position "integerAsStringDigitPos" variable value is pointing to in     
                                                                               ;"integerAsString" variable value
  
  inc rcx                                                                      ;Increment value in "rcx" register
  mov [integerAsStringDigitPos], rcx                                           ;Move the value in "rcx" register into "integerAsStringDigitPos" variable

  pop rax
  cmp rax, 0                                                                   ;Compare '0' with value in "rax" register (If integer in "rax" register (Being converted to string) != 0, divide by 10 again, 
                                                                               ;convert remainder to string, revaluate and repeat until integer in "rax" register (Being converted to string) == 0)
                                                                               
  jne ConvertIntegerToStringLoop_Reversed                                      ;IF "rax" == '0': Jump to "ConvertIntegerToStringLoop" (Loop through current subroutine)

;Sub-Routine: To print string storing converted integer, digit by digit, in reversed order to which integer was stored in string
;             NOTE: String is printed in reverse order to which it was stored as string is converted backwards, therefore requires unreversing to be displayed correctly
DisplayIntegerToStringLoop_Unreversed:
  mov rcx, [integerAsStringDigitPos]                                           ;Move the "integerAsStringDigitPos" variable value into "rcx" register

  mov rax, 1                                                                   ;System call number ("sys_write") to print to the screen
  mov rdi, 1                                                                   ;File descriptor ("stdout")
  mov rsi, rcx                                                                 ;Message to write
  mov rdx, 1                                                                   ;Message of output is 1 byte
  syscall                                                                      ;Invoke the kernel to print the value is "rsi" register ("syscall" over "int 0x80" for 64-Bit functionality)

  mov rcx, [integerAsStringDigitPos]                                           ;Move the "integerAsStringDigitPos" variable value into "rcx" register
  dec rcx                                                                      ;Decrement value in "rcx" register
  mov [integerAsStringDigitPos], rcx                                           ;Move the value in "rcx" register into "integerAsStringDigitPos" variable

  cmp rcx, integerAsString                                                     ;Compare "rcx" to" "integerAsString", means we are at start of string, concluding the printing of the string
  
  jge DisplayIntegerToStringLoop_Unreversed                                    ;IF "rcx" >= "integerAsString" jump to "DisplayIntegerToStringLoop_Unreversed" (Loop through current subroutine, 
                                                                               ;printing each digit from "integerAsString" backwards, which results in the integer digits being displayed correctly, as it is stored backwards when
                                                                               ;generated using the "ConvertIntegerToStringLoop_Reversed" subroutine)
  ret



;--- MISC SUBROUTINES SECTION ----

;Sub-Routine: To create a NewLine (C++ std::endl equivalent)
;             !REFERENCE: Subroutine adapted from: print.asm (5004CEM_Sessions/Session3/AssemblyCode/print.asm)
NewLine:
  mov edx, 1                                                                   ;"newLineChar" length
  mov ecx, newLineChar                                                         ;Move the "newLineChar" variable value into "eax" register
  mov ebx, 1                                                                   ;File descriptor ("stdout")
  mov eax, 4                                                                   ;System call number ("sys_write") to print to the screen
  int 0x80                                                                     ;Invoke interrupt and OS check registers to print newLineChar
  ret

;Sub-Routine: To receive and discard additional char input
;             !REFERENCE: Subroutine adapted from: 5004CEM - Operating Systems and Security - 2223JANMAY, Assembly Code Short Course, User Input: Activity for You (File Name: additionUserInput_Solution.rtf)
ClearLine:
  mov edx, 255                                                                 ;Size of the input is 255 bytes
  mov ecx, clean                                                               ;Move the characters entered by the user into the "clean" variable
  mov ebx, 2                                                                   ;"stdout" for reading from keyboard
  mov eax, 3                                                                   ;System call number ("sys_read") to read from keyboard
  int 0x80                                                                     ;Invoke interrupt and OS check registers, then read from keyboard
  ret

;Sub-Routine: To display "End of Quiz" message and terminate program at end of quiz
GameEnd:
  print_string gameEndMsg, gameEndMsgLen
  call Terminate

;Sub-Routine: To terminate the program gracefully
;             !REFERENCE: Subroutine adapted from: first.asm (5004CEM_Sessions/Session3/Task2/first.asm)
Terminate:
  call NewLine

  print_string programTerminatedMsg, programTerminatedMsgLen
  call NewLine
  call NewLine
  
  mov eax, 1                                                                   ;System call number ("sys_exit")
  mov ebx, 0                                                                   ;Return value
  int 0x80                                                                     ;Invoke interrupt and OS check registers, then terminate program