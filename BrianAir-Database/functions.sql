DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP FUNCTION IF EXISTS calculateFullPrice;

DELIMITER //

CREATE FUNCTION calculateFreeSeats(flightnumber INT)
RETURNS INT
NOT DETERMINISTIC
BEGIN 
    DECLARE booked_seats INT; 

    SELECT SeatConfirmed INTO booked_seats 
    FROM Flight 
    WHERE FlightNumber = flightnumber
    LIMIT 1;

    RETURN 40 - booked_seats;
END
//

CREATE FUNCTION calculatePrice(flightnumber_input INT)
RETURNS DOUBLE
NOT DETERMINISTIC
BEGIN
    DECLARE booked_seats INT DEFAULT 0;

    SELECT SeatConfirmed INTO booked_seats
    FROM Flight
    WHERE FlightNumber = flightnumber_input
    LIMIT 1;

    IF booked_seats IS NULL THEN
        SET booked_seats = 0;
    END IF;

    RETURN (booked_seats + 1) / 40;
END
//


CREATE FUNCTION calculateFullPrice(flightnumber INT)
RETURNS DOUBLE(10,3)
NOT DETERMINISTIC
BEGIN
    DECLARE route_price DOUBLE;
    DECLARE weekday_factor DOUBLE;
    DECLARE profit_factor DOUBLE;
    DECLARE year_val INT;
    DECLARE weekday_val VARCHAR(10);
    DECLARE route_id INT;
    DECLARE tot_price DOUBLE;

    -- Get the route price, weekday factor, and profit factor
    SELECT r.Price, wf.WeekdayFactor, pf.ProfitFactor
    INTO route_price, weekday_factor, profit_factor
    FROM Flight AS f
    INNER JOIN WeeklySchedule AS ws ON f.WeeklyScheduleID = ws.ScheduleID
    INNER JOIN Route AS r ON ws.RouteID = r.RouteID
    INNER JOIN WeekdayFactor AS wf ON ws.Year = wf.Year AND ws.DayOfTheWeek = wf.Weekday
    INNER JOIN ProfitFactor AS pf ON ws.Year = pf.Year
    WHERE f.FlightNumber = flightnumber;

    -- Get the year and weekday from the flight
    SELECT ws.Year, ws.DayOfTheWeek, r.RouteID
    INTO year_val, weekday_val, route_id
    FROM Flight AS f
    INNER JOIN WeeklySchedule AS ws ON f.WeeklyScheduleID = ws.ScheduleID
    INNER JOIN Route AS r ON ws.RouteID = r.RouteID
    WHERE f.FlightNumber = flightnumber;
    -- Check if the flight number exists



    -- Individual IF checks for each variable with specific error messages
    IF year_val IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Year is NULL';
    END IF;

    IF weekday_val IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Weekday is NULL';
    END IF;

    IF route_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Route ID is NULL';
    END IF;

    IF route_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Route price is NULL';
    END IF;

    IF weekday_factor IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Weekday factor is NULL';
    END IF;

    IF profit_factor IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Profit factor is NULL';
    END IF;

    -- Calculate total price using the other function calculatePrice(flightnumber)
    SET tot_price = route_price * weekday_factor * calculatePrice(flightnumber) * profit_factor;

    RETURN tot_price;
END
//

DELIMITER ;
