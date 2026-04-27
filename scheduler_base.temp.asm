; ============================================================
; PROJECT : Mini Task Scheduler
; FILE    : scheduler_base.asm
; AUTHORS : Juwairiya, Muskan, Parwin, Maryam
; COURSE  : Computer Organization & Assembly Language
; DESC    : Simulates round-robin task scheduling using
;           procedure-based execution and loop timer.
;           Features: TCB, progress bars, switch counter,
;           task termination, and color-coded display.
; ============================================================

INCLUDE c:\Users\m\.vscode\extensions\istareatscreens.masm-runner-0.9.1\native\irvine\Irvine32.inc

black        = 0
green        = 2
lightGray    = 7
white        = 15

NUM_TASKS    EQU 4
TCB_SIZE     EQU 20
STACK_SIZE   EQU 128
MAX_ITER     EQU 30

TCB_EIP      EQU 0
TCB_ESP      EQU 4
TCB_EAX      EQU 8
TCB_EBX      EQU 12
TCB_STATUS   EQU 16

INACTIVE     EQU 0
READY        EQU 1
RUNNING      EQU 2

; ============================================================
; DATA SEGMENT
; ============================================================
.data
    TCB_ARRAY    BYTE (NUM_TASKS * TCB_SIZE) DUP(0)

    TASK0_STACK  BYTE STACK_SIZE DUP(0)
    TASK1_STACK  BYTE STACK_SIZE DUP(0)
    TASK2_STACK  BYTE STACK_SIZE DUP(0)
    TASK3_STACK  BYTE STACK_SIZE DUP(0)

    CURRENT_TASK  DWORD 0
    TASK_COUNT    DWORD 0
    switch_count  DWORD 0

    ; Display strings
    msg_title    BYTE "==============================", 0dh, 0ah
                 BYTE "      MINI TASK SCHEDULER     ", 0dh, 0ah, 0
    msg_team     BYTE "  Juwairiya Muskan Parwin Maryam", 0dh, 0ah, 0
    msg_switches BYTE "  Context switches: ", 0
    msg_sep      BYTE "==============================", 0dh, 0ah, 0
    msg_task0    BYTE "  Task 0 (Counter  x1): ", 0
    msg_task1    BYTE "  Task 1 (Counter  x2): ", 0
    msg_task2    BYTE "  Task 2 (Multiply x3): ", 0
    msg_task3    BYTE "  Task 3 (A-Z Cycle  ): ", 0
    msg_running  BYTE "RUNNING  ", 0
    msg_ready    BYTE "READY    ", 0
    msg_inactive BYTE "INACTIVE ", 0
    msg_val      BYTE " val=", 0
    msg_newline  BYTE 0dh, 0ah, 0
    msg_bar_open  BYTE " [", 0
    msg_bar_fill  BYTE "#", 0
    msg_bar_empty BYTE "-", 0
    msg_bar_close BYTE "] ", 0

    msg_done     BYTE "==============================", 0dh, 0ah
                 BYTE "      All tasks completed!    ", 0dh, 0ah
                 BYTE "      Scheduler exiting.      ", 0dh, 0ah
                 BYTE "==============================", 0dh, 0ah, 0
    msg_final_t0 BYTE "  Task 0 final counter  : ", 0
    msg_final_t1 BYTE "  Task 1 final counter  : ", 0
    msg_final_t2 BYTE "  Task 2 final result   : ", 0
    msg_final_t3 BYTE "  Task 3 final letter   : ", 0

    msg_init     BYTE "Initializing tasks...", 0dh, 0ah, 0
    msg_go       BYTE "Starting scheduler...", 0dh, 0ah, 0

    ; Task variables
    counter0     DWORD 0
    counter1     DWORD 0
    result2      DWORD 0
    current_char BYTE  41h

    ; Iteration counters
    iter0        DWORD 0
    iter1        DWORD 0
    iter2        DWORD 0
    iter3        DWORD 0

; ============================================================
; CODE SEGMENT
; ============================================================
.code

; ============================================================
; MAIN — Juwairiya
; ============================================================
main PROC
    call    Clrscr
    mov     edx, OFFSET msg_init
    call    WriteString
    call    INIT_TASKS
    mov     edx, OFFSET msg_go
    call    WriteString

    ; Brief pause so user can read startup message
    mov     ecx, 2000000
