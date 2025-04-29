
-- 1: Самый популярные направления для семейного отдыха (бенефициары (Child, Spouse) + сотрудник);

WITH family_members AS (
    SELECT EmployeeNumber FROM beneficiaries WHERE Type IN (1, 2)
    UNION
    SELECT DISTINCT EmployeeNumber FROM flights
),
family_flights AS (
    SELECT 
        f.DepartureAirportCode || '-' || f.ArrivalAirportCode AS Route
    FROM flights f
    WHERE f.Status = 1
      AND f.EmployeeNumber IN (SELECT EmployeeNumber FROM family_members)
),
ranked_routes AS (
    SELECT Route, COUNT(*) AS FlightCount
    FROM family_flights
    GROUP BY Route
)
SELECT * 
FROM ranked_routes
ORDER BY FlightCount DESC
LIMIT 10;


-- 2: Получить информацию по расстоянию между городами;

SELECT
  DepartureStationCode || '-' || ArrivalStationCode AS Route,
  FlightTime,
  FlightTime * 800 AS EstimatedDistanceKM
FROM flighttime;

-- 3: Вывести статистику по общему преодоленному расстоянию по каждому сотруднику и его бенефициару;

WITH mapped_flights AS (
  SELECT
    COALESCE(b.EmployeeNumber, f.EmployeeNumber) AS OwnerEmployeeNumber,
    ft.FlightTime * 800 AS DistanceKM
  FROM flights f
  LEFT JOIN beneficiaries b ON f.TravelerID = b.BeneficiaryID
  JOIN flighttime ft
    ON f.DepartureAirportCode = ft.DepartureStationCode
   AND f.ArrivalAirportCode = ft.ArrivalStationCode
  WHERE f.Status = 1
)
SELECT
  OwnerEmployeeNumber AS EmployeeNumber,
  SUM(DistanceKM) AS TotalDistanceKM
FROM mapped_flights
GROUP BY OwnerEmployeeNumber;

-- 4:Вывести тренды, лучшего времени бронирования по каждому направлению основываясь на времени бронирования (чем больше бронирований, тем меньше вероятность купить билет);

SELECT * FROM (
  SELECT
    DepartureAirport,
    ArrivalAirport,
    DepartureAirport || '-' || ArrivalAirport AS Route,
    DATE_TRUNC('week', BookingTime) AS BookingWeek,
    COUNT(*) AS NumBookings,
    RANK() OVER (PARTITION BY DepartureAirport, ArrivalAirport ORDER BY COUNT(*) ASC) AS rnk
  FROM transactions_emp
  GROUP BY DepartureAirport, ArrivalAirport, DATE_TRUNC('week', BookingTime)
) ranked
WHERE rnk = 1;
-- 5:Вывести статистику по общему времени, проведенному в полете по каждому пассажиру;

SELECT
  COALESCE(b.EmployeeNumber, f.EmployeeNumber) AS Passenger,
  SUM(ft.FlightTime) AS TotalFlightTimeHours
FROM flights f
LEFT JOIN beneficiaries b ON f.TravelerID = b.BeneficiaryID
JOIN flighttime ft ON f.DepartureAirportCode = ft.DepartureStationCode
                   AND f.ArrivalAirportCode = ft.ArrivalStationCode
WHERE f.Status = 1
GROUP BY Passenger;
-- 6:Самые часто летающие сотрудники в каждом департаменте;
WITH FlightCounts AS (
  SELECT EmployeeNumber, COUNT(*) AS NumFlights
  FROM flights
  WHERE Status = 1
  GROUP BY EmployeeNumber
),
EmpDept AS (
  SELECT EmployeeNumber, DepartmentName FROM employees
),
Ranked AS (
  SELECT ed.DepartmentName, fc.EmployeeNumber, fc.NumFlights,
         RANK() OVER (PARTITION BY ed.DepartmentName ORDER BY fc.NumFlights DESC) AS rnk
  FROM FlightCounts fc
  JOIN EmpDept ed ON fc.EmployeeNumber = ed.EmployeeNumber
)
SELECT * FROM Ranked WHERE rnk = 1;

-- 7:Диаграмма зависимости возраста пассажира от количества перелетов
WITH all_passengers AS (
  SELECT EmployeeNumber AS ID, BirthDate AS DateOfBirth FROM employees
  UNION ALL
  SELECT BeneficiaryID AS ID, DateOfBirth FROM beneficiaries
),
flights_with_age AS (
  SELECT
    ap.ID,
    DATE_PART('year', AGE(ap.DateOfBirth)) AS Age
  FROM all_passengers ap
  JOIN flights f ON f.TravelerID = ap.ID
  WHERE f.Status = 1
)
SELECT Age, COUNT(*) AS NumFlights
FROM flights_with_age
GROUP BY Age
ORDER BY Age;

-- 8:Диаграмма зависимости TOP 5 самых популярных направлений от сезона
WITH TopRoutes AS (
  SELECT
    DepartureAirportCode || '-' || ArrivalAirportCode AS Route,
    COUNT(*) AS FlightCount
  FROM flights
  WHERE Status = 1
  GROUP BY Route
  ORDER BY FlightCount DESC
  LIMIT 5
),
Seasonal AS (
  SELECT
    DepartureAirportCode || '-' || ArrivalAirportCode AS Route,
    EXTRACT(MONTH FROM flight_time) AS Month
  FROM flights
  WHERE Status = 1
)
SELECT
  CASE
    WHEN Month IN (3, 4, 5) THEN 'Spring'
    WHEN Month IN (6, 7, 8) THEN 'Summer'
    WHEN Month IN (9, 10, 11) THEN 'Autumn'
    ELSE 'Winter'
  END AS Season,
  s.Route,
  COUNT(*) AS Flights
FROM Seasonal s
JOIN TopRoutes t ON s.Route = t.Route
GROUP BY Season, s.Route
ORDER BY s.Route, Season;

-- 9:Самые популярные и непопулярные направления обоих АК
WITH RouteCounts AS (
  SELECT AirlineID, DepartureAirportCode || '-' || ArrivalAirportCode AS Route, COUNT(*) AS FlightCount
  FROM flights
  WHERE Status = 1
  GROUP BY AirlineID, Route
),
Ranked AS (
  SELECT *,
         RANK() OVER (PARTITION BY AirlineID ORDER BY FlightCount DESC) AS MostPopular,
         RANK() OVER (PARTITION BY AirlineID ORDER BY FlightCount ASC) AS LeastPopular
  FROM RouteCounts
)
SELECT *
FROM Ranked
WHERE MostPopular = 1 OR LeastPopular = 1;

-- 10:  Сезонность международных рейсов
SELECT
  EXTRACT(MONTH FROM flight_time) AS Month,
  COUNT(*) AS NumInternationalFlights
FROM flights
WHERE ArrivalAirportCode NOT IN ('ALA', 'TSE', 'CIT', 'GUW', 'UKK', 'SCO', 'PPK', 'KSN', 'DMB')
GROUP BY Month
ORDER BY Month;

-- 10:Количество рейсов по дням недели
SELECT
  EXTRACT(DOW FROM flight_time) AS DayOfWeek,
  COUNT(*) AS NumFlights
FROM flights
GROUP BY DayOfWeek
ORDER BY DayOfWeek;
