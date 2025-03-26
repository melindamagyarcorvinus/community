print('preprocessing imported')

import wikilib
import sys
import subprocess
import os
import pandas as pd
import subprocess
from pathlib import Path
import re
from sqlalchemy.dialects.mssql import NVARCHAR, DATETIME2
import sqlalchemy.types as sql_types

revisions_file_path = ""
index_file_path = ""
working_folder = ""
cleaned_revisions_file_path = ""
log_file_path = ""
usergroups_file_path = ""
initialized = False

valid_logtypes = [
    'newusers', #
    'create', 
    'delete', 
    'patrol', #
    'move',
    'block',  #
    'renameuser',#   
    'import', 
    'thanks',  #
    'protect',
    'growthexperiments', 
    'rights',  #
    'upload',   #fájlfeltöltésó
    'tag',
    'massmessage', 
    'merge', 
    'contentmodel', 
    'gblblock',
    'managetags', 
    'usermerge',  # simplewiki esetébren üres
    'globalauth', 
    'review' #patrolhoz hasonló 
]

def init(p_revisions_file_path, p_usergroups_file_path, p_log_file_path, working_folder_path):
    global revisions_file_path, cleaned_revisions_file_path, index_file_path, usergroups_file_path, initialized, working_folder, log_file_path
    if not os.path.exists(working_folder_path):
      os.makedirs(working_folder_path)

    revisions_file_path=p_revisions_file_path
    revisions_file_name = os.path.basename(revisions_file_path)    
    index_file_path = os.path.join(working_folder_path, 'index', os.path.splitext(revisions_file_name)[0] + '-index.csv')
    cleaned_revisions_file_path = os.path.join(working_folder_path, os.path.splitext(revisions_file_name)[0] + '-cleaned.xml')
    usergroups_file_path = p_usergroups_file_path
    log_file_path = p_log_file_path
    
    print("EZ az:"+p_log_file_path)
    
    working_folder = working_folder_path
    print(index_file_path)
    initialized = True

def create_or_load_btree_file():
    if not initialized:
        print("call initalize first")
        return
    if not os.path.exists(index_file_path):
        python_exe = sys.executable
        script_path = "indexcreation_multitask_runwithpython1.py"
        revisions_path = revisions_file_path.replace('\\', '/')  # Biztosítjuk a forward slash használatát
        index_path = index_file_path.replace('\\', '/')  # Biztosítjuk a forward slash használatát
        command = f'"{python_exe}" "{script_path}" allpageswithrevisions="{revisions_path}" indexfile="{index_path}"'
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        print("Output:", result.stdout)
        if result.stderr:
            print("Error:", result.stderr)
    else:
        print("Existing index file loaded.")
    return index_file_path
   
def create_or_load_cleaned_revisions_file():
  if not os.path.exists(cleaned_revisions_file_path):
    print("Start creating cleaned file")
    in_text_element = False
    with open(revisions_file_path, 'r', encoding='utf-8') as infile, \
         open(cleaned_revisions_file_path, 'w', encoding='utf-8') as outfile:
        
        for line in infile:
            if '<text' in line:
                end_of_open_tag = line.find('>') + 1
                closing_tag_pos = line.find('</text>')
                self_closing_tag_pos = line.find('/>')

                if closing_tag_pos != -1:
                    # Nyitó és záró tag ugyanabban a sorban van
                    outfile.write(line[:closing_tag_pos + len('</text>')] + '\n')
                elif self_closing_tag_pos != -1:
                    # Önzáró tag
                    outfile.write(line[:self_closing_tag_pos + len('/>')] + '\n')
                    in_text_element = False
                else:
                    # Nyitó tag utáni rész helyett azonnal a záró taget írjuk ki
                    outfile.write(line[:end_of_open_tag] + '</text>\n')
                    in_text_element = True

            elif '</text>' in line and in_text_element:
                in_text_element = False
                continue

            elif not in_text_element:
                  outfile.write(line)  # Ha nem vagyunk a <text> elemen belül, másoljuk a sort
  else:
        print("Existing cleaned file loaded.")
  return revisions_file_path  


