DROP VIEW IF EXISTS allFlights;


CREATE VIEW allFlights AS 
SELECT 
    a1.Name AS departure_city_name,
    a2.Name AS destination_city_name,
    ws.TimeOfDepature AS departure_time,
    ws.DayOfTheWeek AS departure_day,
    f.WeekNr AS departure_week,
    ws.Year AS departure_year,
    (40 - f.SeatConfirmed) AS nr_of_free_seats,
    calculateFullPrice(f.FlightNumber) AS current_price_per_seat
FROM Flight AS f
INNER JOIN WeeklySchedule AS ws ON f.WeeklyScheduleID = ws.ScheduleID
INNER JOIN Route AS r ON ws.RouteID = r.RouteID
INNER JOIN Airport AS a1 ON r.StartAirportID = a1.AirportCode
INNER JOIN Airport AS a2 ON r.EndAirportID = a2.AirportCode;
    