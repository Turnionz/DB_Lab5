Проблемними таблицями є Ticket та Employee з наступною структурою залежностей

> ticket_id -> user_id, trip_number, departing_station, arrival_station, departing_order, arrival_order, last_name, first_name, wagon_number, seat_number
> 
> employee_id -> train_id, employee_type

В таблиці Ticket можна винести seat_number як FK seat_id та також винести пассажира в нову таблицю Passenger. (Було порушення 3NF)
В таблиці Employee є проблема з train_id, він порушує 1NF бо ми створюємо дуплікати, якщо хочемо записати одного працівника на декілька потягів. Тому створюємо нову таблицю Crew_Assignment  

>*departing/arrival station/order ми не виносимо в нову таблицю*
>
>Причина цього є оптимізація, бо ці поля в нас існують не тільки для показу при покупці квитка, але й для перевірки під час оформлення квитка, якщо ці дані винести в іншу таблцию запити будуть займати забагато часу (в нас було би забагато JOIN запитів, що грузили би систему).

Спочатку побудємо нову таблицю Passenger, потім додаємо нові поля в Ticket (passenger_id, seat_id). Переносимо дані з Ticket в Passenger та з'єднуємо з існуючими квитками, теж саме робимо з Seat. Видаляємо старі поля котрі нам вже непотрібні.

Структура Passenger:

> PK passenger_id
> FK user_id
> last_name
> first_name

Структура Crew_Assignment:

> PK assignment_id
> FK eployee_id
> FK  train_id
> shift_date

```sql
CREATE TABLE IF NOT EXISTS Passenger(
    passenger_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES Client_User(user_id),
    last_name VARCHAR(32) NOT NULL,
    first_name VARCHAR(32) NOT NULL
);

ALTER TABLE Ticket 
    ADD COLUMN passenger_id INT, 
    ADD COLUMN seat_id INT;

ALTER TABLE Ticket 
    ADD FOREIGN KEY (passenger_id) REFERENCES Passenger(passenger_id),
    ADD FOREIGN KEY (seat_id) REFERENCES Seat(seat_id);

DO $$
DECLARE
    ticket_record RECORD; 
    new_pass_id INTEGER;  
BEGIN
    FOR ticket_record IN 
        SELECT ticket_id, user_id, first_name, last_name 
        FROM Ticket 
        WHERE passenger_id IS NULL AND first_name IS NOT NULL
    LOOP
        INSERT INTO Passenger (user_id, first_name, last_name)
        VALUES (ticket_record.user_id, ticket_record.first_name, ticket_record.last_name)
        RETURNING passenger_id INTO new_pass_id;

        UPDATE Ticket
        SET passenger_id = new_pass_id
        WHERE ticket_id = ticket_record.ticket_id;
    END LOOP;
END $$;

UPDATE Ticket t
SET seat_id = s.seat_id
FROM Seat s
JOIN Wagon w ON s.wagon_id = w.wagon_id
JOIN Trip tr ON w.train_id = tr.train_id
WHERE t.trip_number = tr.trip_number
  AND t.wagon_number = w.wagon_number 
  AND t.seat_number = s.seat_number;

DELETE FROM Ticket 
WHERE seat_id IS NULL OR passenger_id IS NULL;

ALTER TABLE Ticket
    ALTER COLUMN passenger_id SET NOT NULL,
    ALTER COLUMN seat_id SET NOT NULL;

ALTER TABLE Ticket 
    DROP COLUMN user_id,
    DROP COLUMN last_name,
    DROP COLUMN first_name,
    DROP COLUMN wagon_number,
    DROP COLUMN seat_number;

CREATE TABLE IF NOT EXISTS Crew_Assignment (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES Employee(employee_id),
    train_id INT NOT NULL REFERENCES Train(train_id),
    shift_date DATE NOT NULL DEFAULT CURRENT_DATE
);

INSERT INTO Crew_Assignment (employee_id, train_id)
SELECT employee_id, train_id 
FROM Employee 
WHERE train_id IS NOT NULL;

ALTER TABLE Employee 
    DROP COLUMN train_id;
```