startup_delay:
    loop    startup_delay

    call    START_SCHEDULER
    exit
main ENDP

; ============================================================
; INIT_TASKS — Juwairiya
; ============================================================
INIT_TASKS PROC
    mov     eax, OFFSET TASK0_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 0  + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 0  + TCB_STATUS], READY

    mov     eax, OFFSET TASK1_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 20 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 20 + TCB_STATUS], READY

    mov     eax, OFFSET TASK2_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 40 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 40 + TCB_STATUS], READY

    mov     eax, OFFSET TASK3_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 60 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 60 + TCB_STATUS], READY

    mov     TASK_COUNT, NUM_TASKS
    ret
INIT_TASKS ENDP

; ============================================================
; START_SCHEDULER — Muskan
; ============================================================
START_SCHEDULER PROC

sched_loop:
    ; Check if ALL tasks are inactive
    movzx   eax, BYTE PTR [TCB_ARRAY + 0  + TCB_STATUS]
    movzx   ebx, BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS]
    movzx   ecx, BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS]
    movzx   edx, BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS]
    cmp     eax, INACTIVE
    jne     run_tasks
    cmp     ebx, INACTIVE
    jne     run_tasks
    cmp     ecx, INACTIVE
    jne     run_tasks
    cmp     edx, INACTIVE
    jne     run_tasks

    ; All done — show final screen
    call    Clrscr
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_done
    call    WriteString

    mov     edx, OFFSET msg_final_t0
    call    WriteString
    mov     eax, [counter0]
    call    WriteDec
    call    Crlf

    mov     edx, OFFSET msg_final_t1
    call    WriteString
    mov     eax, [counter1]
    call    WriteDec
    call    Crlf

    mov     edx, OFFSET msg_final_t2
    call    WriteString
    mov     eax, [result2]
    call    WriteDec
    call    Crlf

    mov     edx, OFFSET msg_final_t3
    call    WriteString
    movzx   eax, BYTE PTR [current_char]
    call    WriteChar
    call    Crlf

    mov     edx, OFFSET msg_sep
    call    WriteString
    call    WaitMsg
    ret

run_tasks:
    ; ---- Task 0 ----
    movzx   eax, BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task0
    mov     CURRENT_TASK, 0
    mov     BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS], RUNNING
    inc     switch_count
    call    DISPLAY_STATUS
    call    DO_TASK0
    movzx   eax, BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task0
    mov     BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS], READY
skip_task0:

    ; ---- Task 1 ----
    movzx   eax, BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task1
    mov     CURRENT_TASK, 1
    mov     BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS], RUNNING
    inc     switch_count
    call    DISPLAY_STATUS
    call    DO_TASK1
    movzx   eax, BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task1
    mov     BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS], READY
skip_task1:

    ; ---- Task 2 ----
    movzx   eax, BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task2
    mov     CURRENT_TASK, 2
    mov     BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS], RUNNING
    inc     switch_count
    call    DISPLAY_STATUS
    call    DO_TASK2
    movzx   eax, BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task2
    mov     BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS], READY
skip_task2:

    ; ---- Task 3 ----
    movzx   eax, BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task3
    mov     CURRENT_TASK, 3
    mov     BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS], RUNNING
    inc     switch_count
    call    DISPLAY_STATUS
    call    DO_TASK3
    movzx   eax, BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS]
    cmp     eax, INACTIVE
    je      skip_task3
    mov     BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS], READY
skip_task3:

    jmp     sched_loop

START_SCHEDULER ENDP

; ============================================================
; TIMER_DELAY — Muskan
; ============================================================
TIMER_DELAY PROC
    push    ecx
    mov     ecx, 5000000
timer_loop:
    loop    timer_loop
    pop     ecx
    ret
TIMER_DELAY ENDP

; ============================================================
; DO_TASK0 — Parwin (Counter x1, terminates after MAX_ITER)
; ============================================================
DO_TASK0 PROC
    mov     eax, [iter0]
    cmp     eax, MAX_ITER
    jl      task0_run
    mov     BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS], INACTIVE
    ret
