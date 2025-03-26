select count(*) from imp_pages_df_w_rd dp  --833813 oldal
select count(*) from imp_pages_df  --720627 oldal  �tir�ny�t�sok n�lk�l


--4. Oldalak contextsbe
insert contexts(originalid, originaltype, parentid)
select p.page_id, 'Page', cparent.id 
from imp_pages_df p join contexts cparent on cparent.originaltype='Namespace' and cparent.originalid=p.namespace_id


--5. oldalc�mek contextattributesba
insert contextattributes (contextid, attributeid, value, validfrom)
select c.id, a.id, p.title, cast(0 as datetime)
from imp_pages_df p join contexts c on p.page_id=c.originalid and c.originaltype='Page', attributes a
where a.entitytype='context' and a.name='name'

/*contextOwner be�ll�t�sa*/
select charindex('/', pca.value), substring(pca.value, 6, 1000), substring(pca.value, 6, iif(pca.value not like '%/%', 1000, charindex('/', pca.value)-6)), * 
from
contexts nc join contextattributes nca on nc.id=nca.contextid, --User namespace 
contexts pc join contextattributes pca on pc.id=pca.contextid  --User namespacebe tartoz� oldalak
where nca.value='User' and nc.originaltype='Namespace'
and pc.originaltype='Page' and pc.parentid=nc.id
--> 35425 user namespacebe tartoz� oldal van a konvert�lt adatokb�l sz�m�tva is

update pc set ownerid = ua.userid 
from
contexts nc join contextattributes nca on nc.id=nca.contextid, --User namespace 
contexts pc join contextattributes pca on pc.id=pca.contextid  --User namespacebe tartoz� oldalak
join userattributes ua on ua.attributeid=7 and ua.validto is null and checksum(substring(pca.value, 6, iif(charindex('/', pca.value)<6, 1000, charindex('/', pca.value)-6)))=ua.cs_value 
and  convert(varbinary(max), ua.value) = convert(varbinary(max),               substring(pca.value, 6, iif(charindex('/', pca.value)<6, 1000, charindex('/', pca.value)-6)))
where nca.value='User' and nc.originaltype='Namespace'
and pc.originaltype='Page' and pc.parentid=nc.id
and ua.id is not null --> 34279-33199=1080 oldalhoz  nem azonos�that�





