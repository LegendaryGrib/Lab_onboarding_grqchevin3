from typing import Protocol


class DatabaseConnection(Protocol):
    def get_balance(self, user_id: str) -> float:
        ...

    def update_balance(self, user_id: str, balance: float) -> None:
        ...


def process_transaction(
    user_id: str, amount: float, db_connection: DatabaseConnection
) -> str:
    status = "pending"

    if amount > 0:
        status = "approved"
        balance = db_connection.get_balance(user_id)
        new_balance = balance - amount
        db_connection.update_balance(user_id, new_balance)

    log_entry = f"Transaction finished with status: {status}"

    with open("audit_log.txt", "w", encoding="utf-8") as audit_file:
        audit_file.write(log_entry)

    return status
