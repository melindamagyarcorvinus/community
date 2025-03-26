--1. Fõ névterek  containersbe
insert containers(originalid, originaltype)
select namespace_id, 'Namespace' from imp_namespace_df where lower(namespacename) not like '%talk'
--2. Talk névterek containersbe
insert containers(originalid, originaltype, parentid)
select talk.namespace_id, 'Namespace', c.id
from imp_namespace_df main join imp_namespace_df talk on ((main.namespacename+' talk'=talk.namespacename) or (talk.namespacename='Talk' and main.namespacename='Main'))
join containers c on c.originaltype='Namespace' and c.originalid=main.namespace_id

--3. Namespacenevek attributútumokba
Insert attributes (name, datatypeid, entitytype)
select 'name', dt.id, 'container'
from datatypes dt where name='string'

insert containerattributes (containerid, attributeid, value, validfrom)
select c.id, a.id, n.namespacename, cast(0 as datetime)
from imp_namespace_df n join containers c on n.namespace_id=c.originalid and c.originaltype='Namespace', attributes a
where a.entitytype='container' and a.name='name'

insert attributes (name, datatypeid, entitytype) values ('type', 1, 'container')

insert containerattributes (attributeid, containerid, validfrom, value) values (19, 1, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 2, '1900.01.01', 'technical')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 3, '1900.01.01', 'user')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 4, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 5, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 6, '1900.01.01', 'technical')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 7, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 8, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 9, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 10, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 11, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 12, '1900.01.01', 'content')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 13, '1900.01.01', 'user')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 14, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 15, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 16, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 17, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 18, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 19, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 20, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 21, '1900.01.01', 'community')
insert containerattributes (attributeid, containerid, validfrom, value) values (19, 22, '1900.01.01', 'community')
