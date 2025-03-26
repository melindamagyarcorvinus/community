/*UserRelations1: thanks*/
insert userrelationtypes (name) values ('thanks')

select * from imp_thanks_log_df --17732 köszönet
--A contributor_username a megköszönõ, a logtitle tartalmazza a megköszöntött adott idõben érvényes aktuális nevét
select count(*) from imp_thanks_log_df left join users  on contributor_id=originalid where users.id is null  --a megköszöntõk mind ismertek
--megköszöntöttek azonosítása. A log a "logtitle" mezõben a megköszöntött user userlapjának nevét tartalmazza. 
--Kérdés, hogy ez az aktuális usernévnek, vagy az adott idõpontbelinek felel-e meg
--#hipotézis: az aktuálisan érvényes usernévnek felel meg
select count(*) from
(
select imp_thanks_log_df.id as log_id, ua.userid as thankeduserid
from imp_thanks_log_df join userattributes ua
on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(substring(logtitle, 6, 1000))=ua.cs_value 
and convert(varbinary(max), ua.value)=convert(varbinary(max), substring(logtitle, 6, 1000))
where ua.validto is null  --> ez jelöli az aktuális érvényességet
) as X
-->select 17732-17696 --> mindössze 36 esetben nem talál
with  x as
(
select imp_thanks_log_df.id as log_id, ua.userid as thankeduserid
from imp_thanks_log_df join userattributes ua
on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(substring(logtitle, 6, 1000))=ua.cs_value 
and convert(varbinary(max), ua.value)=convert(varbinary(max), substring(logtitle, 6, 1000))
where ua.validto is null  --> ez jelöli az aktuális érvényességet
)
select * from imp_thanks_log_df where id not in (select log_id from x)
--> a 36 eset 10 felhasználóhoz kötõdik, melyek közül 5 anonim
--> az öt felhasználó: 
/*User:Arctic Kangaroo
User:Jim Cartar
User:George.Edward.C
User:Satdeep gill
User:Goldenburg111

select * from userattributes where value ='Arctic Kangaroo'  --> átnevezett felhasználó
select * from userattributes where value ='Jim Cartar' --> nem létezõ felhasználó
select * from userattributes where value ='George.Edward.C' --> nem létezõ felhasználó
select * from userattributes where value ='Satdeep gill' --> nem létezõ felhasználó
select * from userattributes where value ='Goldenburg111' --> nem létezõ felhasználó
A nem létezõ felhasználók nem rendelkeznek bejegyzéssel a renameuser logban
*/
--azt a megállapítást, hogy a köszönetnaplóban az aktuális userneveket látjuk, fontos megerõsíteni, mert elméletileg elõfordulhat, hogy a most adott
--usernévvel létezõ user a korábbiakban más néven létezett
--Ehhez megvizsgáljuk azokat a már nem érvényes userneveket, amely nevek jelenleg sem tartoznak senkihez, de a köszönetnapló hivatkozást tartalmaz rájuk.
select * from userattributes ua1
where ua1.attributeid=7 and validto is not null and not exists(select 1 from userattributes ua2 where ua2.attributeid=7 and ua2.validto is null 
and ua1.cs_value=ua2.cs_value 
and convert(varbinary(max), ua1.value)=convert(varbinary(max), ua2.value))
and exists(select 1 from  imp_thanks_log_df where concat('User:', ua1.value) = logtitle)
--> a lekérdezés egyetlen eredményt ad, ami outliernek tekinthetõ. Olyan érvénytelen usernévhez tehát, aminek nincs aktuálisan létezõ megfelelõje, nem tartozik köszönet

if not exists(select 1 from userrelationtypes where name='thanks')
  insert userrelationtypes (name) values ('thanks')

with  x as
(
select imp_thanks_log_df.id as log_id, timestamp, u.id as thankinguserid, ua.userid as thankeduserid, ua.value
from imp_thanks_log_df join userattributes ua
on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(substring(logtitle, 6, 1000))=ua.cs_value 
and convert(varbinary(max), ua.value)=convert(varbinary(max), substring(logtitle, 6, 1000))
join users u on contributor_id=originalid
where ua.validto is null  --> ez jelöli a késõbbi átnevezést
)
insert userrelations (fromuserid, touserid, validfrom, validto, userrelationtypeid)
select distinct thankinguserid, thankeduserid, timestamp, timestamp, (select id from userrelationtypes where name='thanks') from x