task0_run:
    mov     eax, [counter0]
    inc     eax
    mov     [counter0], eax
    inc     DWORD PTR [iter0]
    call    TIMER_DELAY
    ret
DO_TASK0 ENDP

; ============================================================
; DO_TASK1 — Parwin (Counter x2, terminates after MAX_ITER)
; ============================================================
DO_TASK1 PROC
    mov     eax, [iter1]
    cmp     eax, MAX_ITER
    jl      task1_run
    mov     BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS], INACTIVE
    ret
task1_run:
    mov     eax, [counter1]
    add     eax, 2
    mov     [counter1], eax
    inc     DWORD PTR [iter1]
    call    TIMER_DELAY
    ret
DO_TASK1 ENDP

; ============================================================
; DO_TASK2 — Parwin (Multiply x3, terminates after MAX_ITER)
; ============================================================
DO_TASK2 PROC
    mov     eax, [iter2]
    cmp     eax, MAX_ITER
    jl      task2_run
    mov     BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS], INACTIVE
    ret
task2_run:
    mov     eax, [counter0]
    mov     ebx, 3
    mul     ebx
    mov     [result2], eax
    inc     DWORD PTR [iter2]
    call    TIMER_DELAY
    ret
DO_TASK2 ENDP

; ============================================================
; DO_TASK3 — Parwin (A-Z cycle, terminates after MAX_ITER)
; ============================================================
DO_TASK3 PROC
    mov     eax, [iter3]
    cmp     eax, MAX_ITER
    jl      task3_run
    mov     BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS], INACTIVE
    ret
task3_run:
    movzx   eax, BYTE PTR [current_char]
    inc     eax
    cmp     eax, 5Bh
    jl      save_char
    mov     eax, 41h
save_char:
    mov     BYTE PTR [current_char], al
    inc     DWORD PTR [iter3]
    call    TIMER_DELAY
    ret
DO_TASK3 ENDP

; ============================================================
; DISPLAY_STATUS — Maryam
; ============================================================
DISPLAY_STATUS PROC
    pushad
    call    Clrscr

    ; Header
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_title
    call    WriteString
    mov     edx, OFFSET msg_team
    call    WriteString
    mov     edx, OFFSET msg_switches
    call    WriteString
    mov     eax, [switch_count]
    call    WriteDec
    call    Crlf
    mov     edx, OFFSET msg_sep
    call    WriteString

    ; =====================
    ; TASK 0
    ; =====================
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_task0
    call    WriteString

    movzx   ecx, BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS]
    cmp     ecx, INACTIVE
    jne     t0_check_running
    mov     eax, lightGray + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_inactive
    call    WriteString
    jmp     t0_progress
t0_check_running:
    cmp     CURRENT_TASK, 0
    jne     t0_ready
    mov     eax, green + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_running
    call    WriteString
    jmp     t0_progress
t0_ready:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_ready
    call    WriteString

t0_progress:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_bar_open
    call    WriteString
    mov     ecx, [iter0]
    cmp     ecx, 0
    je      t0_empty_bars
t0_fill_loop:
    mov     edx, OFFSET msg_bar_fill
    call    WriteString
    loop    t0_fill_loop
t0_empty_bars:
    mov     eax, MAX_ITER
    sub     eax, [iter0]
    mov     ecx, eax
    cmp     ecx, 0
    je      t0_bar_done
t0_empty_loop:
    mov     edx, OFFSET msg_bar_empty
    call    WriteString
    loop    t0_empty_loop
t0_bar_done:
    mov     edx, OFFSET msg_bar_close
    call    WriteString
    mov     edx, OFFSET msg_val
    call    WriteString
    mov     eax, [counter0]
    call    WriteDec
    mov     edx, OFFSET msg_newline
    call    WriteString

    ; =====================
    ; TASK 1
    ; =====================
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_task1
    call    WriteString

    movzx   ecx, BYTE PTR [TCB_ARRAY + 20 + TCB_STATUS]
    cmp     ecx, INACTIVE
    jne     t1_check_running
    mov     eax, lightGray + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_inactive
    call    WriteString
    jmp     t1_progress
