import pandas as pd
import difflib

def diff_to_dataframe(file_path1, file_path2):
    with open(file_path1, 'r', encoding='utf-8') as file1:
        file1_lines = file1.read().splitlines()
    with open(file_path2, 'r', encoding='utf-8') as file2:
        file2_lines = file2.read().splitlines()

    d = difflib.Differ()
    diff = list(d.compare(file1_lines, file2_lines))

    data = []
    current_section = "No Section"
    buffer_text = []
    buffer_type = None
    buffer_line = None

    for index, line in enumerate(diff):
        if line.startswith(('  ==', '+ ==')):  # Detect section titles
            if buffer_text:  # Flush the buffer if it has content
                data.append({
                    'Type': buffer_type,
                    'Section': current_section,
                    'Line': buffer_line,
                    'Text': '\n'.join(buffer_text)
                })
                buffer_text = []
            current_section = line[2:].strip() if line.startswith('  ') else line[3:].strip()

        if line[0] in ('+', '-'):
            if buffer_type and buffer_type != line[0]:  # Different type, flush the buffer
                data.append({
                    'Type': buffer_type,
                    'Section': current_section,
                    'Line': buffer_line,
                    'Text': '\n'.join(buffer_text)
                })
                buffer_text = [line[2:]]
                buffer_type = line[0]
                buffer_line = index + 1
            else:  # Same type or buffer is empty
                if not buffer_text:
                    buffer_line = index + 1  # Start a new buffer
                buffer_text.append(line[2:])
                buffer_type = line[0]

    # Flush the remaining buffer
    if buffer_text:
        data.append({
            'Type': buffer_type,
            'Section': current_section,
            'Line': buffer_line,
            'Text': '\n'.join(buffer_text)
        })

    df = pd.DataFrame(data, columns=['Type', 'Section', 'Line', 'Text'])
    return df

# File paths

# Create and display the DataFrame
df_diff = diff_to_dataframe(file_path1, file_path2)
print(df_diff)



def diff_to_dataframe(file_path1, file_path2):
    # Fájlok megnyitása és sorok beolvasása
    with open(file_path1, 'r', encoding='utf-8') as file1:
        file1_lines = file1.read().splitlines()
    with open(file_path2, 'r', encoding='utf-8') as file2:
        file2_lines = file2.read().splitlines()

    # Differ objektum használata a különbségek meghatározására
    d = difflib.Differ()
    diff = list(d.compare(file1_lines, file2_lines))

    # Eltérések gyűjtése egy listába, beleértve a szekciókat is
    data = []
    current_section = "No Section"  # Kezdeti szekció, ha nincs felismert szekció

    for index, line in enumerate(diff):
        if line.startswith(('  ==', '+ ==')):  # Szekció címeket keres
            section_line = line[2:].strip()  # Tisztítja a szekció nevét
            if section_line.startswith('=='):
                current_section = section_line

        if line[0] == '+':
            data.append({
                'Type': 'Added',
                'Section': current_section,
                'Line': index + 1,
                'Text': line[2:]
            })
        elif line[0] == '-':
            data.append({
                'Type': 'Removed',
                'Section': current_section,
                'Line': index + 1,
                'Text': line[2:]
            })

    # DataFrame létrehozása a gyűjtött adatokból
    df = pd.DataFrame(data, columns=['Type', 'Section', 'Line', 'Text'])
    return df


# DataFrame létrehozása és megjelenítése
df_diff = diff_to_dataframe(file_path1, file_path2)
print(df_diff)


def diff_to_dataframe(file_path1, file_path2):
    # Fájlok megnyitása és sorok beolvasása
    with open(file_path1, 'r', encoding='utf-8') as file1:
        file1_lines = file1.read().splitlines()
    with open(file_path2, 'r', encoding='utf-8') as file2:
        file2_lines = file2.read().splitlines()

    # Differ objektum használata a különbségek meghatározására
    d = difflib.Differ()
    diff = list(d.compare(file1_lines, file2_lines))

    # Eltérések gyűjtése egy listába, beleértve a szekciókat is
    data = []
    current_section = "Unknown Section"  # Alapértelmezett szekció címe
    for index, line in enumerate(diff):
        if line.startswith('  =='):  # Feltételezve, hogy a szekció címek '==' karakterekkel kezdődnek
            current_section = line.strip()
        elif line[0] == '+':
            data.append({
                'Type': 'Added',
                'Section': current_section,
                'Line': index + 1,
                'Text': line[2:]
            })
        elif line[0] == '-':
            data.append({
                'Type': 'Removed',
                'Section': current_section,
                'Line': index + 1,
                'Text': line[2:]
            })

    # DataFrame létrehozása a gyűjtött adatokból
    df = pd.DataFrame(data, columns=['Type', 'Section', 'Line', 'Text'])
    return df

