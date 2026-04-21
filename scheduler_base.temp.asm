; ============================================================
; PROJECT : Mini Task Scheduler
; FILE    : scheduler_base.asm
; AUTHOR  : Juwairiya (Phase 1 - Architecture & Integration)
; PURPOSE : Defines memory layout, TCB structure, and task
;           stubs. All team members build on this file.
; ============================================================

INCLUDE c:\Users\m\.vscode\extensions\istareatscreens.masm-runner-0.9.1\native\irvine\Irvine32.inc

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
    ; call  START_SCHEDULER

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
; TASK STUBS — Parwin replaces these with real task code.
; Each one is an infinite loop for now so the scheduler
; has something to switch between.
; DO NOT rename these labels — TCB entries point to them.
; ============================================================
TASK0 PROC
    ; Stub: Parwin replaces with counter task
    jmp     TASK0
TASK0 ENDP

TASK1 PROC
    ; Stub: Parwin replaces with display task
    jmp     TASK1
TASK1 ENDP

TASK2 PROC
    ; Stub: Parwin replaces with another routine
    jmp     TASK2
TASK2 ENDP

TASK3 PROC
    ; Stub: Parwin replaces with another routine
    jmp     TASK3
TASK3 ENDP

END main