t1_check_running:
    cmp     CURRENT_TASK, 1
    jne     t1_ready
    mov     eax, green + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_running
    call    WriteString
    jmp     t1_progress
t1_ready:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_ready
    call    WriteString

t1_progress:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_bar_open
    call    WriteString
    mov     ecx, [iter1]
    cmp     ecx, 0
    je      t1_empty_bars
t1_fill_loop:
    mov     edx, OFFSET msg_bar_fill
    call    WriteString
    loop    t1_fill_loop
t1_empty_bars:
    mov     eax, MAX_ITER
    sub     eax, [iter1]
    mov     ecx, eax
    cmp     ecx, 0
    je      t1_bar_done
t1_empty_loop:
    mov     edx, OFFSET msg_bar_empty
    call    WriteString
    loop    t1_empty_loop
t1_bar_done:
    mov     edx, OFFSET msg_bar_close
    call    WriteString
    mov     edx, OFFSET msg_val
    call    WriteString
    mov     eax, [counter1]
    call    WriteDec
    mov     edx, OFFSET msg_newline
    call    WriteString

    ; =====================
    ; TASK 2
    ; =====================
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_task2
    call    WriteString

    movzx   ecx, BYTE PTR [TCB_ARRAY + 40 + TCB_STATUS]
    cmp     ecx, INACTIVE
    jne     t2_check_running
    mov     eax, lightGray + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_inactive
    call    WriteString
    jmp     t2_progress
t2_check_running:
    cmp     CURRENT_TASK, 2
    jne     t2_ready
    mov     eax, green + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_running
    call    WriteString
    jmp     t2_progress
t2_ready:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_ready
    call    WriteString

t2_progress:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_bar_open
    call    WriteString
    mov     ecx, [iter2]
    cmp     ecx, 0
    je      t2_empty_bars
t2_fill_loop:
    mov     edx, OFFSET msg_bar_fill
    call    WriteString
    loop    t2_fill_loop
t2_empty_bars:
    mov     eax, MAX_ITER
    sub     eax, [iter2]
    mov     ecx, eax
    cmp     ecx, 0
    je      t2_bar_done
t2_empty_loop:
    mov     edx, OFFSET msg_bar_empty
    call    WriteString
    loop    t2_empty_loop
t2_bar_done:
    mov     edx, OFFSET msg_bar_close
    call    WriteString
    mov     edx, OFFSET msg_val
    call    WriteString
    mov     eax, [result2]
    call    WriteDec
    mov     edx, OFFSET msg_newline
    call    WriteString

    ; =====================
    ; TASK 3
    ; =====================
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_task3
    call    WriteString

    movzx   ecx, BYTE PTR [TCB_ARRAY + 60 + TCB_STATUS]
    cmp     ecx, INACTIVE
    jne     t3_check_running
    mov     eax, lightGray + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_inactive
    call    WriteString
    jmp     t3_progress
t3_check_running:
    cmp     CURRENT_TASK, 3
    jne     t3_ready
    mov     eax, green + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_running
    call    WriteString
    jmp     t3_progress
t3_ready:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_ready
    call    WriteString

t3_progress:
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_bar_open
    call    WriteString
    mov     ecx, [iter3]
    cmp     ecx, 0
    je      t3_empty_bars
t3_fill_loop:
    mov     edx, OFFSET msg_bar_fill
    call    WriteString
    loop    t3_fill_loop
t3_empty_bars:
    mov     eax, MAX_ITER
    sub     eax, [iter3]
    mov     ecx, eax
    cmp     ecx, 0
    je      t3_bar_done
t3_empty_loop:
    mov     edx, OFFSET msg_bar_empty
    call    WriteString
    loop    t3_empty_loop
t3_bar_done:
    mov     edx, OFFSET msg_bar_close
    call    WriteString
    mov     edx, OFFSET msg_val
    call    WriteString
    movzx   eax, BYTE PTR [current_char]
    call    WriteChar
    mov     edx, OFFSET msg_newline
    call    WriteString

    ; Footer
    mov     eax, white + (black * 16)
    call    SetTextColor
    mov     edx, OFFSET msg_sep
    call    WriteString

    popad
    ret
DISPLAY_STATUS ENDP

END main