select u.id as userid, attributeid,  originalid, value, cs_value, ua.id as userattributeid
from attributes a, users u join  userattributes ua
on u.id=ua.userid
where validto is null  and a.entitytype='user' and a.name='username'


select ca.* from contexts c join contextattributes ca on c.id=ca.contextid where originaltype='Namespace'

select * from contexts where parentid=4

user1-user2 párosokat akarok

select * from attributes
insert attributes (name, datatypeid, entitytype) values ('type', 1, 'context')

insert contextattributes (attributeid, contextid, validfrom) values (19, 1, '1900.01.01')

insert contextattributes (attributeid, contextid, validfrom, value) values (19, 1, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 2, '1900.01.01', 'technical')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 3, '1900.01.01', 'user')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 4, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 5, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 6, '1900.01.01', 'technical')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 7, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 8, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 9, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 10, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 11, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 12, '1900.01.01', 'content')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 13, '1900.01.01', 'user')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 14, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 15, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 16, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 17, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 18, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 19, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 20, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 21, '1900.01.01', 'community')
insert contextattributes (attributeid, contextid, validfrom, value) values (19, 22, '1900.01.01', 'community')

Egy ember bejövõ fokszáma az ahányan a saját lapján megszólították valaha


select ownerid, count(distinct creatoruserid) indegree, count(*)
--into #indegree
from contexts c join contents cnt on c.id=cnt.contextid
where ownerid is not null and ownerid <> creatoruserid
group by ownerid
order by 2 desc

select * from contexts where parentid is null


select * from #indegree order by 2 desc

select  cast(year(uat.value) as varchar(4))+format(datepart(quarter, cast(uat.value as datetime2)), '00'), * 
from #indegree join users on #indegree.ownerid=users.id join userattributes uat on uat.userid=users.id  and uat.attributeid=11
join userattributes uan on uan.userid=users.id  and uan.attributeid=7 and uan.validto is null

--Csúszóablak: mindig az aktuális negyedév + négy negyedévet nézünk, és egyesével haladunk végig.
select top * from contents join users on users.id=creatoruserid order by createdon
/*a modell célváltozója „churned”, azaz lemorzsolódott értéket vesz fel, ha egy négy negyedéves idõszakban a felhasználó aktív volt, majd az ablakot követõ négy negyedéves idõszakban ezt a szintet (öt szerkesztés négy negyedév alatt) már nem érte el. Ellenkezõ esetben az érték „stay”, azaz marad. */
/*Aktivitásnak tekinthetõ egy négy negyedéves idõszakban legalább öt különbözõ napon történõ szerkesztés. */

/*MSC magyarázóváltozók*/
regquarter  --select  cast(year(value) as varchar(4))+format(datepart(quarter, cast(value as datetime2)), '00'), * from #indegree join users on #indegree.ownerid=users.id join userattributes ua on ua.userid=users.id  and attributeid=11
edits in window
active days in window
active quarters in window
all edits
all active days
all active quarters
thanks in window
thanked in window
average accept in window
trusted
daystotrust
revision check system active
degree editors
degree community
degree content

select count(*) 
from [dbo].[imp_rights_log_df]

select * from attributes

select * from contexts where parentid >100

select * from contextrelations

select namespaceattributes.value, count(*) 
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' and isnull(pagerevs.creatoruserid,0)<>isnull(pages.ownerid,0)
group by namespaceattributes.value

select creatoruserid, count(*) 
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' --and pagerevs.creatoruserid<>pages.ownerid
group by creatoruserid

select count(distinct creatoruserid) from contents


------------------
select namespaceattributes.value, count(*), count(distinct pagerevs.creatoruserid)
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' and isnull(pagerevs.creatoruserid,0)<>isnull(pages.ownerid,0)
and not exists(select 1 from userattributes ua  where ua.attributeid=16 and ua.value in ('bot' , 'flood')
and ua.userid=pagerevs.creatoruserid and pagerevs.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, pagerevs.createdon))
group by namespaceattributes.value

/*Ez a lekérdezés megmutatja, hogy hány szerkesztés történt a különbözõ névtértípusokban hány különbözõ user által, az explicit bot és flood userek, valamint a saját oldalakon végzett szerkesztések nélkül
community	437728	15691
content	5667796	92254
technical	3855	156
user	686151	9861
*/

select year(pagerevs.createdon), namespaceattributes.value, count(*), count(distinct pagerevs.creatoruserid)
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' and isnull(pagerevs.creatoruserid,0)<>isnull(pages.ownerid,0)
and not exists(select 1 from userattributes ua  where ua.attributeid=16 and ua.value in ('bot' , 'flood')
and ua.userid=pagerevs.creatoruserid and pagerevs.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, pagerevs.createdon))
group by namespaceattributes.value, year(pagerevs.createdon)
order by 1

with proba as(
select creatoruserid, year(pagerevs.createdon) year,  month(pagerevs.createdon) month, namespaceattributes.value as type, count(*) count
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' and isnull(pagerevs.creatoruserid,0)<>isnull(pages.ownerid,0)
and not exists(select 1 from userattributes ua  where ua.attributeid=16 and ua.value in ('bot' , 'flood')
and ua.userid=pagerevs.creatoruserid and pagerevs.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, pagerevs.createdon))
and year(pagerevs.createdon)=2024
group by creatoruserid, namespaceattributes.value, year(pagerevs.createdon), month(pagerevs.createdon)
)
select * from proba where creatoruserid in (select creatoruserid from proba group by creatoruserid having count(*)>1)
order by 1, 2, 3


with szerktypes as
(select  creatoruserid userid, namespaceattributes.value as type, count(*) as darab
from contexts namespaces join contexts pages on pages.parentid=namespaces.id join contextattributes namespaceattributes on namespaceattributes.contextid=namespaces.id and attributeid=19
join contents pagerevs on pagerevs.contextid=pages.id
where namespaces.originaltype='Namespace' and pages.originaltype='Page' and isnull(pagerevs.creatoruserid,0)<>isnull(pages.ownerid,0)
and not exists(select 1 from userattributes ua  where ua.attributeid=16 and ua.value in ('bot' , 'flood')
and ua.userid=pagerevs.creatoruserid and pagerevs.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, pagerevs.createdon))
group by creatoruserid, namespaceattributes.value)
select * into #szerktypes from szerktypes


with thx as
(select touserid as userid, count(*) as thxdarab from userrelations where userrelationtypeid=1 group by touserid)/*,
rthx as
(select fromuserid as userid, count(*) as thxdarab from userrelations where userrelationtypeid=1 group by fromuserid)*/
select creatoruserid,  ua.value as username, min(createdon) first_activity, 
max(createdon) last_activity, datediff(dd, min(createdon), max(createdon)) as tenure, isnull(min(szerktypes_c.darab),0) as communityedits, isnull(min(szerktypes_cnt.darab),0) as contentedits,  isnull(min(szerktypes_usr.darab),0) as  useredits, 
isnull(min(thx.thxdarab),0) as thankscount
--, isnull(min(rthx.thxdarab),0) as receivedthankscount
, count(distinct cast(contents.createdon as date)) active_days
from contents left join #szerktypes szerktypes_c on contents.creatoruserid=szerktypes_c.userid and szerktypes_c.type='community'
left join #szerktypes szerktypes_cnt on contents.creatoruserid=szerktypes_cnt.userid and szerktypes_cnt.type='content'
left join #szerktypes szerktypes_usr on contents.creatoruserid=szerktypes_usr.userid and szerktypes_usr.type='user'
left join thx on contents.creatoruserid=thx.userid
--left join rthx on contents.creatoruserid=thx.userid
join userattributes ua on contents.creatoruserid=ua.userid and attributeid=7 and validto is null
where not exists(select 1 from userattributes ua  where ua.attributeid=16 and ua.value in ('bot' , 'flood')
and ua.userid=contents.creatoruserid and contents.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, contents.createdon))
group by creatoruserid, ua.value
-->ez az adathalmaz egy survival analízishez jó lehetne, de túlzottan sok statisztikai magyarázkodást igényel. 
--Mindenesetre minden évre és felhasználóra megmutatja a szerkesztések, aktív napok, kapott és küldött köszönetek számát, elsõ és utolsó aktivitás idõpontját.
--A köszönetekkel nem lehet számolni a köszönetrendszer elõtt.

/*hogyan jönnek létre felhasználói kapcsolatok?*/


--edits under bot flag
select cnt.id as contentid
into #editsunderbotflag
from contents cnt join userattributes ua  on cnt.creatoruserid=ua.userid
where ua.attributeid=16 and ua.value in ('bot' , 'flood') and cnt.createdon between isnull(validfrom, cast(0 as datetime)) and isnull(validto, cnt.createdon)

