# AES-Encryption-Module
This AES general purpose encryption module can encrypt 128-bit plaintexts with 128-bit keys. Written in verilog, featuring ready-valid interface to encrypt key and plaintext pairs.

## Features
- 4 sbox design using lookup tables
- 2 stage pipeline
- 5 cycles per round
- 1 cycle to load data, 50 cycles rounds, 2 cycles at end until cipher visible to consumer, 53 cycles total
- 128-bit key, state and output registers, 4-bit round register, 1-bit done flag (+ 32-bit pipeline register if no BRAM is inferred)
- Designed using ready-valid protocol to process a stream of key and plaintext pairs
- Optimized for throughput: Consuming a cipher from the out register before the current encryption is finished allows for full sbox utilization at every cycle, assuming next plaintext and key are present
- Optimized for minimal register overhead: only three 128-bit registers
- Sbox implemented in a way for tools to infer BRAM, this serves as pipeline stage
- Addition of an output register was chosen to save 2 cycles after data is ready. This way new data can already be processed and the sbox is not idle for those 2 cycles
- If calculated cipher is not consumed, next input will be encrypted until last cycle before writeback to output register
- Not optimized for repeated encryptions with same key



## Operation
- Plaintext is xored with key and stored in state register, key is stored in key register.
- The following steps are repeated until last round:
	-  Schedule key_w3 to sbox for the expandkey operation, in the meantime perform shiftrows on state register. This allows writeback to the state words without overwriting data that is still to be scheduled to the sbox.
	- One after the other schedule state_w0, w1, w2 and w3 to sbox:
	- While state_w0 is scheduled to sbox, the expandkey operation is performed and written back to key register.
	- While state_w1 is scheduled, transformed state_w0 is ready on the sbox output pipeline stage. Calculate mixcolumn, add roundkey from key_w0 register and write back to state_w0.
	- Repeat above step for state_w2 and state_w3, perform mixcolumn and add roundkeys in the same manner, except in round 10 bypass mixcolumn.
- During the last round while state_w3 is scheduled, and if the out register is available next cycle, in_ready is asserted to load new data and begin new encryption for full sbox utilization.
- If the out register is blocked by the result of the previous encryption the design will stall until it is available again.
	
