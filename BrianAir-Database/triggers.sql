DROP TRIGGER IF EXISTS TicketNumberTrigger;

DELIMITER //
CREATE TRIGGER TicketNumberTrigger
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE passenger_id INT;
    DECLARE ticket_number INT;

    DECLARE cur CURSOR FOR 
        SELECT PassengerID 
        FROM PassengerList 
        WHERE ReservationNr = NEW.ReservationNr;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    

    read_loop: LOOP
        FETCH cur INTO passenger_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Generate a random 7-digit number (unguessable)
        SET ticket_number = FLOOR(RAND() * 9000000) + 1000000;

        -- Insert ticket
        INSERT INTO Ticket(TicketNr, ReservationNr, PassengerID)
        VALUES (ticket_number, NEW.ReservationNr, passenger_id);
    END LOOP;

    CLOSE cur;
END;

//
DELIMITER ;