def getpages(usecache=True):
    if usecache and os.path.exists(_getpagesfilepath()) and os.path.exists(_getdiscardedpagesfilepath()):
        print('existsing files loaded'+_getpagesfilepath())
        return pd.read_feather(_getpagesfilepath()), pd.read_feather(_getdiscardedpagesfilepath())
    columns = ['title', 'ns', 'id']
    pages = []
    discarded_pages = []  # Lista az eldobott oldalak címének és névterének tárolására
    

    
    # Átmeneti változók a page elemek tárolásához
    current_page = {}
    has_redirect = False
    page_count = 0
    
   
    with open(cleaned_revisions_file_path, 'r', encoding='utf-8') as file:
        while True:
            line = file.readline()
            if not line:  # Ha elérjük a fájl végét
                break
            if '<page>' in line:
                page_count += 1
                current_page = {}
                has_redirect = False
                redirect_title = None
            elif '</page>' in line:
                if not has_redirect and '/' not in current_page.get('title', '') and all(key in current_page for key in ['title', 'ns', 'id']):
                    pages.append(current_page)
                else: #if '/' in current_page.get('title', ''):
                    discarded_pages.append({'title': current_page['title'], 'ns': current_page['ns'], 'id': current_page['id'], 'redirecttitle':redirect_title})
            elif '<redirect' in line:
                has_redirect = True
                redirect_title = re.search(r'(?<=title=")[^"]*', line)[0]
            elif '<title>' in line:
                current_page['title'] = line.split('>')[1].split('<')[0]
            elif '<ns>' in line:
                current_page['ns'] = line.split('>')[1].split('<')[0]
            elif '<id>' in line:
                if 'id' not in current_page:
                    current_page['id'] = line.split('>')[1].split('<')[0]
            if '<page>' in line:
                if page_count % 10000 == 0:
                    print(f"Current number of <page> elements processed: {page_count}")
    
    # # Konvertáljuk a gyűjtött adatokat DataFrame-be
    pages_df = pd.DataFrame(pages, columns=columns)    
    discarded_pages_df = pd.DataFrame(discarded_pages, columns=['id', 'title', 'ns', 'redirecttitle'])
    
    pages_df.rename(columns={'id': 'page_id', 'ns':'namespace_id'}, inplace=True)
    discarded_pages_df.rename(columns={'id': 'page_id', 'ns':'namespace_id'}, inplace=True)
    
    pages_df['page_id'] = pages_df['page_id'].astype('Int64')
    discarded_pages_df.rename(columns={'id': 'page_id'}, inplace=True)
    
    pages_df['namespace_id'] = pages_df['namespace_id'].astype('Int64')
    discarded_pages_df['namespace_id'] = discarded_pages_df['namespace_id'].astype('Int64')
    
    pages_df.to_feather(_getpagesfilepath())
    discarded_pages_df.to_feather(_getdiscardedpagesfilepath())
    
    return pages_df, discarded_pages_df

