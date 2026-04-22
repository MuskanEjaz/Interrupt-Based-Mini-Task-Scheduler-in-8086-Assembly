; ============================================================
; PROJECT : Mini Task Scheduler
; FILE    : scheduler_base.asm
; AUTHOR  : Juwairiya (Phase 1 - Architecture & Integration)
; PURPOSE : Defines memory layout, TCB structure, and task
;           stubs. All team members build on this file.
; ============================================================

INCLUDE Irvine32.inc

; ============================================================
; CONSTANTS — change values here only, nowhere else
; ============================================================
NUM_TASKS   EQU 4       ; total number of tasks
TCB_SIZE    EQU 20      ; bytes per TCB entry (keep at 20)
STACK_SIZE  EQU 128     ; bytes per task's private stack

; --- TCB field offsets (byte position inside one TCB entry) ---
; Muskan uses these constants to read/write each field.
; Never use raw numbers like [TCB_ARRAY + 2] — always use these.
TCB_EIP     EQU 0       ; saved instruction pointer  (4 bytes)
TCB_ESP     EQU 4       ; saved stack pointer        (4 bytes)
TCB_EAX     EQU 8       ; saved EAX                  (4 bytes)
TCB_EBX     EQU 12      ; saved EBX                  (4 bytes)
TCB_STATUS  EQU 16      ; task status byte           (1 byte)
                        ; 3 padding bytes at 17,18,19
                        ; total = 20 bytes per entry

; --- Task status codes ---
INACTIVE    EQU 0       ; task does not exist / finished
READY       EQU 1       ; task is waiting for CPU time
RUNNING     EQU 2       ; task is currently executing

; ============================================================
; DATA SEGMENT
; ============================================================
.data
    ; ----------------------------------------------------------
    ; TCB ARRAY
    ; 4 tasks x 20 bytes = 80 bytes total, all zeroed at start.
    ; Layout in memory:
    ;   [0..19]  = Task 0 TCB
    ;   [20..39] = Task 1 TCB
    ;   [40..59] = Task 2 TCB
    ;   [60..79] = Task 3 TCB
    ; ----------------------------------------------------------
    TCB_ARRAY   BYTE (NUM_TASKS * TCB_SIZE) DUP(0)

    ; ----------------------------------------------------------
    ; PRIVATE STACKS
    ; Each task gets its own 128-byte stack block.
    ; Stack grows DOWNWARD so the initial SP points to the
    ; END of each block (highest address), not the start.
    ; ----------------------------------------------------------
    TASK0_STACK BYTE STACK_SIZE DUP(0)
    TASK1_STACK BYTE STACK_SIZE DUP(0)
    TASK2_STACK BYTE STACK_SIZE DUP(0)
    TASK3_STACK BYTE STACK_SIZE DUP(0)

    ; ----------------------------------------------------------
    ; SCHEDULER STATE
    ; Muskan's scheduler reads and updates CURRENT_TASK.
    ; Maryam's display routine reads it to show active task.
    ; ----------------------------------------------------------
    CURRENT_TASK    DWORD 0     ; index of currently running task (0-3)
    TASK_COUNT      DWORD 0     ; how many tasks are initialized

    ; ----------------------------------------------------------
    ; DISPLAY STRINGS — Maryam fills these in
    ; ----------------------------------------------------------
    msg_init    BYTE "Scheduler initialized. Tasks ready.", 0dh, 0ah, 0
    msg_start   BYTE "Starting scheduler...", 0dh, 0ah, 0
    msg_done    BYTE "All tasks complete.", 0dh, 0ah, 0

    ; ----------------------------------------------------------
    ; TASK VARIABLES — Parwin
    ; ----------------------------------------------------------
    counter0     DWORD 0     ; Task 0 counter (counts by 1)
    counter1     DWORD 0     ; Task 1 counter (counts by 2)
    result2      DWORD 0     ; Task 2 arithmetic result
    current_char BYTE 41h   ; Task 3 current letter (starts at 'A')

; ============================================================
; CODE SEGMENT
; ============================================================
.code

