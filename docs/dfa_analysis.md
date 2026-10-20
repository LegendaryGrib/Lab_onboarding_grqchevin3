# DFA: Def-Use Analysis

The line numbers below refer to the original `process_transaction` fragment in
Practice 7, not the fixed implementation.

| Variable | Definition (def) | Use (use) | Data-flow notes |
| --- | --- | --- | --- |
| `user_id` | Function parameter, line 1 | Lines 6 and 8 | Used to read and update the user's balance. |
| `amount` | Function parameter, line 1 | Line 4 | Controls whether the transaction block executes. |
| `db_connection` | Function parameter, line 1 | None | The provided fragment does not use this parameter. |
| `log_entry` | Line 2, then redefined on line 10 | Line 13 | The value from line 2 is overwritten before it is read (dead store). |
| `status` | Line 5, only if `amount > 0` | Lines 10 and 15 | If `amount <= 0`, it is read without being defined, raising `UnboundLocalError`. |
| `balance` | Line 6, only if `amount > 0` | Line 7 | The read on line 7 follows its definition within the same branch. |
| `new_balance` | Line 7, only if `amount > 0` | Line 8 | The value is passed to `update_balance`. |
| `file` | Line 12 | Line 13 | The file is written but never explicitly closed. |

## Defects found

1. **Uninitialized variable:** `status` is assigned only inside `if amount > 0`
   (line 5) but read on line 10 and returned on line 15. For `amount <= 0`,
   Python raises `UnboundLocalError`.
2. **Dead store:** the initial value assigned to `log_entry` on line 2 is
   overwritten on line 10 before any read.
3. **Resource leak:** line 12 opens `audit_log.txt`, and line 13 writes to it,
   but the fragment never closes the file. A context manager ensures closure.
