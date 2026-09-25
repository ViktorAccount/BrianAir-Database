
DROP TABLE IF EXISTS Ticket;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS PassengerList;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS ContactInfo;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS WeeklySchedule;
DROP TABLE IF EXISTS Route;
DROP TABLE IF EXISTS Airport;
DROP TABLE IF EXISTS ProfitFactor;
DROP TABLE IF EXISTS WeekdayFactor;

CREATE TABLE Airport(
    AirportCode VARCHAR(3),
    Name VARCHAR(30),
    Country VARCHAR(30),
     
    PRIMARY KEY (AirportCode)
); 

CREATE TABLE ProfitFactor (
    Year INT,
    ProfitFactor DOUBLE,

    PRIMARY KEY(Year)
);

CREATE TABLE Route (
    RouteID INT AUTO_INCREMENT,
    Price DOUBLE,
    StartAirportID VARCHAR(3),
    EndAirportID VARCHAR(3),
    Year INT,

    PRIMARY KEY (RouteID),
    FOREIGN KEY (StartAirportID) REFERENCES Airport(AirportCode),
    FOREIGN KEY (EndAirportID) REFERENCES Airport(AirportCode),
    FOREIGN KEY (Year) REFERENCES ProfitFactor(Year),
    UNIQUE (StartAirportID, EndAirportID, Year)
);

CREATE TABLE WeekdayFactor (
    Year INT,
    Weekday VARCHAR(10),
    WeekdayFactor DOUBLE,

    PRIMARY KEY(Year, Weekday)
);

CREATE TABLE WeeklySchedule(
    ScheduleID INT AUTO_INCREMENT, 
    Year INT,
    DayOfTheWeek VARCHAR(10),
    TimeOfDepature TIME, 
    RouteID INT, 

    PRIMARY KEY(ScheduleID), 
    FOREIGN KEY(RouteID) REFERENCES Route(RouteID),
    FOREIGN KEY(Year) REFERENCES WeekdayFactor(Year),
    UNIQUE(Year, DayOfTheWeek, TimeOfDepature)
);


CREATE TABLE Flight(
    FlightNumber INT AUTO_INCREMENT, 
    WeekNr INT, 
    WeeklyScheduleID INT,
    SeatConfirmed INT, 

    PRIMARY KEY(FlightNumber),
    FOREIGN KEY(WeeklyScheduleID) REFERENCES WeeklySchedule(ScheduleID)
);

CREATE TABLE Passenger( 
    PassengerID INT AUTO_INCREMENT,
    PassportNr INT, 
    Name VARCHAR(30),
    

    PRIMARY KEY(PassengerID),
    UNIQUE(PassportNr)
);

CREATE TABLE ContactInfo(
    ContactInfoID INT AUTO_INCREMENT,
    PhoneNumber BIGINT,
    EmailAddress VARCHAR(30),
    PassengerID INT,

    PRIMARY KEY(ContactInfoID),
    FOREIGN KEY(PassengerID) REFERENCES Passenger(PassengerID)
);

CREATE TABLE Reservation( 
    ReservationNr INT AUTO_INCREMENT, 
    SeatReserved INT,
    FlightNr INT,
    ContactInfoID INT,

    PRIMARY KEY(ReservationNr),
    FOREIGN KEY(FlightNr) REFERENCES Flight(FlightNumber),
    FOREIGN KEY(ContactInfoID) REFERENCES ContactInfo(ContactInfoID)
);

CREATE TABLE PassengerList(
    PassengerID INT,
    ReservationNr INT,

    PRIMARY KEY(PassengerID, ReservationNr),
    FOREIGN KEY(ReservationNr) REFERENCES Reservation(ReservationNr),
    FOREIGN KEY(PassengerID) REFERENCES Passenger(PassengerID)
);

CREATE TABLE Payment(
    PaymentNr INT AUTO_INCREMENT, 
    CreditCardHolder VARCHAR(30),
    CreditCardNumber BIGINT,
    Price DOUBLE, 

    PRIMARY KEY(PaymentNr)
);

CREATE TABLE Booking(
    ReservationNr INT,
    SeatReserved INT,
    PaymentNr INT,

    PRIMARY KEY(ReservationNr),
    FOREIGN KEY(ReservationNr) REFERENCES Reservation(ReservationNr),
    FOREIGN KEY(PaymentNr) REFERENCES Payment(PaymentNr)
);

CREATE TABLE Ticket (
    TicketNr INT, 
    ReservationNr INT, 
    PassengerID INT,

    PRIMARY KEY(TicketNr),
    FOREIGN KEY(ReservationNr) REFERENCES Reservation(ReservationNr),
    FOREIGN KEY(PassengerID) REFERENCES Passenger(PassengerID)
);