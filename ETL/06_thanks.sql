/*UserRelations1: thanks*/
insert userrelationtypes (name) values ('thanks')

select * from imp_thanks_log_df --17732 k�sz�net
--A contributor_username a megk�sz�n�, a logtitle tartalmazza a megk�sz�nt�tt adott id�ben �rv�nyes aktu�lis nev�t
select count(*) from imp_thanks_log_df left join users  on contributor_id=originalid where users.id is null  --a megk�sz�nt�k mind ismertek
--megk�sz�nt�ttek azonos�t�sa. A log a "logtitle" mez�ben a megk�sz�nt�tt user userlapj�nak nev�t tartalmazza. 
--K�rd�s, hogy ez az aktu�lis usern�vnek, vagy az adott id�pontbelinek felel-e meg
--#hipot�zis: az aktu�lisan �rv�nyes usern�vnek felel meg
select count(*) from
(
select imp_thanks_log_df.id as log_id, ua.userid as thankeduserid
from imp_thanks_log_df join userattributes ua
on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(substring(logtitle, 6, 1000))=ua.cs_value 
and convert(varbinary(max), ua.value)=convert(varbinary(max), substring(logtitle, 6, 1000))
where ua.validto is null  --> ez jel�li az aktu�lis �rv�nyess�get
) as X
-->select 17732-17696 --> mind�ssze 36 esetben nem tal�l
with  x as
(
select imp_thanks_log_df.id as log_id, ua.userid as thankeduserid
from imp_thanks_log_df join userattributes ua
on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(substring(logtitle, 6, 1000))=ua.cs_value 
and convert(varbinary(max), ua.value)=convert(varbinary(max), substring(logtitle, 6, 1000))
where ua.validto is null  --> ez jel�li az aktu�lis �rv�nyess�get
)
select * from imp_thanks_log_df where id not in (select log_id from x)
--> a 36 eset 10 felhaszn�l�hoz k�t�dik, melyek k�z�l 5 anonim
--> az �t felhaszn�l�: 
/*User:Arctic Kangaroo
User:Jim Cartar
User:George.Edward.C
User:Satdeep gill
User:Goldenburg111

select * from userattributes where value ='Arctic Kangaroo'  --> �tnevezett felhaszn�l�
select * from userattributes where value ='Jim Cartar' --> nem l�tez� felhaszn�l�
select * from userattributes where value ='George.Edward.C' --> nem l�tez� felhaszn�l�
select * from userattributes where value ='Satdeep gill' --> nem l�tez� felhaszn�l�
select * from userattributes where value ='Goldenburg111' --> nem l�tez� felhaszn�l�
A nem l�tez� felhaszn�l�k nem rendelkeznek bejegyz�ssel a renameuser logban
*/
--azt a meg�llap�t�st, hogy a k�sz�netnapl�ban az aktu�lis userneveket l�tjuk, fontos meger�s�teni, mert elm�letileg el�fordulhat, hogy a most adott
--usern�vvel l�tez� user a kor�bbiakban m�s n�ven l�tezett
--Ehhez megvizsg�ljuk azokat a m�r nem �rv�nyes userneveket, amely nevek jelenleg sem tartoznak senkihez, de a k�sz�netnapl� hivatkoz�st tartalmaz r�juk.
select * from userattributes ua1
where ua1.attributeid=7 and validto is not null and not exists(select 1 from userattributes ua2 where ua2.attributeid=7 and ua2.validto is null 
and ua1.cs_value=ua2.cs_value 
and convert(varbinary(max), ua1.value)=convert(varbinary(max), ua2.value))
and exists(select 1 from  imp_thanks_log_df where concat('User:', ua1.value) = logtitle)
--> a lek�rdez�s egyetlen eredm�nyt ad, ami outliernek tekinthet�. Olyan �rv�nytelen usern�vhez teh�t, aminek nincs aktu�lisan l�tez� megfelel�je, nem tartozik k�sz�net

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
where ua.validto is null  --> ez jel�li a k�s�bbi �tnevez�st
)
insert userrelations (fromuserid, touserid, validfrom, validto, userrelationtypeid)
select distinct thankinguserid, thankeduserid, timestamp, timestamp, (select id from userrelationtypes where name='thanks') from x

