
CREATE TABLE employees (
    EmployeeNumber INTEGER PRIMARY KEY,
    UUID UUID,
    DepartmentName TEXT,
    BirthDate DATE,
    JoinDate DATE
);


CREATE TABLE departments (
    DepartmentID INTEGER PRIMARY KEY,
    DepartmentName TEXT
);


CREATE TABLE beneficiaries (
    BeneficiaryID INTEGER PRIMARY KEY,
    EmployeeNumber INTEGER REFERENCES employees(EmployeeNumber),
    Gender INTEGER,
    DateOfBirth DATE,
    Type INTEGER, -- 1=Spouse, 2=Child, 3=Parent и т.д.
    IsActive BOOLEAN
);


CREATE TABLE transactions_emp (
    EmployeeNumber INTEGER,
    UUID UUID,
    DepartureAirport TEXT,
    ArrivalAirport TEXT,
    DepartureTime TIMESTAMP,
    ReturnTime TIMESTAMP,
    Status INTEGER,
    BookingTime TIMESTAMP
);


CREATE TABLE transactions_ben (
    BeneficiaryID INTEGER,
    UUID UUID,
    DepartureAirport TEXT,
    ArrivalAirport TEXT,
    DepartureTime TIMESTAMP,
    ReturnTime TIMESTAMP,
    Status INTEGER,
    BookingTime TIMESTAMP
);


CREATE TABLE flighttime (
    DepartureStationCode TEXT,
    ArrivalStationCode TEXT,
    FlightTime NUMERIC
);


CREATE TABLE flights (
    TravelerID INTEGER,
    EmployeeNumber INTEGER,
    FlightTime TIMESTAMP,
    ReturnFlightTime TIMESTAMP,
    DepartureAirportCode TEXT,
    ArrivalAirportCode TEXT,
    RecordLocator TEXT,
    AirlineID INTEGER,
    Status INTEGER
);