def getrevisions(pages_df, usecache=True, keepbot = False):
    if usecache and os.path.exists(_getrevisionsfilepath()):
        revisions_df = pd.read_feather(_getrevisionsfilepath())
        revisions_df = revisions_df[revisions_df['page_id'].astype(int).isin(pages_df['page_id'].astype(int))]
        return revisions_df
    print("load from here:"+ _getrevisionsfilepath())

    columns = ['page_id', 'revision_id', 'timestamp', 'username', 'user_id', 'ip', 'comment', 'origin', 'format']
    revisions = []
    current_page_id = None
    current_revision = {}
    with open(cleaned_revisions_file_path, 'r', encoding='utf-8') as file:
        current_revision = {}
        in_contributor = False  # Ezt a változót használjuk a contributor szekció azonosítására
        for line in file:
            if '<page>' in line:
                current_page_id = None
            elif '<id>' in line and current_page_id is None:
                current_page_id = line.split('<id>')[1].split('</id>')[0]
            elif '<revision>' in line:
                current_revision = {'page_id': current_page_id}
            elif '</revision>' in line:
                #if current_revision['page_id'] in valid_page_ids:  # Csak akkor adjuk hozzá, ha a page_id érvényes
                revisions.append(current_revision)
                current_revision = {}
            elif '<contributor>' in line:
                in_contributor = True  # Beállítjuk, hogy a contributor szekcióban vagyunk
            elif '</contributor>' in line:
                in_contributor = False  # Kilépünk a contributor szekcióból
            elif current_revision != {}:
                if '<id>' in line and in_contributor:
                    current_revision['user_id'] = line.split('<id>')[1].split('</id>')[0]
                elif '<id>' in line and not in_contributor:
                    current_revision['revision_id'] = line.split('<id>')[1].split('</id>')[0]
                elif '<timestamp>' in line:
                    current_revision['timestamp'] = line.split('<timestamp>')[1].split('</timestamp>')[0]
                elif '<username>' in line:
                    current_revision['username'] = line.split('<username>')[1].split('</username>')[0]
                elif '<ip>' in line:
                    current_revision['ip'] = line.split('<ip>')[1].split('</ip>')[0]
                elif '<comment>' in line:
                    current_revision['comment'] = line.split('<comment>')[1].split('</comment>')[0]
                elif '<origin>' in line:
                    current_revision['origin'] = line.split('<origin>')[1].split('</origin>')[0]
                elif '<format>' in line:
                    current_revision['format'] = line.split('<format>')[1].split('</format>')[0]
    
    # DataFrame létrehozása és kiíratása
    revisions_df = pd.DataFrame(revisions, columns=columns)
    #minta_df =revisions_df.head(1000)
    revisions_df['timestamp'] = pd.to_datetime(revisions_df['timestamp'])
    revisions_df['page_id'] = revisions_df['page_id'].astype('Int64')
    revisions_df['revision_id'] = revisions_df['revision_id'].astype('Int64')
    revisions_df['user_id'] = revisions_df['user_id'].astype('Int64')
    revisions_df['origin'] = revisions_df['origin'].astype('Int64')
    revisions_df = revisions_df[revisions_df['page_id'].astype(int).isin(pages_df['page_id'].astype(int))]
    
    if usecache:  #EZ A TÖBBIÉL NEM ÍGY VAN
        revisions_df.reset_index().to_feather(_getrevisionsfilepath())
    
    return revisions_df


def getnamespaces():
    revisions_file_path = cleaned_revisions_file_path
    namespace_data = []
    with open(revisions_file_path, 'r', encoding='utf-8') as file:
        inside_namespaces = False
        for line in file:
            line = line.strip()
            if '<namespaces>' in line:
                inside_namespaces = True
                continue
            if '</namespaces>' in line:
                inside_namespaces = False
                break
            if inside_namespaces:
                match = re.search(r'<namespace key="([^"]+)"[^>]*>([^<]+)</namespace>', line)
                if match:
                    key = match.group(1)
                    name = match.group(2)
                    namespace_data.append((key, name))
    namespace_df = pd.DataFrame(namespace_data, columns=['namespace_id', 'namespacename'])
    namespace_df['namespace_id'] = namespace_df['namespace_id'].astype('Int64')
    namespace_df = pd.concat([namespace_df, pd.DataFrame({'namespace_id': [0], 'namespacename': ['Main']})], ignore_index=True)

    return namespace_df

def getusergroupassignments(usecache = True):
    if usecache and os.path.exists(_getusergroupsfilepath()):
        print('User group assignments: read cached data')
        return pd.read_feather(_getusergroupsfilepath())
    insert_line = ''
    with open(usergroups_file_path, 'r', encoding='utf-8') as file:
      for line in file:
        if line.strip().startswith('INSERT INTO `user_groups`'):
            insert_line = line.strip()
            break

    if insert_line:
        values_str = insert_line.split('VALUES ')[1]
        values_str = values_str.strip('();')
        rows = values_str.split('),(')
        data = [tuple(map(lambda x: x.strip("'"), row.split(','))) for row in rows]
        group_df = pd.DataFrame(data, columns=['user', 'group', 'expiry'])
    
    group_df['user'] = group_df['user'].astype('Int64')
    group_df.reset_index().to_feather(_getusergroupsfilepath())
    return group_df