# Fájlok útvonalainak megadása (ide írd a saját fájljaid útvonalait)
file_path1 = 'C:/Work/Communities/a.txt'
file_path2 = 'C:/Work/Communities/b.txt'

# DataFrame létrehozása és megjelenítése
df_diff = diff_to_dataframe(file_path1, file_path2)
print(df_diff)


# -*- coding: utf-8 -*-
"""
Created on Mon Aug 19 17:05:54 2024

@author: magyarnóm
"""

import difflib
import pandas as pd

def diff_to_dataframe(file_path1, file_path2):
    # Fájlok megnyitása és sorok beolvasása
    with open(file_path1, 'r', encoding='utf-8') as file1:
        file1_lines = file1.read().splitlines()
    with open(file_path2, 'r', encoding='utf-8') as file2:
        file2_lines = file2.read().splitlines()

    # Differ objektum használata a különbségek meghatározására
    d = difflib.Differ()
    diff = list(d.compare(file1_lines, file2_lines))

    # Eltérések gyűjtése egy listába
    data = []
    for index, line in enumerate(diff):
        if line[0] == '+':
            data.append({'Type': 'Added', 'Line': index + 1, 'Text': line[2:]})  # A plusz jel utáni szöveget mentjük
        elif line[0] == '-':
            data.append({'Type': 'Removed', 'Line': index + 1, 'Text': line[2:]})  # A mínusz jel utáni szöveget mentjük

    # DataFrame létrehozása a gyűjtött adatokból
    df = pd.DataFrame(data, columns=['Type', 'Line', 'Text'])
    return df


# Fájlok útvonalainak megadása
file_path1 = 'C:/Work/Communities/a.txt'
file_path2 = 'C:/Work/Communities/b.txt'

# DataFrame létrehozása és megjelenítése
df_diff = diff_to_dataframe(file_path1, file_path2)
df_diff


import difflib

def character_diff(file_path1, file_path2):
    # Fájlok megnyitása és sorok beolvasása
    with open(file_path1, 'r', encoding='utf-8') as file1:
        file1_text = file1.read().strip()
    with open(file_path2, 'r', encoding='utf-8') as file2:
        file2_text = file2.read().strip()

    # Karakter-alapú összehasonlítás ndiff segítségével
    diff = list(difflib.ndiff(file1_text, file2_text))

    # Különbségek kinyerése és megjelenítése
    for line in diff:
        if line.startswith('+ ') or line.startswith('- '):
            print(line)

# Példa szövegek
file_path1 = 'path_to_first_sentence.txt'  # "Hello word this is a sentence"
file_path2 = 'path_to_second_sentence.txt'  # "Hello world this is a sentence"

# Függvény meghívása
character_diff(file_path1, file_path2)


def inline_diff(s1, s2):
    # difflib.SequenceMatcher használata a hasonlóságok és különbségek meghatározására
    matcher = difflib.SequenceMatcher(None, s1, s2)
    output = []
    for opcode, a0, a1, b0, b1 in matcher.get_opcodes():
        if opcode == 'equal':
            output.append(matcher.a[a0:a1])
        elif opcode == 'insert':
            output.append(f"[+{s2[b0:b1]}]")
        elif opcode == 'delete':
            output.append(f"[-{s1[a0:a1]}]")
        elif opcode == 'replace':
            output.append(f"[-{s1[a0:a1]}][+{s2[b0:b1]}]")
    return ''.join(output)

# Példa szövegek
s1 = "Hello word this is a sentence"
s2 = "Hello world this is a sentence"

# Függvény meghívása és az eredmény kiíratása
print(inline_diff(s1, s2))
