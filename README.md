# Interrupt-Based-Mini-Task-Scheduler-in-x86

##  Overview

This project implements a simplified **interrupt-driven task scheduler** using **8086 Assembly Language**. It simulates basic operating system multitasking by switching between multiple tasks using a timer-based mechanism.

The project demonstrates core low-level concepts such as:

* Interrupt handling
* Context switching
* Stack operations
* CPU scheduling

---

##  Features

*  Timer-based task switching (simulated interrupt mechanism)
*  Context switching using register save/restore
*  Multiple simple tasks (e.g., counters, loops)
*  Output display for active task tracking
*  Testing of scheduling scenarios

---

##  System Architecture

The scheduler works by:

1. Triggering a timer interrupt (simulated)
2. Saving the current task state (registers + stack)
3. Switching to the next task
4. Restoring its execution context
5. Continuing execution

This cycle repeats, creating the illusion of multitasking.

---

##  Team & Responsibilities

### 1. Juwairiya Haroon

* System architecture design
* Logic flow development
* Integration of all modules

### 2. Muskan Ejaz

* Scheduling algorithm implementation
* Context switching (register save/restore)
* Low-level debugging

### 3. Maryam Nor

* I/O interfacing
* Output display handling
* System testing

### 4. Parwin

* Task creation (counters/loops)
* Timer simulation
* Execution routines

---

##  Key Concepts Demonstrated

* Interrupt handling in 8086
* Cooperative multitasking
* Stack-based context switching
* Low-level CPU control
* Assembly-level debugging

---

##  Technologies Used

* 8086 Assembly Language
* DOS-based execution environment (e.g., EMU8086 / DOSBox)

---

##  How to Run

1. Open the project in an 8086 emulator (e.g., EMU8086)
2. Assemble the code
3. Run the program
4. Observe task switching and output behavior

---

##  Example Behavior

* Multiple tasks run seemingly in parallel
* Output shows switching between tasks
* Counters or loops update based on scheduler timing

---

##  Learning Outcomes

This project helps in understanding:

* How operating systems manage multiple tasks
* How CPUs handle interrupts
* How context switching works at a low level

---

##  Future Improvements

* Real hardware timer integration
* Priority-based scheduling
* Dynamic task addition/removal
* Enhanced UI output

---
