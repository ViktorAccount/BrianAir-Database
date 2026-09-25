DROP PROCEDURE IF EXISTS deleteReservation;
DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;


DELIMITER //
CREATE PROCEDURE addYear(IN year_val INT, IN factor DOUBLE)
BEGIN
    INSERT INTO ProfitFactor(Year, ProfitFactor)
    VALUES (year_val, factor);
END
//

CREATE PROCEDURE addDay(IN year_val INT, IN day VARCHAR(10), IN factor DOUBLE)
BEGIN
    INSERT INTO WeekdayFactor(Year, Weekday, WeekdayFactor)
    VALUES (year_val, day, factor);
END
//

CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3), IN name VARCHAR(30), IN country VARCHAR(30))
BEGIN
    INSERT INTO Airport(AirportCode, Name, Country)
    VALUES (airport_code, name, country);
END
//

CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year_val INT, IN routeprice DOUBLE)
BEGIN
    INSERT INTO Route(Price, StartAirportID, EndAirportID, Year)
    VALUES (routeprice, departure_airport_code, arrival_airport_code, year_val);
END
//

CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year_val INT, IN day VARCHAR(10), IN departure_time TIME)
BEGIN
    DECLARE route_id INT;
    DECLARE last_weekly_schedule_id INT;
    DECLARE week_num INT DEFAULT 1;

    SELECT RouteID INTO route_id FROM Route 
    WHERE StartAirportID = departure_airport_code 
    AND EndAirportID = arrival_airport_code 
    AND Year = year_val
    LIMIT 1;

    IF route_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Route not found for the specified airport';
    END IF;


    INSERT INTO WeeklySchedule(Year, DayOfTheWeek, TimeOfDepature, RouteID)
    VALUES (year_val, day, departure_time, route_id);

    SET last_weekly_schedule_id = LAST_INSERT_ID();

    WHILE week_num <= 52 DO
        INSERT INTO Flight(WeekNr, WeeklyScheduleID, SeatConfirmed)
        VALUES  (week_num, last_weekly_schedule_id, 0);
        SET week_num = week_num + 1;
    END WHILE;
END
//

CREATE PROCEDURE addReservation(
    IN departure_airport_code VARCHAR(3),
    IN arrival_airport_code VARCHAR(3),
    IN year_val INT,
    IN week INT,
    IN day VARCHAR(10),
    IN time TIME,
    IN number_of_passengers INT,
    OUT output_reservation_nr INT
)
BEGIN
    DECLARE flight_number INT;
    DECLARE available_seats INT;
    DECLARE total_seats_confirmed INT;

    -- Find the flight number based on the input parameter
    SELECT FlightNumber INTO flight_number
    FROM Flight
    WHERE WeekNr = week
    AND WeeklyScheduleID IN (
        SELECT ScheduleID
        FROM WeeklySchedule
        WHERE Year = year_val
        AND DayOfTheWeek = day
        AND TimeOfDepature = time
    )
    LIMIT 1;

    IF flight_number IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'There exist no flight for the given route, date and time.';
    END IF;

    SELECT SeatConfirmed INTO total_seats_confirmed
    FROM Flight
    WHERE FlightNumber = flight_number
    LIMIT 1;

    SET available_seats = 40 - total_seats_confirmed;

    -- Step 3: Check availability
    IF number_of_passengers > available_seats THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'There are not enough seats available on the chosen flight';
    ELSE
        -- Step 4: Insert reservation
        INSERT INTO Reservation(SeatReserved, FlightNr,ContactInfoID)
        VALUES (number_of_passengers, flight_number, NULL);

        SET output_reservation_nr = LAST_INSERT_ID();
    END IF;

END
//

CREATE PROCEDURE addPassenger(
    IN reservation_nr INT, 
    IN passport_number INT,
    IN name VARCHAR(30)
)

