
/*
A felhasználók konvertálása az ETL folyamat elsõ lépése.
A részfolyamat során a feladat a felhasználók egyedi azonosításra alkalmas ID-jának kinyerése a cél.
A Wikipediában a userek azonosítása userid alapján történik. Az exportált adatbáziskivonatok minden mûvelet esetében az aktuális felhasználónevet tartalmazzák, 
Az átnevezés lehetséges, ezt a mûveletet külön napló tárolja. Egy felhasználónv egy adott idõpillanatban egyedi, de különbözõ idõpontokban két különbözõ user is 
rendelkezhet azonos névvel (ha nincs átfedés)

Az adatok forrása:
- A felhasználók létrehozására irányuló log (imp_newusers_df)
- A szerkesztéseket tároló állomány (imp_revisions_df)
- Minden egyéb olyan log, amely felhasználónév és azonosító párokat tartalmaz.
Elméletileg a felhasználók létrehozására irányuló log elegendõ lenne, de, különösen a korai adatok esetében, nem minden felhasználó létrehozási rekordja található meg.
- A log szerkezete: 
id, timestamp, a regisztrációt végzõ user neve és azonosítója, comment, type, action (altípus), logtitle, params.
Két további számított oszlopot helyez el az elõfeldolgozás. Az elsõ a params oszlop értékének elsõ sora (bizonyos logtípusoknál ezek információt hordoznak), és, amennyiben a 
params php szerializált tömböt tartalmaz, akkor az abból kifejtett tulajdonságok. Ez a két számított oszlop ebben a folyamatban nem hordoz információt.
*/
/*Elõzetes vizsgálatok*/
select count(*) from imp_newusers_log_df --> A napló 1 462 332 sort tartalmaz.
select action, count(*) darab, min(timestamp) elsohasznalat, max(timestamp) utolsohasznalat
from imp_newusers_log_df group by action  order by 2 desc 
--> 5 különféle altípus, autocreate	(1313600), create (145301), newusers (1590), create2 (1526), byemail (315). 
--> a "newusers" nincs aktív használatban, utolsó használata  2006.04.17, helyébe a "create" lépett.
select min(timestamp) from imp_revisions_df
--> A a napló legelsõ rekordja 2005 szeptember 9-én készült, miközben a legelsõ szerkesztés 2001-bõl származik, így nem minden felhasználói fiók létrehozásának idõpontja ismeretes
--Egy usernaplóval szemben jogos feltételezés, hogy midnen létrehozóhoz egyetlen rekord fog társulni (önregisztráció). Ebben az esetben a contributor_id és contributor_name alkalmas
select contributor_id, count(*) from imp_newusers_log_df  group by contributor_id, action having count(*)>1 
--> a hipotézis nem áll meg, user alnaplónként vizsgálva:
select contributor_id, count(*) from imp_newusers_log_df where action in ('create', 'newusers') group by contributor_id, action having count(*)>1 
--> a create és a newuser altípusok esetében (néhány hibás, a mûveletvégzõt nem rögzítõ logelemen túl, amelyek nem használhatók) minden contributorhoz egyetlen sort tartozik, ezek az önregisztrációk
--> azt várjuk, hogy az automatikus fióklétrehozások is önregisztrációk
select contributor_id, count(*) from imp_newusers_log_df where action = 'autocreate' group by contributor_id, action having count(*)>1 
--> 6 automatikus fiókregisztrációra nem illik a mintázat 
select contributor_id, count(distinct timestamp) from imp_newusers_log_df where action = 'autocreate' group by contributor_id, action having count(*)>1 
--> 5  esetben loghibáról van szó, duplikált azonos tartalmú sorok, 1 eset külön vizsgálatot igényel:
select *  from imp_newusers_log_df where contributor_id= 450446
--> hibás logbejegyzés, azonos felhasználó két autocreate bejegyzése, a korábbi dátumot kezelhetjük valósként
select contributor_id, count(*) from imp_newusers_log_df where action not in ('create', 'autocreate', 'newusers') group by contributor_id having count(*)>1 
--> 163 eset egyéb naplótípusoknál
select contributor_id, action, count(*) from imp_newusers_log_df where action not in ('create', 'autocreate', 'newusers') group by contributor_id, action having count(*)>1 order by 2
--> a byemail és a create2 naplók esetében nem lehet számítani arra, hogy a contributor_id és a contributor_username a regisztált usert tartalmazza.
select count(*) from imp_newusers_log_df where action in ('byemail', 'create2')  
--> 315 sor
go
drop table if exists #usercreationlog
go
select distinct contributor_id, contributor_username, timestamp, action 
into #usercreationlog
from imp_newusers_log_df where action in ('create', 'newusers')  and contributor_id is not null 
union
select contributor_id, contributor_username, min(timestamp) as timestamp, action 
from imp_newusers_log_df where action in ('autocreate')  and contributor_id is not null group by contributor_id, contributor_username, action
go
drop table if exists #usercreationuniquelog
go
--Van e olyan user, akinek két külön logcsoportban is van sora?
select * from #usercreationlog where contributor_id in
(select contributor_id
from #usercreationlog
group by contributor_id
having count(*)>1)
order by 1
--> van, ezeknél a usereknél a korábbi idõpontot és actiont kell tárolni.
select distinct contributor_id, contributor_username, min(timestamp) over (partition by contributor_id) timestamp, 
first_value(action) over (partition by contributor_id order by timestamp) action
into #usercreationuniquelog
from #usercreationlog 
go
--> ebbõl az adathalmazból beszúrhatók a felhasználók
insert users (originalid, originaltype)
select contributor_id, 'user'
from #usercreationuniquelog 
go
--az aktuális név 
exec addattribute @name='username', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'username'), contributor_username, null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 
--a regisztráció idõpontja
exec addattribute @name='createdon', @datatypename='datetime', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'createdon'), cast(left(timestamp, 19)  as datetime), null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 
--és a fióklétrehozás módja.
exec addattribute @name='accounttype', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'accounttype'), action, null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 

