# -*- coding: utf-8 -*-
"""
Created on Sat Feb 22 14:53:34 2025

@author: magyarm
Vizualizációk az esettanulmányhoz
"""
#%% vonaldiagram az új tartalmi oldalakról
import pandas as pd
import matplotlib.pyplot as plt

data = pd.read_csv('C:/Work/Communities/Results/new_pages_daily.csv', delimiter=';')
data = data[data['type'] == 'content']
data['date'] = pd.to_datetime(data['date'])
data['year'] = data['date'].dt.to_period('M')
monthly_sum = data.groupby('year')['darab'].sum()


plt.figure(figsize=(10, 5))
plt.plot(monthly_sum.index.to_timestamp(), monthly_sum, linestyle='-')
plt.title('Új tartalmi oldalak havonta')
plt.xlabel('Dátum')
plt.ylabel('Darab')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

#%% Vonaldiagram a különféle tartalmi oldalakról
'''
select cast(created as date) date, type, count(*) darab from #firstedits 
group by cast(created as date), type
'''

import pandas as pd
import matplotlib.pyplot as plt

data = pd.read_csv('C:/Work/Communities/Results/new_pages_daily.csv', delimiter=';')
data = data[data['type'] != 'technical']
data['date'] = pd.to_datetime(data['date'])

#Az utolsó teljes évre limitálás
data = data[data['date'] < '2024-01-01']

# Csoportosítás havonta
monthly_data = data.groupby([data['date'].dt.to_period('M'), 'type'])['darab'].sum().unstack()

# Magyar nyelvű cimkék fordítása
type_mapping = {'community': 'közösség', 'user': 'felhasználó', 'content': 'tartalom'}

plt.figure(figsize=(10, 5))
for column in monthly_data.columns:
    plt.plot(monthly_data.index.to_timestamp(), monthly_data[column], label=type_mapping.get(column, column), linestyle='-')

plt.title('Új oldalak kontextustípus szerint')
plt.xlabel('Dátum')
plt.ylabel('Darab')
plt.legend(title='Típus')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

#%% Standardizálás
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler

data = pd.read_csv('C:/Work/Communities/Results/new_pages_daily.csv', delimiter=';')
data = data[data['type'] != 'technical']
data['date'] = pd.to_datetime(data['date'])

monthly_data = data.groupby([data['date'].dt.to_period('M'), 'type'])['darab'].sum().unstack()


scaler = StandardScaler()
standardized_data = monthly_data.copy()
for column in monthly_data.columns:
    standardized_data[column] = scaler.fit_transform(monthly_data[column].values.reshape(-1, 1)).flatten()


type_mapping = {'community': 'közösség', 'user': 'felhasználó', 'content': 'tartalom'}

plt.figure(figsize=(10, 5))
for column in standardized_data.columns:
    plt.plot(standardized_data.index.to_timestamp(), standardized_data[column], label=type_mapping.get(column, column), linestyle='-')

plt.title('Standardizált új oldalak kontextustípus szerint')
plt.xlabel('Dátum')
plt.ylabel('Standardizált darab')
plt.legend(title='Típus')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

#%% Szerkesztések kontextusonként összegezve
'''
select cast(created as date) date, type, count(*) darab from #firstedits 
group by cast(created as date), type
'''
import pandas as pd
import matplotlib.pyplot as plt

# Load the CSV data into a DataFrame
data = pd.read_csv('C:/Work/Communities/Results/edits_daily.csv', delimiter=';')
data = data[data['type'] != 'technical']

data['date'] = pd.to_datetime(data['date'])

data = data[data['date'] < '2024-01-01']
monthly_data = data.groupby([data['date'].dt.to_period('M'), 'type'])['darab'].sum().unstack()
type_mapping = {'community': 'közösség', 'user': 'felhasználó', 'content': 'tartalom'}

plt.figure(figsize=(10, 5))
for column in monthly_data.columns:
    plt.plot(monthly_data.index.to_timestamp(), monthly_data[column], label=type_mapping.get(column, column), linestyle='-')

plt.title('Szerkesztések kontextustípus szerint')
plt.xlabel('Dátum')
plt.ylabel('Darab')
plt.legend(title='Típus')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
#%% Felhasználóközi kapcsolatok
import pandas as pd
import matplotlib.pyplot as plt

# Adatok betöltése
data = pd.read_csv('C:/Work/Communities/Results/connectionsperday_all_time_with_owner_same_day.csv', delimiter=';')
data['interpersonal'] = (data['owner'] == data['user1']) | (data['owner'] == data['user2'])

data['date'] = pd.to_datetime(data['date'])
data = data[data['type'] != 'technical']
data = data[data['type'] != 'thanks']
data['user_min'] = data[['user1', 'user2']].min(axis=1)
data['user_max'] = data[['user1', 'user2']].max(axis=1)
data = data.groupby(['user_min', 'user_max', 'type'])['date'].min().reset_index()
data['month'] = data['date'].dt.to_period('M')