def getusers(revisions_df, group_df, keepanon = False, keepbot = False, usecache=True):
    if revisions_df is None and usecache:
        if os.path.exists(_getusersfilepath()):
            users_df =  pd.read_feather(_getusersfilepath())
            revisions_df = revisions_df[revisions_df['user_id'].isin(users_df['user_id'])]
            return users_df

    elif not revisions_df is None and usecache:
        print("Revisions dataframe is set, cache eliminated")

    users_df = revisions_df[['user_id', 'username', 'ip']].drop_duplicates().reset_index(drop=True)  #aktív szerkesztők
    if keepanon:
      users_df['username'] = users_df['username'].fillna(users_df['ip'])
      users_df['user_id'] = users_df['user_id'].fillna(0)
    else:
        users_df = users_df[users_df['ip'].isna()].drop(columns='ip')

    #prioritási szótár
    priorities = {
    'sysop': 5,
    'bureaucrat': 4,
    'editor': 3,
    'trusted': 2,
    'untrusted': 1,
    'bot':0
    }
    merged_df = users_df.merge(group_df, left_on='user_id', right_on='user', how='left')
    merged_df['group'] = merged_df['group'].fillna('untrusted')
    merged_df['priority'] = merged_df['group'].map(priorities).fillna(0)
    
    highest_priority_group = merged_df.loc[merged_df.groupby('user_id')['priority'].idxmax(), ['user_id', 'group']]
    users_df = users_df.merge(highest_priority_group, on='user_id', how='left').rename(columns={'group': 'highest_group'})
    if not keepbot:
      users_df = users_df[users_df['highest_group'] != 'bot']
    users_df['highest_group'] = users_df['highest_group'].apply(lambda x: x if x in priorities else 'untrusted')
    
    users_df.reset_index().to_feather(_getusersfilepath())
    revisions_df = revisions_df[revisions_df['user_id'].isin(users_df['user_id'])]
    
    return users_df

def getlog(logtype, action = None, usecache = True, max_lines=0):
    if logtype not in valid_logtypes:
        raise ValueError(f"Invalid logtype. Valid logtypes are: {valid_logtypes}")
    
    if usecache and os.path.exists(_getlogfilepath(logtype, action)):
        print('read cached data')
        return pd.read_feather(_getlogfilepath(logtype, action))
    log_df = pd.DataFrame()
    temp_items = []
    batch_size = 10000  #ennyi soronként írjuk ki a sorokat a log_df-be
    with open(log_file_path, 'r', encoding='utf-8') as file:
        current_logitem = {}
        multi_line_tag = None
        multi_line_value = None
        in_siteinfo = True
        in_contributor = False
        for line in file:
            line = line.strip()
            if line == '</siteinfo>':
                in_siteinfo = False
                continue
            if not in_siteinfo:
                if line == '<logitem>':
                    current_logitem = {}
                    in_contributor=False
                elif line == '<contributor>':
                    in_contributor = True
                elif line == '</contributor>':
                    in_contributor = False
                elif line == '</logitem>':
                    if multi_line_tag:  # Ha még van feldolgozatlan több soros érték
                        current_logitem[multi_line_tag] = multi_line_value.strip()
                        multi_line_value = None
                        multi_line_tag = None
                    
                    if current_logitem.get('type') == logtype and (not action or current_logitem.get('action') == action):
                        temp_items.append(current_logitem)    
                    current_logitem = {}
                    if len(temp_items) >= batch_size:
                        log_df = pd.concat([log_df, pd.DataFrame(temp_items)], ignore_index=True)
                        print("Number of rows:", log_df.shape[0])
                        if max_lines!= 0 and log_df.shape[0]>max_lines:
                            break
                        temp_items = []  # Lista ürítése a következő batch-hez
                elif line.startswith('<') and not line.startswith('</') and line.endswith('>') and '</' in line:
                    tag = line.split('>')[0][1:].split(' ')[0]
                    value = line.split('>', 1)[1].rsplit(f'</{tag}>', 1)[0]
                    if in_contributor:
                        tag = 'contributor_'+tag

                    current_logitem[tag] = value
        
                elif line.startswith('<') and not line.startswith('</') and not line.endswith('/>'):
                    multi_line_tag = line.split('>')[0][1:].split(' ')[0]
                    multi_line_value = line.split('>', 1)[1]
        
                elif multi_line_tag:
                    # Ellenőrizzük, hogy a sor tartalmazza-e a záró taget
                    end_tag_index = line.find(f'</{multi_line_tag}>')
                    if end_tag_index != -1:
                        # Csak a záró tag előtti részt adjuk hozzá a multi_line_value-hoz
                        multi_line_value += '\n' + line[:end_tag_index]
                        current_logitem[multi_line_tag] = multi_line_value#.strip() --> itt nem lehet trimmelni, ez épp a többsoros érték sorvége jeleit venné el
                        multi_line_tag = None
                        multi_line_value = None
                    else:
                        # Ha nincs záró tag, folytatjuk a sor hozzáadását
                        multi_line_value += '\n' + line

    
    # Ha maradtak elemek a temp_items-ben, hozzáadjuk azokat is a DataFrame-hez
    if temp_items:
        log_df = pd.concat([log_df, pd.DataFrame(temp_items)], ignore_index=True)

    log_df['timestamp'] = pd.to_datetime(log_df['timestamp'])
    log_df['contributor_id'] = log_df['contributor_id'].astype('Int64')
    log_df.to_feather(_getlogfilepath(logtype))
    return log_df