/*A napló hiányosságai miatt elõfordulhat, hogy vannak még felhasználók egyéb naplókban és a szerkesztések között. Ezek szintén aktuális id és felhasználónév párosok*/
; 
with contributors as
(
select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp from imp_block_log_df 
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_create_log_df 
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_newusers_log_df
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_patrol_log_df
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_renameuser_log_df
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_rights_log_df
union select contributor_id, contributor_username, cast(left(timestamp, 19) as datetime) as timestamp  from imp_thanks_log_df
union select user_id, username,  cast(left(timestamp, 19) as datetime) as timestamp from imp_revisions_df
)
select contributor_id, contributor_username, min(timestamp) timestamp
into #contributions
from contributors  where isnull(contributor_id,0) <> 0 and not exists(select 1 from users where originalid=contributor_id)
group by contributor_id, contributor_username

--> ebbõl az adathalmazból beszúrhatók a felhasználók
insert users (originalid, originaltype) select contributor_id, 'user' from #contributions 
go
--az aktuális név 
exec addattribute @name='username', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto) select u.id, dbo.getattributeid('user', 'username'), contributor_username, null, null
from users u join #contributions l on u.originalid=l.contributor_id 
--a regisztráció idõpontja, ami ebben az esetben az elsõ aktivitás idõpontja lesz
exec addattribute @name='createdon', @datatypename='datetime', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto) select u.id, dbo.getattributeid('user', 'createdon'), timestamp, null, null
from users u join #contributions l on u.originalid=l.contributor_id 
--és a fióklétrehozás módja, ami ebben az esetben "contribution" lesz.
exec addattribute @name='accounttype', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'accounttype'), 'contribution', null, null
from users u join #contributions l on u.originalid=l.contributor_id 
go
drop table if exists #contributions
drop table if exists #usercreationlog
drop table if exists #usercreationuniquelog