# Az első előfordulások havi szintű aggregálása
monthly_new_connections = data.groupby(['month', 'type']).size().unstack(fill_value=0)
data.groupby(['type']).size()

# Korlátozás a 2024 január 1-je előtti adatokra
monthly_new_connections = monthly_new_connections[monthly_new_connections.index < '2024-01']

# Típusok magyarítása
type_mapping = {'interpersonal': 'személyközi', 'discussion': 'viták', 'coediting': 'közös szerkesztés'}

# Vizualizáció készítése
plt.figure(figsize=(10, 5))  
for connection_type in monthly_new_connections.columns:
    plt.plot(monthly_new_connections.index.to_timestamp(), monthly_new_connections[connection_type], label=type_mapping.get(connection_type, connection_type))

plt.title('Új kapcsolatok száma kapcsolattípusonként')
plt.xlabel('Dátum')
plt.ylabel('Új kapcsolatok száma')
plt.legend(title='Kapcsolattípus')
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

#%% típusonkénti új lapok
import pandas as pd
import matplotlib.pyplot as plt

data = pd.read_csv('C:/Work/Communities/Results/new_pages_daily.csv', delimiter=';')
data['date'] = pd.to_datetime(data['date'])
data = data[data['type'] != 'technical']
data.head()

data = data[data['type'] != 'technical']
data['date'] = pd.to_datetime(data['date'])

pertype_data = data.groupby([data['type']])['darab'].sum()
#%% típusonként új szerkesztések
import pandas as pd
import matplotlib.pyplot as plt
# Adatok betöltése
data = pd.read_csv('C:/Work/Communities/Results/edits_daily.csv', delimiter=';')
data['date'] = pd.to_datetime(data['date'])
data = data[data['type'] != 'technical']
data.head()

data = data[data['type'] != 'technical']
data['date'] = pd.to_datetime(data['date'])

pertype_data = data.groupby([data['type']])['darab'].sum()
#%% Long tail plotok
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# CSV fájl beolvasása
data = pd.read_csv('C:/Work/Communities/Results/edits_by_users_and_type.csv', sep=';')

# A különböző típusok feldolgozása
types = ['content', 'community', 'user']
colors = {'content': 'orange', 'community': 'blue', 'user': 'green'}  # Színek hozzárendelése
type_mapping = {'community': 'Közösség', 'user': 'Felhasználó', 'content': 'Tartalom'}  # Magyar fordítások

fig, axes = plt.subplots(1, 3, figsize=(10, 5), sharey=True)  # Három subplot egy sorban, azonos y-tengellyel, méret módosítása

for i, type_name in enumerate(types):
    # Adatok szűrése az aktuális típus szerint
    type_data = data[data['type'] == type_name]

    # Felhasználók szerkesztéseinek összesítése
    user_contributions = type_data.groupby('userid')['count'].sum().sort_values()

    # Kumulatív százalék kiszámítása
    cumulative_percent = user_contributions.cumsum() / user_contributions.sum()

    # Kumulatív százalék ábrázolása
    ax = axes[i]
    ax.plot(cumulative_percent.values, marker='o', linestyle='-', color=colors[type_name])
    ax.set_title(type_mapping[type_name])  # Az aktuális típus neve magyarul az alcímben
    ax.grid(True)

    # Tengelyfeliratok formázása
    ax.xaxis.set_major_locator(ticker.MaxNLocator(5))  # Legfeljebb 5 fő tick az x-tengelyen

# Közös x-tengely felirat hozzáadása a teljes sorhoz
fig.text(0.5, -0.04, 'Felhasználók közreműködések száma alapján rendezve', ha='center')
fig.suptitle('Közreműködések kumulatív százalékos eloszlása kontextustípusok szerint')

# Az ábrák megjelenítése
plt.tight_layout(rect=[0, 0, 1, 0.95])  # A főcím miatt állítsuk be a layoutot
plt.show()

#%% Fokszám boxplotok előkészítése

import pandas as pd
import networkx as nx
import matplotlib.pyplot as plt

# Adatok betöltése
data = pd.read_csv('C:/Work/Communities/Results/connectionsperday_all_time_with_owner_same_day.csv', delimiter=';')

# Dátum oszlop konvertálása
data['date'] = pd.to_datetime(data['date'])

# Hálózatok létrehozása típusonként
networks = {t: nx.Graph() for t in data['type'].unique()}

# Kapcsolatok hozzáadása a megfelelő hálózathoz, figyelembe véve a már létező kapcsolatokat
for index, row in data.iterrows():
    network = networks[row['type']]
    if not network.has_edge(row['user1'], row['user2']):
        network.add_edge(row['user1'], row['user2'])

# Összegyűjtjük a fokszámokat minden típusra és minden user-re
degrees = {t: pd.Series(dict(nx.degree(net))) for t, net in networks.items()}

