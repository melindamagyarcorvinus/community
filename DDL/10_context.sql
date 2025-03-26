select count(*) from imp_pages_df_w_rd dp  --833813 oldal
select count(*) from imp_pages_df  --720627 oldal  átirányítások nélkül


--4. Oldalak containersbe
insert containers(originalid, originaltype, parentid)
select p.page_id, 'Page', cparent.id 
from imp_pages_df p join containers cparent on cparent.originaltype='Namespace' and cparent.originalid=p.namespace_id


--5. oldalcímek containerattributesba
insert containerattributes (containerid, attributeid, value, validfrom)
select c.id, a.id, p.title, cast(0 as datetime)
from imp_pages_df p join containers c on p.page_id=c.originalid and c.originaltype='Page', attributes a
where a.entitytype='container' and a.name='name'

/*ContainerOwner beállítása*/
select charindex('/', pca.value), substring(pca.value, 6, 1000), substring(pca.value, 6, iif(pca.value not like '%/%', 1000, charindex('/', pca.value)-6)), * 
from
containers nc join containerattributes nca on nc.id=nca.containerid, --User namespace 
containers pc join containerattributes pca on pc.id=pca.containerid  --User namespacebe tartozó oldalak
where nca.value='User' and nc.originaltype='Namespace'
and pc.originaltype='Page' and pc.parentid=nc.id
--> 35425 user namespacebe tartozó oldal van a konvertált adatokból számítva is

update pc set ownerid = ua.userid 
from
containers nc join containerattributes nca on nc.id=nca.containerid, --User namespace 
containers pc join containerattributes pca on pc.id=pca.containerid  --User namespacebe tartozó oldalak
join userattributes ua on ua.attributeid=7 and ua.validto is null and checksum(substring(pca.value, 6, iif(charindex('/', pca.value)<6, 1000, charindex('/', pca.value)-6)))=ua.cs_value 
and  convert(varbinary(max), ua.value) = convert(varbinary(max),               substring(pca.value, 6, iif(charindex('/', pca.value)<6, 1000, charindex('/', pca.value)-6)))
where nca.value='User' and nc.originaltype='Namespace'
and pc.originaltype='Page' and pc.parentid=nc.id
and ua.id is not null --> 34279-33199=1080 oldalhoz  nem azonosítható





