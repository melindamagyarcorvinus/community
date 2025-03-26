import os
import csv
import multiprocessing
import time
import pandas as pd

def find_next_page_boundary(file, start_byte, file_size, direction='forward'):
    """A funkció elmozdítja a start_byte-ot a legközelebbi <page> vagy </page> taghoz."""
    file.seek(start_byte)
    if direction == 'forward':
        while True:
            line_start_byte = file.tell()
            line = file.readline()
            if not line or line_start_byte >= file_size:
                return file_size  # Ha elérjük a fájl végét
            if '<page>' in line:
                return line_start_byte
    elif direction == 'backward':
        while True:
            file.seek(max(0, file.tell() - 1024), os.SEEK_SET)  # Ugrás hátrafelé egy blokkal
            lines = file.readlines()
            for i in range(len(lines) - 1, -1, -1):
                if '</page>' in lines[i]:
                    return file.tell() - len('\n'.join(lines[i:]))  # Visszatérünk a </page> záró taghoz
            if file.tell() == 0:
                return 0  # Ha elértük a fájl elejét

def process_chunk_multiprocessing(file_path, start_byte, end_byte, output_file_path):
    print(f"Feldolgozás kezdete: {start_byte}, vége: {end_byte}")
    with open(output_file_path, 'w', newline='', encoding='utf-8') as index_file:
        csv_writer = csv.writer(index_file)
        csv_writer.writerow(['page_id', 'revision_id', 'page_start_byte', 'revision_start_byte', 'page_end_byte', 'revision_end_byte'])

        with open(file_path, 'r', encoding='utf-8') as file:
            file.seek(start_byte)
            current_page_id = None
            page_start_byte = None
            revision_start_byte = None
            index_data = []

            while True:
                line_start_byte = file.tell()
                if line_start_byte >= end_byte:
                    break
                line = file.readline()
                if not line:
                    break
                if '<page>' in line:
                    current_page_id = None
                    page_start_byte = line_start_byte
                elif '<id>' in line and current_page_id is None:
                    current_page_id = line.split('<id>')[1].split('</id>')[0]
                elif '<revision>' in line:
                    current_revision_id = None
                    revision_start_byte = line_start_byte
                elif '<id>' in line and current_revision_id is None:
                    current_revision_id = line.split('<id>')[1].split('</id>')[0]
                elif '</revision>' in line:
                    revision_end_byte = file.tell()
                    if current_page_id and current_revision_id:
                        index_data.append([
                            current_page_id,
                            current_revision_id,
                            page_start_byte,
                            revision_start_byte,
                            None,
                            revision_end_byte
                        ])
                    current_revision_id = None
                elif '</page>' in line:
                    page_end_byte = file.tell()
                    for entry in index_data:
                        entry[4] = page_end_byte
                        csv_writer.writerow(entry)
                    index_data = []

def create_index_files_multiprocessing(file_path, output_dir, num_chunks):
    file_size = os.path.getsize(file_path)
    chunk_size = file_size // num_chunks
    processes = []

    for i in range(num_chunks):
        start_byte = i * chunk_size
        end_byte = file_size if i == num_chunks - 1 else (i + 1) * chunk_size

        with open(file_path, 'r', encoding='utf-8') as file:
            start_byte = find_next_page_boundary(file, start_byte, file_size, direction='forward')
            end_byte = find_next_page_boundary(file, end_byte, file_size, direction='forward')

        output_file_path = os.path.join(output_dir, f'index_part_{i+1}.csv')
        p = multiprocessing.Process(target=process_chunk_multiprocessing, args=(file_path, start_byte, end_byte, output_file_path))
        processes.append(p)
        p.start()

    for p in processes:
        p.join()


def create_page_index_mapping(index_dir, num_chunks, output_file_path):
    page_index_mapping = {}

    for i in range(1, num_chunks + 1):
        file_path = os.path.join(index_dir, f'index_part_{i}.csv')
        df = pd.read_csv(file_path)

        for page_id in df['page_id'].unique():
            if page_id not in page_index_mapping:
                page_index_mapping[page_id] = []
            page_index_mapping[page_id].append(f'index_part_{i}.csv')

    # Az eredmény mentése
    #output_file_path = os.path.join(output_dir, 'page_index_mapping.csv')
    with open(output_file_path, 'w', newline='', encoding='utf-8') as output_file:
        csv_writer = csv.writer(output_file)
        csv_writer.writerow(['page_id', 'index_files'])

        for page_id, files in page_index_mapping.items():
            csv_writer.writerow([page_id, ', '.join(files)])

    print(f"A page_index_mapping.csv fájl elkészült: {output_file_path}")

import sys
import os

if __name__ == '__main__':
    params = {}
    for arg in sys.argv[1:]: 
        # Az első elem a script neve, azt kihagyjuk
        key, value = arg.split("=")
        params[key] = value
    file_path = params.get("allpageswithrevisions", "C:/Work/Communities/Data/huwiki-20240801-pages-meta-history6.xml-p1983743p1992220")
    index_file_path = params.get("indexfile", "C:/Work/Communities/Data/index/huwiki-20240801-pages-meta-history6-index.csv")

    #output_dir = params.get("param1", "C:/Work/Communities/Data/IndexFiles")
    output_dir = os.path.join(os.path.dirname(index_file_path)+'/index')
    if not os.path.exists(output_dir):
       os.makedirs(output_dir)
    num_chunks = 20

    start_time = time.time()
    create_index_files_multiprocessing(file_path, output_dir, num_chunks)
    end_time = time.time()

    print(f"Az indexelés ideje: {end_time - start_time:.2f} másodperc")

    create_page_index_mapping(output_dir, num_chunks, index_file_path)


'''
import os
import pandas as pd

def count_lines_in_index_files(output_dir, num_chunks):
    total_lines = 0

    for i in range(1, num_chunks + 1):
        file_path = os.path.join(output_dir, f'index_part_{i}.csv')
        df = pd.read_csv(file_path)
        line_count = len(df)
        print(f'{file_path}: {line_count} sor')
        total_lines += line_count

    print(f'Összesen: {total_lines} sor')

# Hívás példa
output_dir = "C:/Work/Communities/Data/simple/IndexFiles"
num_chunks = 20
count_lines_in_index_files(output_dir, num_chunks)
Összesen: 8 752 431 sor
6 947 620
'''


# Példa a kód futtatására
#index_dir = "C:/Work/Communities/Data/simple/indexfiles"
#output_dir = "C:/Work/Communities/Data/simple/"