; ============================================================
; MAIN — entry point, Juwairiya owns this
; Sequence: init tasks → print status → start scheduler
; ============================================================
main PROC
    call    Clrscr

    ; Print init message
    mov     edx, OFFSET msg_init
    call    WriteString

    ; Initialize all 4 task TCBs
    call    INIT_TASKS

    ; Print confirmation
    mov     edx, OFFSET msg_start
    call    WriteString

    ; === PHASE 2 HOOK: Muskan's scheduler replaces this ===
    call  START_SCHEDULER

    ; === PHASE 3 HOOK: Maryam's display runs inside scheduler ===

    ; For now, confirm tasks were set up correctly
    call    VERIFY_TASKS

    mov     edx, OFFSET msg_done
    call    WriteString

    call    WaitMsg         ; pause so window doesn't close
    exit
main ENDP

; ============================================================
; INIT_TASKS — Juwairiya writes this
; Fills each TCB with the task's starting EIP, ESP, status.
; Called once at startup before the scheduler begins.
; ============================================================
INIT_TASKS PROC
    ; --- Task 0 --- (offset = 0 * 20 = 0)
    mov     eax, OFFSET TASK0
    mov     DWORD PTR [TCB_ARRAY + 0 + TCB_EIP], eax
    mov     eax, OFFSET TASK0_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 0 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 0 + TCB_STATUS], READY

    ; --- Task 1 --- (offset = 1 * 20 = 20)
    mov     eax, OFFSET TASK1
    mov     DWORD PTR [TCB_ARRAY + 20 + TCB_EIP], eax
    mov     eax, OFFSET TASK1_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 20 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 20 + TCB_STATUS], READY

    ; --- Task 2 --- (offset = 2 * 20 = 40)
    mov     eax, OFFSET TASK2
    mov     DWORD PTR [TCB_ARRAY + 40 + TCB_EIP], eax
    mov     eax, OFFSET TASK2_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 40 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 40 + TCB_STATUS], READY

    ; --- Task 3 --- (offset = 3 * 20 = 60)
    mov     eax, OFFSET TASK3
    mov     DWORD PTR [TCB_ARRAY + 60 + TCB_EIP], eax
    mov     eax, OFFSET TASK3_STACK + STACK_SIZE
    mov     DWORD PTR [TCB_ARRAY + 60 + TCB_ESP], eax
    mov     BYTE PTR  [TCB_ARRAY + 60 + TCB_STATUS], READY

    mov     TASK_COUNT, NUM_TASKS
    ret
INIT_TASKS ENDP

; ============================================================
; VERIFY_TASKS — Juwairiya writes this (debug/testing tool)
; Reads each TCB and prints the saved EIP so you can confirm
; INIT_TASKS ran correctly before handing off to the team.
; Maryam will replace this with proper display later.
; ============================================================
VERIFY_TASKS PROC
    mov     ecx, NUM_TASKS      ; loop 4 times
    mov     esi, 0              ; task index
    mov     edi, 0              ; byte offset into TCB_ARRAY

verify_loop:
    ; print task index
    mov     eax, esi
    call    WriteDec
    mov     al, ':'
    call    WriteChar

    ; manually calculate offset = index * 20
    ; instead of esi*TCB_SIZE (20 is not a valid scale factor)
    mov     eax, esi
    mov     ebx, TCB_SIZE       ; ebx = 20
    mul     ebx                 ; eax = esi * 20
    mov     edi, eax            ; edi = byte offset of this TCB

    ; read saved EIP from this TCB entry
    mov     eax, DWORD PTR [TCB_ARRAY + edi + TCB_EIP]
    call    WriteHex
    call    Crlf

    inc     esi
    loop    verify_loop

    ret
VERIFY_TASKS ENDP

; ============================================================
; CONTEXT_SWITCH — Muskan Ejaz
; Saves current task state, finds next READY task, restores & jumps
; ============================================================
CONTEXT_SWITCH PROC
    pushad                          ; save all registers (8 x 4 = 32 bytes)

    ; Return address is now at [esp+32]
    mov     edi, [esp + 32]         ; EDI = saved EIP of current task

    ; --- Save current task state into its TCB ---
    mov     eax, CURRENT_TASK
    push    eax                     ; save index
    mov     ebx, TCB_SIZE
    mul     ebx                     ; EAX = current_task * 20
    mov     esi, eax                ; ESI = TCB byte offset

    ; Save EIP
    mov     DWORD PTR [TCB_ARRAY + esi + TCB_EIP], edi

    ; Save ESP (real ESP = esp + 32 pushad + 4 return addr = esp+36)
    mov     eax, esp
    add     eax, 36
    mov     DWORD PTR [TCB_ARRAY + esi + TCB_ESP], eax

    ; Save EAX (at [esp+28] in pushad layout)
    mov     eax, [esp + 28]
    mov     DWORD PTR [TCB_ARRAY + esi + TCB_EAX], eax

    ; Save EBX (at [esp+16] in pushad layout)
    mov     eax, [esp + 16]
    mov     DWORD PTR [TCB_ARRAY + esi + TCB_EBX], eax

    ; Mark current task as READY
    mov     BYTE PTR [TCB_ARRAY + esi + TCB_STATUS], READY

    pop     eax                     ; restore current task index

    ; --- Find next READY task ---