with titles as
(select contextid, value from contextattributes where attributeid=17)
select titles.contextid, titles.value, count(*)  
from contents join titles on contents.contextid=titles.contextid
where not exists (select 1 from #editsunderbotflag where contentid=contents.id)
group by titles.contextid, titles.value 
order by 3 desc

select c.creatoruserid, (select count(distinct creatoruserid) from contents c2 where c2.contextid=c.contextid and c2.createdon between dateadd(dd, -5, c.createdon) and dateadd(dd, 5, c.createdon))
from contents c where contextid=70011


select c.createdon d1, c.creatoruserid u1, c2.createdon d2, c2.creatoruserid u2
into #teszt
from contents c  join contents c2 on c.contextid=c2.contextid and c2.createdon between dateadd(dd, -5, c.createdon) and dateadd(dd, 5, c.createdon)
where c.contextid=70011 and c.creatoruserid<>c2.creatoruserid



--Ez a lekérdezés a felhasználói vitalapokon létrejövõ közvetlen kapcsolatokat adja meg - ownere csak ilyen lapoknak van.
select distinct ownerid, creatoruserid, 'user'
from contexts c join contents cnt on c.id=cnt.contextid
where ownerid is not null and ownerid <> creatoruserid
and cnt.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
--> 93 ezer közvetlen interperszonális kapcsolat jött létre 2014 január elseje után(?)
/*
select ca.value, pc.id as contextid 
into #contexttypes
from contexts nc join contexts pc on nc.id=pc.parentid
join  contextattributes ca on nc.id=ca.contextid and attributeid=19 
*/
--
union
select distinct c.creatoruserid u1, c2.creatoruserid u2, ct.value
from contents c  join contents c2 on c.contextid=c2.contextid and c2.createdon between dateadd(dd, -5, c.createdon) and dateadd(dd, 5, c.createdon)
join #contexttypes ct on ct.contextid=c.contextid
where /*c.contextid=70011 and */c.creatoruserid<>c2.creatoruserid and c.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid in (c.id, c2.id))

/*ÉVENTE*/
--Ez a lekérdezés a felhasználói vitalapokon létrejövõ közvetlen kapcsolatokat adja meg - ownere csak ilyen lapoknak van.
select distinct year(cnt.createdon) year, ownerid user1, creatoruserid user2, 'user' as type
into #connectionsperyear
from contexts c join contents cnt on c.id=cnt.contextid
where ownerid is not null and ownerid <> creatoruserid
and cnt.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid=cnt.id)
union
select distinct year(c.createdon), c.creatoruserid u1, c2.creatoruserid u2, ct.value
from contents c  join contents c2 on c.contextid=c2.contextid and c2.createdon between dateadd(dd, -5, c.createdon) and dateadd(dd, 5, c.createdon)
join #contexttypes ct on ct.contextid=c.contextid
where /*c.contextid=70011 and */c.creatoruserid<>c2.creatoruserid and c.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid in (c.id, c2.id))
union
--ezek pedig a köszik
select year(validfrom), fromuserid, touserid, 'thanks' from userrelations where userrelationtypeid=1 and validfrom >= '2014.01.01'


select user1 from #connectionsperyear
union
select user2 from #connectionsperyear
-->66600 esemény

--> a botokat a jognapló alapján nem mind lehet megtalálni, a user group assignments kivonat is kell hozzá
select * from #connectionsperyear 
where user1 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
and user2 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
--#473133 esemény

/*HA nincs groupolás, akkor felesleges levágni a dátumból az évet, ez a distinctelés szempontjából fontos*/
--Ez a lekérdezés a felhasználói vitalapokon létrejövõ közvetlen kapcsolatokat adja meg - ownere csak ilyen lapoknak van.
with data as 
(
select distinct cast(cnt.createdon as date) as date, ownerid user1, creatoruserid user2, 'user' as type
from contexts c join contents cnt on c.id=cnt.contextid
where ownerid is not null and ownerid <> creatoruserid
and cnt.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid=cnt.id)
union
select distinct cast(c.createdon as date), c.creatoruserid u1, c2.creatoruserid u2, ct.value
from contents c  join contents c2 on c.contextid=c2.contextid and c2.createdon between dateadd(dd, -5, c.createdon) and dateadd(dd, 5, c.createdon)
join #contexttypes ct on ct.contextid=c.contextid
where /*c.contextid=70011 and */c.creatoruserid<>c2.creatoruserid and c.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid in (c.id, c2.id))
union
--ezek pedig a köszik
select cast(validfrom as date), fromuserid, touserid, 'thanks' from userrelations where userrelationtypeid=1 and validfrom >= '2014.01.01'
)
select * 
into #connectionsbyday
from data
where user1 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
and user2 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))

