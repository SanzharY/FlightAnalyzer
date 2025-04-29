import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

file_path = r"C:\Users\ekpin\Downloads\Analyst_test\analyst_test\transactions.csv"
df = pd.read_csv(file_path, sep=';')
df['DepartureFlightTime'] = pd.to_datetime(df['DepartureFlightTime'], errors='coerce')
df = df.dropna(subset=['DepartureAirportCode', 'ArrivalAirportCode', 'DepartureFlightTime'])
df['Route'] = df['DepartureAirportCode'] + '-' + df['ArrivalAirportCode']
top_5_routes = df['Route'].value_counts().nlargest(5).index.tolist()
df_top = df[df['Route'].isin(top_5_routes)].copy()

def get_season(month):
    if month in [12, 1, 2]:
        return 'Winter'
    elif month in [3, 4, 5]:
        return 'Spring'
    elif month in [6, 7, 8]:
        return 'Summer'
    else:
        return 'Autumn'

df_top['Season'] = df_top['DepartureFlightTime'].dt.month.apply(get_season)
season_counts = df_top.groupby(['Route', 'Season']).size().reset_index(name='NumFlights')

plt.figure(figsize=(12, 6))
sns.barplot(data=season_counts, x='Season', y='NumFlights', hue='Route')
plt.title("Зависимость TOP-5 направлений от сезона")
plt.xlabel("Сезон")
plt.ylabel("Количество рейсов")
plt.tight_layout()
plt.show()