BEGIN 
    DECLARE reservation_exists INT DEFAULT 0;
    DECLARE passenger_id INT;
    
    SELECT PassengerID INTO passenger_id
    FROM Passenger 
    WHERE PassportNr = passport_number
    LIMIT 1;

    -- Check if reservationNr is in Booking
    SELECT COUNT(*) INTO reservation_exists
    FROM Booking
    WHERE ReservationNr = reservation_nr;
    IF reservation_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The booking has already been payed and no further passengers can be added.';
    END IF;

    -- Check if reservation exists
    SELECT COUNT(*) INTO reservation_exists
    FROM Reservation
    WHERE ReservationNr = reservation_nr;

    IF reservation_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The given reservation number does not exist.';
    END IF;


    -- Check if we didnt find the passenger
    IF passenger_id IS NULL THEN
        INSERT INTO Passenger(PassportNr, Name)
        VALUES (passport_number, name);
        SET passenger_id = LAST_INSERT_ID();
    END IF;
    
    -- Check if the passenger is already in the reservation
    IF EXISTS (
        SELECT 1 
        FROM PassengerList 
        WHERE ReservationNr = reservation_nr 
        AND PassengerID = passenger_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Passenger already exists in this reservation.';
    END IF;

    INSERT INTO PassengerList(PassengerID, ReservationNr)
    VALUE (passenger_id, reservation_nr);

    -- UPDATE Reservation 
    -- SET SeatReserved = SeatReserved + 1
    -- WHERE ReservationNr = reservation_nr;
END
//

CREATE PROCEDURE addContact(
    IN reservation_nr INT, 
    IN passport_number INT, 
    IN email VARCHAR(30), 
    IN phone BIGINT
)
BEGIN 

    DECLARE passenger_id INT;
    DECLARE reservation_exists INT DEFAULT 0; 

     -- Check if reservation exists
    SELECT COUNT(*) INTO reservation_exists
    FROM Reservation
    WHERE ReservationNr = reservation_nr;

    IF reservation_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The given reservation number does not exist.';
    END IF;

    SELECT PassengerID INTO passenger_id
    FROM Passenger 
    WHERE PassportNr = passport_number
    LIMIT 1; 

    IF NOT EXISTS (
        SELECT 1 
        FROM PassengerList 
        WHERE ReservationNr = reservation_nr 
        AND PassengerID = passenger_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The person is not a passenger of the reservation';
    ELSE
        -- Insert contact info
        INSERT INTO ContactInfo(PhoneNumber, EmailAddress, PassengerID)
        VALUES (phone, email, passenger_id);

        -- Update reservation with contact info
        UPDATE Reservation
        SET ContactInfoID = LAST_INSERT_ID()
        WHERE ReservationNr = reservation_nr;

    END IF;
END; 
// 

CREATE PROCEDURE deleteReservation(IN reservation_nr INT)
BEGIN
    DECLARE reservation_exists INT DEFAULT 0;

    -- Check if reservation exists
    SELECT COUNT(*) INTO reservation_exists
    FROM Reservation
    WHERE ReservationNr = reservation_nr;

    IF reservation_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The given reservation number does not exist.';
    END IF;



    DELETE FROM PassengerList
    WHERE ReservationNr = reservation_nr;

    DELETE FROM Reservation
    WHERE ReservationNr = reservation_nr;
END
//

CREATE PROCEDURE addPayment(
    IN reservation_nr INT, 
    IN cardholder_name VARCHAR(30),
    IN credit_card_number BIGINT
)

BEGIN 
    DECLARE flight_number INT;
    DECLARE available_seats INT;
    DECLARE total_seats_confirmed INT;
    DECLARE seats_reserved INT;
    DECLARE contact_info_id INT;
    DECLARE reservation_exists INT DEFAULT 0;

    START TRANSACTION;

    -- Check if reservation exists
    SELECT COUNT(*) INTO reservation_exists
    FROM Reservation
    WHERE ReservationNr = reservation_nr;

    IF reservation_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The given reservation number does not exist.';
    END IF;


    SELECT ContactInfoID,FlightNr
    INTO contact_info_id,flight_number
    FROM Reservation 
    WHERE ReservationNr = reservation_nr
    FOR UPDATE;

    IF flight_number IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No contact information found for this reservation.';
    END IF;

    -- Get seats reserved from passenger list where the reservation number matches
    SELECT COUNT(*) INTO seats_reserved
    FROM PassengerList
    WHERE ReservationNr = reservation_nr;
    
    -- Get total seats confirmed from flight where the flight number matches
    SELECT SeatConfirmed INTO total_seats_confirmed
    FROM Flight
    WHERE FlightNumber = flight_number
    LIMIT 1
    FOR UPDATE;

    IF contact_info_id IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No contact information found for this reservation.';
        
    ELSEIF (seats_reserved + total_seats_confirmed) > 40 THEN
        call deleteReservation(reservation_nr);
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough available seats on this flight.';
        
    END IF;

    -- Insert payment information
    INSERT INTO Payment(CreditCardHolder, CreditCardNumber, Price)
    VALUES (cardholder_name, credit_card_number, calculateFullPrice(flight_number));

    -- Create booking
    INSERT INTO Booking(ReservationNr, SeatReserved, PaymentNr)
    VALUES (reservation_nr, seats_reserved, LAST_INSERT_ID());

    -- Update flight with confirmed seats
    UPDATE Flight 
    SET SeatConfirmed = SeatConfirmed + seats_reserved
    WHERE FlightNumber = flight_number;

    COMMIT;
END
// 

DELIMITER ; 
