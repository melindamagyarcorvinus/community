import os
import pandas as pd
import difflib
import re
import mwparserfromhell
import phpserialize

from datetime import datetime

print('wikilib imported')

class RevisionResult:
    pass

    
def get_revision_map(page_index_mapping_path, index_dir, page_id):
    # 1. Lépés: Betöltjük a page index mapping fájlt
    page_index_df = pd.read_csv(page_index_mapping_path)

    # page_id és revision_id konverzió sztringgé
    page_id = str(page_id)


    # 2. Lépés: Megkeressük, melyik index fájl tartalmazza a megadott page_id-t
    page_files = page_index_df.loc[page_index_df['page_id'].astype(str) == page_id, 'index_files'].values
    if len(page_files) == 0:
        print(f"Page ID {page_id} nem található az indexben.")
        return None

    page_files = page_files[0].split(', ')

    # 3. Lépés: Betöltjük az index fájlt és megkeressük a megfelelő revision_id-t
    revision_index_df = pd.DataFrame()
    for file_name in page_files:
        print(file_name)
        file_path = os.path.join(index_dir, file_name)
        revision_index_df = pd.concat([revision_index_df, pd.read_csv(file_path)], ignore_index=True)
    
    return revision_index_df[revision_index_df['page_id'].astype(str) == page_id]
    

def get_revision_text_idx(original_file_path, revision_id, revision_index_df):
    result = RevisionResult()
    result.id = str(revision_id)
   
    matching_row = revision_index_df[revision_index_df['revision_id'].astype(str) == result.id]
    revision_start_byte = matching_row['revision_start_byte'].values[0]
    revision_end_byte = matching_row['revision_end_byte'].values[0]
    result.parentid=None
    # 4. Lépés: Kinyitjuk az eredeti fájlt és megkeressük a text tartalmat
    with open(original_file_path, 'r', encoding='utf-8') as file:
        file.seek(revision_start_byte)
        result.revision_text = None
        result.parentid = None

        while file.tell() < revision_end_byte:
            line = file.readline()
            if "<parentid>" in line:
                result.parentid =  line.split('>', 1)[1].split('<', 1)[0]
            if "<timestamp>" in line:
                result.timestamp =  datetime.fromisoformat(line.split('>', 1)[1].split('<', 1)[0].rstrip('Z'))

            if '<text' in line:
                result.revision_text = line
                # Ellenőrizzük, hogy a <text> és </text> egy sorban van-e
                if '</text>' not in line and not line.strip().endswith("/>"):
                    while True:
                        next_line = file.readline()
                        result.revision_text += next_line
                        if '</text>' in next_line:
                            break
                result.revision_text = result.revision_text.split('>', 1)[1].rsplit('</text>', 1)[0]
                break

    return result

#A szövegtartalom nélküli fájlok elnevezéséhez
def insert_prefix(file_path, prefix):
    head, tail = os.path.split(file_path)
    return os.path.join(head, prefix+'-' + tail)

#ezen dolgozni kell még, de a szokásos userhozzászólásokkal jól teljesít.
def clean_wikitext(text):
   wikicode = mwparserfromhell.parse(text)
   text = wikicode.strip_code(keep_template_params=['Citation'])
   text = re.sub(r'<includeonly>.*?</includeonly>', '', text, flags=re.DOTALL)
   text = re.sub(r'<noinclude>.*?</noinclude>', '', text, flags=re.DOTALL)
   text = re.sub(r'</?div.*?>', '', text, flags=re.DOTALL)
   text = re.sub(r'</?span.*?>', '', text, flags=re.DOTALL)
   return text.strip()

def clean_wikitext2(text):
    wikicode = mwparserfromhell.parse(text)
    # Létrehozzuk a tisztított szöveg változót
    cleaned_text = ""
    # Végigmegyünk a wikikód összes elemén
    for node in wikicode.nodes:
        if isinstance(node, mwparserfromhell.nodes.heading.Heading):
            # Ha a node egy fejléc, akkor hozzáadjuk a tisztított szöveghez
            cleaned_text += str(node)
        elif isinstance(node, mwparserfromhell.nodes.text.Text):
            # Ha a node szöveg, akkor csak a szöveg részt adjuk hozzá
            cleaned_text += node.value
        # Itt adhatók hozzá további szabályok, ha szükséges

    # Az eredményül kapott szöveget visszaadjuk
    return cleaned_text.strip()

def clean_wikitext3(text):
    # Feltételezzük, hogy ez a függvény meghívása megadja a nyers szövegünket
    raw_text = text

    # Először végezzünk egy általános HTML tisztítást
    cleaned_html_text = re.sub(r'&lt;.*?&gt;', '', raw_text)  # Eltávolít minden HTML-szerű tartalmat

    # Most dolgozzuk fel a wikikódot
    wikicode = mwparserfromhell.parse(cleaned_html_text)
    cleaned_text = ""
    for node in wikicode.nodes:
        if isinstance(node, mwparserfromhell.nodes.heading.Heading):
            cleaned_text += str(node)
        elif isinstance(node, mwparserfromhell.nodes.text.Text):
            cleaned_text += node.value
        elif isinstance(node, mwparserfromhell.nodes.tag.Tag):  # a tagek eltávolítása korábban történik, ha itt még van ilyen, lezáratlan tag okozza
            cleaned_text += str(node.contents)

    # Az eredményül kapott tisztított szöveget itt kezelhetjük, pl. kiírhatjuk vagy visszatérhetünk vele
    return cleaned_text


def clean_wikitext4(text):
    # Feltételezzük, hogy ez a függvény meghívása megadja a nyers szövegünket
    raw_text = text

    # Először végezzünk egy általános HTML tisztítást
    cleaned_html_text = re.sub(r'&lt;.*?&gt;', '', raw_text)  # Eltávolít minden HTML-szerű tartalmat

    return cleaned_html_text