# DataFrame létrehozása a fokszámokból
degree_df = pd.DataFrame(degrees).fillna(0).astype(int).reset_index()
degree_df.columns = ['userid'] + [f'degree_{t}' for t in degree_df.columns[1:]]

# Új oszlop hozzáadása, ami True értéket kap, ha minden fokszám 0 (az első oszlopot, a 'userid'-t kihagyva)
degree_df['all_zero'] = (degree_df.iloc[:, 1:] == 0).all(axis=1)




#%% Fokszám boxplotok vizualizáció

# Szűrés azokra a felhasználókra, akiknek bármelyik típus szerinti fokszáma legalább 5
filtered_df = degree_df[degree_df.iloc[:, 1:].max(axis=1) >= 500]

# A DataFrame átalakítása hosszú formátumra
melted_filtered_df = filtered_df.melt(id_vars='userid', var_name='type', value_name='degree')

# Boxplot készítése az összes típusra
plt.figure(figsize=(12, 8))
plt.boxplot([melted_filtered_df[melted_filtered_df['type'] == column]['degree'].dropna() for column in melted_filtered_df['type'].unique()],
            labels=[column.split('_')[1] for column in melted_filtered_df['type'].unique()])
plt.title('Comparison of Degree Distributions by Type for Active Users')
plt.xlabel('Type')
plt.ylabel('Degree')
plt.grid(True)
plt.show()
#%% Venn diagram
#pip install matplotlib_venn
import pandas as pd
from matplotlib_venn import venn3
import matplotlib.pyplot as plt

# CSV fájl beolvasása
data = pd.read_csv('C:/Work/Communities/Results/edits_by_users_and_type.csv', sep=';')
# Különítsük el a userid-ket a különböző típusok szerint
content_users = set(data[data['type'] == 'content']['userid'])
community_users = set(data[data['type'] == 'community']['userid'])
user_users = set(data[data['type'] == 'user']['userid'])

# Venn-diagram készítése
plt.figure(figsize=(10, 5))  # Átméretezés az egyezőség érdekében
venn3([content_users, community_users, user_users], ('Tartalom', 'Közösség', 'Felhasználó'), 
      set_colors=('orange', 'blue', 'green'))  # Színek és feliratok magyarítása
plt.title('Felhasználói metszetek a kontextustípusok szerint')

plt.show()

# Felhasználói halmazok létrehozása minden egyes kontextustípus szerint
content_users = set(data[data['type'] == 'content']['userid'])
community_users = set(data[data['type'] == 'community']['userid'])
user_users = set(data[data['type'] == 'user']['userid'])

# Azonosítjuk azokat a felhasználókat, akik mindhárom kontextustípusban részt vettek
triple_intersect_users = content_users & community_users & user_users

# Kiszámítjuk az összes szerkesztésüket
total_edits = data[data['userid'].isin(triple_intersect_users)]['count'].sum()

#%% Kalkulációk
import pandas as pd

# CSV fájl beolvasása
data = pd.read_csv('C:/Work/Communities/Results/edits_by_users_and_type.csv', sep=';')

# Adatok szűrése a "content" típusra
content_data = data[data['type'] == 'content']

# Felhasználói halmazok létrehozása minden egyes kontextustípus szerint
content_users = set(data[data['type'] == 'content']['userid'])
community_users = set(data[data['type'] == 'community']['userid'])
user_users = set(data[data['type'] == 'user']['userid'])

# 1. Csak content névtérben szerkesztő felhasználók
only_content_users = content_users - (community_users | user_users)
edits_only_content = content_data[content_data['userid'].isin(only_content_users)]['count'].sum()

# 2. Content és community metszetében lévő felhasználók (de a userrel nincs metszete)
content_community_users = (content_users & community_users) - user_users
edits_content_community = content_data[content_data['userid'].isin(content_community_users)]['count'].sum()

# 3. Content és user metszetében lévő felhasználók (de a communityvel nincs metszete)
content_user_users = (content_users & user_users) - community_users
edits_content_user = content_data[content_data['userid'].isin(content_user_users)]['count'].sum()

# 4. Content, user és community metszetében elhelyezkedő felhasználók
triple_intersect_users = content_users & community_users & user_users
edits_triple_intersect = content_data[content_data['userid'].isin(triple_intersect_users)]['count'].sum()

# Összes szerkesztés a "content" típus alatt
total_edits_content = content_data['count'].sum()

# Eredmények kiírása
print(f"Összes szerkesztés a 'content' típus alatt: {total_edits_content}")
print(f"Szerkesztések száma csak a 'content' névtérben szerkesztőktől: {edits_only_content}")
print(f"Szerkesztések száma a 'content' és 'community' metszetében, kizárva a 'user'-t: {edits_content_community}")
print(f"Szerkesztések száma a 'content' és 'user' metszetében, kizárva a 'community'-t: {edits_content_user}")
print(f"Szerkesztések száma a 'content', 'community' és 'user' metszetében: {edits_triple_intersect}")