def _getpagesfilepath():
    global initalized, working_folder
    print("Working folder:" +working_folder)
    if not initialized:
        print("module not initialized")
    else:
        return os.path.join(working_folder, '', Path(revisions_file_path).with_suffix('').stem+"-pages.feather")

def _getdiscardedpagesfilepath():
    global initalized, working_folder
    if not initialized:
        print("module not initialized")
    else:
        return os.path.join(working_folder, '', Path(revisions_file_path).with_suffix('').stem+"-discarded-pages.feather")

def _getrevisionsfilepath():
    global initalized, folder
    if not initialized:
        print("module not initialized")
    else:
        return os.path.join(working_folder, '', Path(revisions_file_path).with_suffix('').stem+"-revisions.feather")

def _getusersfilepath():
    global initalized, folder
    if not initialized:
        print("module not initialized")
    else:
        return os.path.join(working_folder, '', Path(revisions_file_path).with_suffix('').stem+"-users.feather")

def _getusergroupsfilepath():
   global initalized, folder
   if not initialized:
       print("module not initialized")
   else:
       return os.path.join(working_folder, '', Path(revisions_file_path).with_suffix('').stem+"-usergroups.feather")

def _getlogfilepath(logtype, action=None):
    global initalized, folder
    if action:
        action = "-"+action
    else:
        action=""
    if not initialized:
        print("module not initialized")
    else:
        return os.path.join(working_folder, '', Path(log_file_path).with_suffix('').stem+"-"+logtype+action+"-log.feather")

def _getindexfiles(usecache=True):
    '''
    Egy index állománycsoport áll: 
        - egy főállományból ami megmondja, hogy melyik oldalhoz tartozó byte határok melyik indexállományban vannak.
        - 20 darab indexállományból
    '''
    index_file_path = _getindexfilepath()
    if not usecache or not os.path.exists(index_file_path):
        python_exe = sys.executable
        script_path = os.getcwd()+"\\"+"indexcreation_multitask_runwithpython1.py"
        revisions_path = os.path.join(folder, revfilename)
        index_path = index_file_path.replace('\\', '/')  # Biztosítjuk a forward slash használatát
        command = f'"{python_exe}" "{script_path}" allpageswithrevisions="{revisions_path}" indexfile="{index_path}"'
        print(command)
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        print("Output:", result.stdout)
        print("Error:", result.stderr)
    

def write_df_to_sql(df, table_name, con, **kwargs):
    """
    Általános függvény DataFrame SQL-be írására.
    A string (object) oszlopokhoz automatikusan NVARCHAR-t rendel.
    
    :param df: A pandas DataFrame, amelyet kiírunk SQL-be.
    :param table_name: A cél SQL tábla neve.
    :param con: A SQLAlchemy kapcsolat (engine).
    :param kwargs: A pandas to_sql függvényének extra paraméterei.
    """
    # Automatikusan generált dtype szótár

    # Automatikusan generált dtype szótár
    dtype = {col: NVARCHAR(length=None) for col in df.select_dtypes(include=['object']).columns}
    # Hozzáadás a datetime64 oszlopok számára
    dtype.update({col: DATETIME2() for col in df.select_dtypes(include=['datetime64[ns, UTC]']).columns})

    print(dtype)
    
    # Az átadott paraméterek felülírhatják az automatikusan generált dtype-ot
    kwargs['dtype'] = dtype
    
    # DataFrame írása az adatbázisba
    df.to_sql(table_name, con=con, **kwargs)


