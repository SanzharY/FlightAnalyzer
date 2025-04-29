import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
from pathlib import Path

employee_file = Path(r"C:\Users\ekpin\Downloads\Analyst_test\analyst_test\employees")
employee_lines = employee_file.read_text(encoding="utf-8").splitlines()
pattern = re.compile(r"(\d+)\s+([A-F0-9-]+)\s+(.*?)\s+([A-Za-z]{3} \d{1,2} \d{4})\s+(\d{1,2} \w{3} \d{4})$")
parsed_employees = []

for line in employee_lines:
    match = pattern.match(line.strip())
    if match:
        emp_number = int(match.group(1))
        uuid = match.group(2)
        department = match.group(3).strip()
        birth_date = pd.to_datetime(match.group(4), errors='coerce')
        join_date = pd.to_datetime(match.group(5), errors='coerce')
        parsed_employees.append((emp_number, uuid, department, birth_date, join_date))

df_employees = pd.DataFrame(parsed_employees, columns=[
    "EmployeeNumber", "UUID", "DepartmentName", "BirthDate", "JoinDate"
])

beneficiaries = pd.read_xml(r"C:\Users\ekpin\Downloads\Analyst_test\analyst_test\beneficiaries.xml")
flights = pd.read_csv(r"C:\Users\ekpin\Downloads\Analyst_test\analyst_test\transactions.csv", sep=';')

df_employees['BirthDate'] = pd.to_datetime(df_employees['BirthDate'], errors='coerce')
beneficiaries['DateOfBirth'] = pd.to_datetime(beneficiaries['DateOfBirth'], errors='coerce')
flights['DepartureFlightTime'] = pd.to_datetime(flights['DepartureFlightTime'], errors='coerce')

passenger_birthdates = pd.concat([
    df_employees[['EmployeeNumber', 'BirthDate']].rename(columns={"EmployeeNumber": "TravelerID"}),
    beneficiaries[['BeneficiaryID', 'DateOfBirth']].rename(columns={"BeneficiaryID": "TravelerID", "DateOfBirth": "BirthDate"})
])

flights_with_age = pd.merge(
    flights[['TravelerID', 'DepartureFlightTime']],
    passenger_birthdates,
    on='TravelerID',
    how='left'
)

flights_with_age['Age'] = flights_with_age.apply(
    lambda row: row['DepartureFlightTime'].year - row['BirthDate'].year
    if pd.notnull(row['BirthDate']) and pd.notnull(row['DepartureFlightTime']) else None,
    axis=1
)

age_distribution = flights_with_age.dropna(subset=['Age'])     .groupby('Age').size().reset_index(name='NumFlights')

plt.figure(figsize=(10, 5))
sns.lineplot(data=age_distribution, x='Age', y='NumFlights', marker='o')
plt.title("Количество перелётов по возрасту пассажиров")
plt.xlabel("Возраст")
plt.ylabel("Количество перелётов")
plt.grid(True)
plt.tight_layout()
plt.show()