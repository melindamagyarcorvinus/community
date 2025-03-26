import os
import numpy as np
import wikilib2
import preprocessing as pp
import pandas as pd

'''
revisions_file_path = 'C:/Work/Communities/Data/hu/huwiki-20240801-pages-meta-history6.xml-p1983743p1992220'
working_folder_path = 'C:/Work/Communities/Code/Data'
usergroups_file_path = 'C:/Work/Communities/Data/hu/huwiki-20240801-user_groups.sql'
log_file_path = 'C:/Work/Communities/Data/hu/huwiki-20240801-pages-logging.xml'
'''

revisions_file_path = r'C:\Work\Communities\Data\simple\simplewiki-20240801-pages-meta-history.xml'
working_folder_path = r'C:/Work/Communities/Code/Data/Simple'
usergroups_file_path = r'C:\Work\Communities\Data\simple\simplewiki-20240801-user_groups.sql'
log_file_path = r'C:\Work\Communities\Data\simple\simplewiki-20240801-pages-logging.xml'


pp.init(revisions_file_path, usergroups_file_path, log_file_path, working_folder_path)
page_index_mapping_path= pp.create_or_load_btree_file()  #
pp.create_or_load_cleaned_revisions_file()
pages_df, discarded_pages_df = pp.getpages(usecache=True)
pages_df = pd.concat([pages_df, discarded_pages_df])

revisions_df=pp.getrevisions(pages_df, usecache=False)
ugdf = pp.getusergroupassignments()  #ebben aktuÃ¡lis csoporthozzÃ¡rendelÃ©sek vannak idÅbÃ©lyeg nÃ©lkÃ¼l
users_df = pp.getusers(revisions_df, ugdf, usecache = False) 
review_log_df = pp.getlog('review', usecache=False)
protect_log_df = wikilib2.process_dataframe(pp.getlog('protect', usecache=True), 'params')
newusers_log_df = wikilib2.process_dataframe(pp.getlog('newusers', usecache=True), 'params')
thanks_log_df=  wikilib2.process_dataframe(pp.getlog('thanks', usecache=False), 'params')
renameuser_log_df = wikilib2.process_dataframe(pp.getlog('renameuser', usecache=True), 'params')
rights_log_df = wikilib2.process_dataframe(pp.getlog('rights', usecache=True), 'params')
block_log_df = wikilib2.process_dataframe(pp.getlog('block', usecache=True), 'params')
usermerge_log_df = wikilib2.process_dataframe(pp.getlog('usermerge', usecache=True), 'params')
delete_log_df = wikilib2.process_dataframe(pp.getlog('delete', usecache=True), 'params')
patrol_log_df = wikilib2.process_dataframe(pp.getlog('patrol', usecache=True), 'params')
create_log_df = wikilib2.process_dataframe(pp.getlog('create', usecache=True), 'params')
move_log_df = wikilib2.process_dataframe(pp.getlog('move', usecache=True), 'params')
usermerge_log_df = wikilib2.process_dataframe(pp.getlog('usermerge', usecache=True), 'params')
protect_log_df = wikilib2.process_dataframe(pp.getlog('protect', usecache=True), 'params')
contentmodel_log_df = wikilib2.process_dataframe(pp.getlog('contentmodel', usecache=True), 'params')
gblblock_log_df = wikilib2.process_dataframe(pp.getlog('gblblock', usecache=True), 'params')
managetags_log_df = wikilib2.process_dataframe(pp.getlog('managetags', usecache=True), 'params')
globalauth_log_df = wikilib2.process_dataframe(pp.getlog('globalauth', usecache=True), 'params')
review_log_df = wikilib2.process_dataframe(pp.getlog('review', usecache=True), 'params')



#%% DB
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.dialects.mssql import NVARCHAR
import sqlalchemy.types as sql_types
engine = create_engine(r'mssql+pyodbc://sa:Informatikai.@.\EXPRESS2022/Community?driver=ODBC+Driver+17+for+SQL+Server')
pp.write_df_to_sql(df=revisions_df, table_name='imp_revisions', con=engine, index=False, if_exists='replace', method='multi', chunksize=100)
pp.write_df_to_sql(df=newusers_log_df, table_name='imp_newusers_log_df', con=engine, index=False, if_exists='replace', method='multi', chunksize=100)

pp.write_df_to_sql(df=pages_df, table_name='imp_pages', con=engine, index=False, if_exists='replace', method='multi', chunksize=100)
pp.write_df_to_sql(df=renameuser_log_df, table_name='imp_renameuser_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)

pp.write_df_to_sql(df=thanks_log_df, table_name='imp_thanks_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)
pp.write_df_to_sql(df=namespace_df, table_name='imp_namespace_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)
pp.write_df_to_sql(df=rights_log_df, table_name='imp_rights_log_df', con=engine, index=False, if_exists='replace', method='multi', chunksize=100)
pp.write_df_to_sql(df=block_log_df, table_name='imp_block_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)
pp.write_df_to_sql(df=usermerge_log_df, table_name='imp_usermerge_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)

pp.write_df_to_sql(df=patrol_log_df, table_name='imp_patrol_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)

pp.write_df_to_sql(df=create_log_df, table_name='imp_create_log_df', con=engine, index=False, if_exists='append', method='multi', chunksize=100)
pp.write_df_to_sql(df=delete_log_df, table_name='imp_delete_log_df', con=engine, index=False, if_exists='replace', method='multi', chunksize=100)

