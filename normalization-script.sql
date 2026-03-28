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