def save_revision_text_by_id(xml_file_path, revision_id, output_file_name):
    correct_page = False
    with open(xml_file_path, 'r', encoding='utf-8') as file:
        for line in file:
            if '<revision>' in line:
                correct_page = False
            if '<id>' in line and revision_id in line:
                correct_page = True
            if correct_page and '<text' in line:
                with open(output_file_name, 'w', encoding='utf-8') as output_file:
                    text_start = line.split('<text')[1].split('>', 1)[1]
                    if '</text>' in text_start:
                        output_file.write(text_start.split('</text>')[0])
                    else:
                        output_file.write(text_start)
                        for line in file:
                            if '</text>' in line:
                                output_file.write(line.split('</text>')[0])
                                break
                            output_file.write(line)
                break
                
#teljes állományból egy oldal kifejtéséhez
def save_page_by_id(xml_file_path, page_id, output_file_name):
    page_start = False
    page_content = []
    within_page_id = False

    with open(xml_file_path, 'r', encoding='utf-8') as file:
        for line in file:
            if '<page>' in line:
                page_content = [line]
                page_start = True
                within_page_id = False
            elif page_start:
                page_content.append(line)
                if '<id>' in line and not within_page_id:
                    within_page_id = True
                    if page_id in line.split('<id>')[1].split('</id>')[0]:
                        correct_page = True
                    else:
                        correct_page = False
                if '</page>' in line:
                    if correct_page:
                        with open(output_file_name, 'w', encoding='utf-8') as output_file:
                            output_file.writelines(page_content)
                        break
                    page_start = False
                    page_content = []


#%% diff függvény
def diff_to_dataframe_with_section(text1, text2):
    d = difflib.Differ()
    diff = list(d.compare(text1.splitlines(), text2.splitlines()))
    print(diff)
    data = []
    current_section = "No Section"
    buffer_text = []
    buffer_type = None
    buffer_line = None

    for index, line in enumerate(diff):
        if line.startswith(('  ==', '+ ==')):
            if buffer_text:
                data.append({
                    'Type': buffer_type,
                    'Section': current_section,
                    'Line': buffer_line,
                    'Text': '\n'.join(buffer_text)
                })
                buffer_text = []
            current_section = line[1:].strip() if line.startswith('  ') else line[2:].strip()

        if line[0] in ('+', '-'):
            if buffer_type and buffer_type != line[0]:
                data.append({
                    'Type': buffer_type,
                    'Section': current_section,
                    'Line': buffer_line,
                    'Text': '\n'.join(buffer_text)
                })
                buffer_text = [line[2:]]
                buffer_type = line[0]
                buffer_line = index + 1
            else:
                if not buffer_text:
                    buffer_line = index + 1
                buffer_text.append(line[2:])
                buffer_type = line[0]

    if buffer_text:
        data.append({
            'Type': buffer_type,
            'Section': current_section,
            'Line': buffer_line,
            'Text': '\n'.join(buffer_text)
        })

    return pd.DataFrame(data, columns=['Type', 'Section', 'Line', 'Text'])

#%%diff függvény merge nélkül
def diff_to_dataframe_with_section_no_merge(text1, text2):
    d = difflib.Differ()
    diff = list(d.compare(text1.splitlines(), text2.splitlines()))

    data = []
    current_section = "No Section"

    for index, line in enumerate(diff):
        if line.startswith(('  ==', '+ ==')):
            current_section = line[1:].strip() if line.startswith('  ') else line[2:].strip()

        if line[0] in ('+', '-'):
            data.append({
                'Type': line[0],
                'Section': current_section,
                'Line': index + 1,
                'Text': line[2:]
            })

    return pd.DataFrame(data, columns=['Type', 'Section', 'Line', 'Text'])

def iscommunity(namespacename):
    return namespacename.upper().startswith("WIKIPEDIA") or namespacename.upper().endswith('TALK')
#%%logfeldolgozók

def process_dataframe(df: pd.DataFrame, column: str) -> pd.DataFrame:
    def process_param_data(input_data):
        if input_data is None or pd.isna(input_data):
            return {}
        try:
            if isinstance(input_data, str):
                input_data = input_data.encode('utf-8')
            data = phpserialize.loads(input_data)
            cleaned_data = {}
            for key, value in data.items():
                key_parts = key.decode('utf-8').split('::')
                if len(key_parts) < 2:
                    continue
                cleaned_key = key_parts[1]
                if isinstance(value, dict):
                    cleaned_value = ', '.join(
                        item.decode('utf-8') if isinstance(item, bytes) else str(item)
                        for item in value.values()
                    )
                else:
                    cleaned_value = value.decode('utf-8') if isinstance(value, bytes) else value
                cleaned_data[cleaned_key] = cleaned_value
            return cleaned_data
        except (ValueError, TypeError):
            try:
                rows = input_data.decode('utf-8').split('\n')
            except AttributeError:
                rows = input_data.split('\n')
            results = {}
            for index, row in enumerate(rows):
                if row.strip():
                    results[f'col{index+1}'] = row.strip()
            return results

    if column not in df.columns:
        raise ValueError(f"A megadott oszlop ('{column}') nem található a DataFrame-ben.")
    expanded_data = df[column].apply(process_param_data).apply(pd.Series)
    #az expand hatására előfordulhatnak ismételt oszlopnevek, indexelés:
    result = pd.concat([df, expanded_data], axis=1)
    for col in result.columns[result.columns.duplicated()].unique():
        count = 0
        for idx in range(len(result.columns)):
            if result.columns[idx] == col:
                result.columns.values[idx] = f"{col}_{count}"
                count += 1

    return result
    