find_next:
    inc     eax
    cmp     eax, NUM_TASKS
    jl      check_this
    mov     eax, 0                  ; wrap around
check_this:
    push    eax                     ; save candidate index
    mov     ebx, TCB_SIZE
    mul     ebx                     ; EAX = candidate * 20
    movzx   ecx, BYTE PTR [TCB_ARRAY + eax + TCB_STATUS]
    pop     eax                     ; restore candidate index
    cmp     ecx, READY
    jne     find_next               ; not ready, try next

    ; --- Switch to next task ---
    mov     CURRENT_TASK, eax

    push    eax
    mov     ebx, TCB_SIZE
    mul     ebx
    mov     esi, eax
    pop     eax

    ; Mark new task RUNNING
    mov     BYTE PTR [TCB_ARRAY + esi + TCB_STATUS], RUNNING

    ; Restore next task's registers
    mov     eax, DWORD PTR [TCB_ARRAY + esi + TCB_EAX]
    mov     ebx, DWORD PTR [TCB_ARRAY + esi + TCB_EBX]
    mov     esp, DWORD PTR [TCB_ARRAY + esi + TCB_ESP]

    ; Jump to next task
    jmp     DWORD PTR [TCB_ARRAY + esi + TCB_EIP]

CONTEXT_SWITCH ENDP

; ============================================================
; START_SCHEDULER — Muskan Ejaz
; Entry point for the scheduler, begins with Task 0
; ============================================================
START_SCHEDULER PROC
    mov     CURRENT_TASK, 0
    mov     BYTE PTR [TCB_ARRAY + 0 + TCB_STATUS], RUNNING
    jmp     DWORD PTR [TCB_ARRAY + 0 + TCB_EIP]
START_SCHEDULER ENDP

; ============================================================
; TIMER_TICK — Muskan Ejaz
; Software delay simulating a timer. Tasks call this periodically.
; ============================================================
TIMER_TICK PROC
    push    ecx
    mov     ecx, 100000
timer_loop:
    loop    timer_loop
    pop     ecx
    call    CONTEXT_SWITCH
    ret
TIMER_TICK ENDP

; ============================================================
; TASK STUBS — Parwin's real task code
; DO NOT rename these labels — TCB entries point to them.
; ============================================================
TASK0 PROC
    ; Counter task — increments counter0 by 1
    mov     eax, [counter0]
    inc     eax
    mov     [counter0], eax

    ; Delay loop — simulates work
    mov     ecx, 50000
delay0:
    loop    delay0

    call    TIMER_TICK
    jmp     TASK0
TASK0 ENDP

TASK1 PROC
    ; Counter task — increments counter1 by 2
    mov     eax, [counter1]
    add     eax, 2
    mov     [counter1], eax

    ; Delay loop
    mov     ecx, 50000
delay1:
    loop    delay1

    call    TIMER_TICK
    jmp     TASK1
TASK1 ENDP

TASK2 PROC
    ; Arithmetic task — multiplies counter0 by 3, stores in result2
    mov     eax, [counter0]
    mov     ebx, 3
    mul     ebx
    mov     [result2], eax

    ; Delay loop
    mov     ecx, 50000
delay2:
    loop    delay2

    call    TIMER_TICK
    jmp     TASK2
TASK2 ENDP

TASK3 PROC
    ; Letter cycling task — cycles A through Z
    movzx   eax, [current_char]
    inc     eax
    cmp     eax, 5Bh        ; past 'Z'?
    jl      save_char
    mov     eax, 41h        ; reset to 'A'
save_char:
    mov     [current_char], al

    ; Delay loop
    mov     ecx, 50000
delay3:
    loop    delay3

    call    TIMER_TICK
    jmp     TASK3
TASK3 ENDP

END main