with x as(
select user1, user2, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
union
select user2, user1, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
)
select user1, user2, min(date) from x group by user1, user2

with x as(
select user1, user2, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
union
select user2, user1, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
)
select user1, user2, min(date) from x group by user1, user2

select * from #connectionsbyday


with x as(
select user1, user2, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
union
select user2, user1, date from  #connectionsbyday where year(date)=2014 and month(date)=1 and type='user'
)
select user1, user2, min(date) from x 
group by user1, user2
order by user1


select greatest(user1, user2), least(user1, user2), min(date) from #connectionsbyday where type='user'  and year(date)=2014 and month(date)=1
group by greatest(user1, user2), least(user1, user2)

select greatest(1,2)

select count(*) from contents where creatoruserid=0 is null
select top 10 * from contents



with data as 
(
select distinct c.ownerid, cast(cnt.createdon as date) as date, ownerid user1, creatoruserid user2, 'user' as type
from contexts c join contents cnt on c.id=cnt.contextid
where ownerid is not null and ownerid <> creatoruserid
--and cnt.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid=cnt.id)
union
select distinct null, cast(c.createdon as date), c.creatoruserid u1, c2.creatoruserid u2, ct.value
from contents c  join contents c2 on c.contextid=c2.contextid and cast(c2.createdon as date)=cast(c.createdon as date)--c2.createdon between dateadd(dd, 0, c.createdon) and dateadd(dd, 0, c.createdon)
join #contexttypes ct on ct.contextid=c.contextid
where /*c.contextid=70011 and */c.creatoruserid<>c2.creatoruserid --and c.createdon>='2014.01.01'  --az elsõ thanks idõpontja 20130907
and not exists (select 1 from #editsunderbotflag where contentid in (c.id, c2.id))
union
--ezek pedig a köszik
select null, cast(validfrom as date), fromuserid, touserid, 'thanks' from userrelations where userrelationtypeid=1 and validfrom >= '2014.01.01'
)
select * 
into #connectionsbydayalltime0  --> ment csv-be
from data
where user1 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
and user2 not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))

select isnull(ownerid, '') ownerid, date, user1, user2, type from #connectionsbydayalltime0
select c.createdon, ct.value, count(*) as darab
into #editsall
from contents c  join #contexttypes ct on ct.contextid=c.contextid
where not exists (select 1 from #editsunderbotflag where contentid=c.id)
and creatoruserid not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
group by c.createdon, ct.value

select c.contextid, ct.value as type, min(c.createdon) created
into #firstedits
from  contents c join #contexttypes ct on ct.contextid=c.contextid
where not exists (select 1 from #editsunderbotflag where contentid=c.id)
and creatoruserid not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
group by c.contextid, ct.value


select cast(createdon as date) date, value as type, sum(darab) count
from #editsall
group by cast(createdon as date), value
order by 1


select * from userattributes where userid=15540046
select * from 


select cast(created as date) date, type, count(*) darab from #firstedits 
group by cast(created as date), type


select cast(createdon as date) date, value as type, sum(darab) count
from #editsall
group by cast(createdon as date), value
order by 1



select creatoruserid, ct.value, count(*) darab
into #editsbyuserandtype
from  contents c join #contexttypes ct on ct.contextid=c.contextid
where not exists (select 1 from #editsunderbotflag where contentid=c.id)
and creatoruserid not in (select id from users where originalid in (select ug_user from user_groups where ug_group='bot'))
group by creatoruserid, ct.value

select value, sum(darab)/1000.00*1000, sum(darab) from #editsbyuserandtype group by value
select * from #editsbyuserandtype where value='user' order by 3 desc


select * from userattributes where userid=16061349
select * from users where id=16061349


select id from users where originalid in (select ug_user from user_groups where ug_group='bot'
select * from user_groups where ug_group='bot' and ug_user = 114482



select * from #editsunderbotflag join contents on contentid=contents.id
where creatoruserid=16061349

select * from contextattributes where attributeid=17 and contextid in 
(select contextid from contextattributes where value='community')
select * from contextattributes where value='User'