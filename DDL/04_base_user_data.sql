
/*
A felhaszn�l�k konvert�l�sa az ETL folyamat els� l�p�se.
A r�szfolyamat sor�n a feladat a felhaszn�l�k egyedi azonos�t�sra alkalmas ID-j�nak kinyer�se a c�l.
A Wikipedi�ban a userek azonos�t�sa userid alapj�n t�rt�nik. Az export�lt adatb�ziskivonatok minden m�velet eset�ben az aktu�lis felhaszn�l�nevet tartalmazz�k, 
Az �tnevez�s lehets�ges, ezt a m�veletet k�l�n napl� t�rolja. Egy felhaszn�l�nv egy adott id�pillanatban egyedi, de k�l�nb�z� id�pontokban k�t k�l�nb�z� user is 
rendelkezhet azonos n�vvel (ha nincs �tfed�s)

Az adatok forr�sa:
- A felhaszn�l�k l�trehoz�s�ra ir�nyul� log (imp_newusers_df)
- A szerkeszt�seket t�rol� �llom�ny (imp_revisions_df)
- Minden egy�b olyan log, amely felhaszn�l�n�v �s azonos�t� p�rokat tartalmaz.
Elm�letileg a felhaszn�l�k l�trehoz�s�ra ir�nyul� log elegend� lenne, de, k�l�n�sen a korai adatok eset�ben, nem minden felhaszn�l� l�trehoz�si rekordja tal�lhat� meg.
- A log szerkezete: 
id, timestamp, a regisztr�ci�t v�gz� user neve �s azonos�t�ja, comment, type, action (alt�pus), logtitle, params.
K�t tov�bbi sz�m�tott oszlopot helyez el az el�feldolgoz�s. Az els� a params oszlop �rt�k�nek els� sora (bizonyos logt�pusokn�l ezek inform�ci�t hordoznak), �s, amennyiben a 
params php szerializ�lt t�mb�t tartalmaz, akkor az abb�l kifejtett tulajdons�gok. Ez a k�t sz�m�tott oszlop ebben a folyamatban nem hordoz inform�ci�t.
*/
/*El�zetes vizsg�latok*/
select count(*) from imp_newusers_log_df --> A napl� 1 462 332 sort tartalmaz.
select action, count(*) darab, min(timestamp) elsohasznalat, max(timestamp) utolsohasznalat
from imp_newusers_log_df group by action  order by 2 desc 
--> 5 k�l�nf�le alt�pus, autocreate	(1313600), create (145301), newusers (1590), create2 (1526), byemail (315). 
--> a "newusers" nincs akt�v haszn�latban, utols� haszn�lata  2006.04.17, hely�be a "create" l�pett.
select min(timestamp) from imp_revisions_df
--> A a napl� legels� rekordja 2005 szeptember 9-�n k�sz�lt, mik�zben a legels� szerkeszt�s 2001-b�l sz�rmazik, �gy nem minden felhaszn�l�i fi�k l�trehoz�s�nak id�pontja ismeretes
--Egy usernapl�val szemben jogos felt�telez�s, hogy midnen l�trehoz�hoz egyetlen rekord fog t�rsulni (�nregisztr�ci�). Ebben az esetben a contributor_id �s contributor_name alkalmas
select contributor_id, count(*) from imp_newusers_log_df  group by contributor_id, action having count(*)>1 
--> a hipot�zis nem �ll meg, user alnapl�nk�nt vizsg�lva:
select contributor_id, count(*) from imp_newusers_log_df where action in ('create', 'newusers') group by contributor_id, action having count(*)>1 
--> a create �s a newuser alt�pusok eset�ben (n�h�ny hib�s, a m�veletv�gz�t nem r�gz�t� logelemen t�l, amelyek nem haszn�lhat�k) minden contributorhoz egyetlen sort tartozik, ezek az �nregisztr�ci�k
--> azt v�rjuk, hogy az automatikus fi�kl�trehoz�sok is �nregisztr�ci�k
select contributor_id, count(*) from imp_newusers_log_df where action = 'autocreate' group by contributor_id, action having count(*)>1 
--> 6 automatikus fi�kregisztr�ci�ra nem illik a mint�zat 
select contributor_id, count(distinct timestamp) from imp_newusers_log_df where action = 'autocreate' group by contributor_id, action having count(*)>1 
--> 5  esetben loghib�r�l van sz�, duplik�lt azonos tartalm� sorok, 1 eset k�l�n vizsg�latot ig�nyel:
select *  from imp_newusers_log_df where contributor_id= 450446
--> hib�s logbejegyz�s, azonos felhaszn�l� k�t autocreate bejegyz�se, a kor�bbi d�tumot kezelhetj�k val�sk�nt
select contributor_id, count(*) from imp_newusers_log_df where action not in ('create', 'autocreate', 'newusers') group by contributor_id having count(*)>1 
--> 163 eset egy�b napl�t�pusokn�l
select contributor_id, action, count(*) from imp_newusers_log_df where action not in ('create', 'autocreate', 'newusers') group by contributor_id, action having count(*)>1 order by 2
--> a byemail �s a create2 napl�k eset�ben nem lehet sz�m�tani arra, hogy a contributor_id �s a contributor_username a regiszt�lt usert tartalmazza.
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
--Van e olyan user, akinek k�t k�l�n logcsoportban is van sora?
select * from #usercreationlog where contributor_id in
(select contributor_id
from #usercreationlog
group by contributor_id
having count(*)>1)
order by 1
--> van, ezekn�l a userekn�l a kor�bbi id�pontot �s actiont kell t�rolni.
select distinct contributor_id, contributor_username, min(timestamp) over (partition by contributor_id) timestamp, 
first_value(action) over (partition by contributor_id order by timestamp) action
into #usercreationuniquelog
from #usercreationlog 
go
--> ebb�l az adathalmazb�l besz�rhat�k a felhaszn�l�k
insert users (originalid, originaltype)
select contributor_id, 'user'
from #usercreationuniquelog 
go
--az aktu�lis n�v 
exec addattribute @name='username', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'username'), contributor_username, null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 
--a regisztr�ci� id�pontja
exec addattribute @name='createdon', @datatypename='datetime', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'createdon'), cast(left(timestamp, 19)  as datetime), null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 
--�s a fi�kl�trehoz�s m�dja.
exec addattribute @name='accounttype', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'accounttype'), action, null, null
from users u join #usercreationuniquelog l on u.originalid=l.contributor_id 

/*A napl� hi�nyoss�gai miatt el�fordulhat, hogy vannak m�g felhaszn�l�k egy�b napl�kban �s a szerkeszt�sek k�z�tt. Ezek szint�n aktu�lis id �s felhaszn�l�n�v p�rosok*/
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

--> ebb�l az adathalmazb�l besz�rhat�k a felhaszn�l�k
insert users (originalid, originaltype) select contributor_id, 'user' from #contributions 
go
--az aktu�lis n�v 
exec addattribute @name='username', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto) select u.id, dbo.getattributeid('user', 'username'), contributor_username, null, null
from users u join #contributions l on u.originalid=l.contributor_id 
--a regisztr�ci� id�pontja, ami ebben az esetben az els� aktivit�s id�pontja lesz
exec addattribute @name='createdon', @datatypename='datetime', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto) select u.id, dbo.getattributeid('user', 'createdon'), timestamp, null, null
from users u join #contributions l on u.originalid=l.contributor_id 
--�s a fi�kl�trehoz�s m�dja, ami ebben az esetben "contribution" lesz.
exec addattribute @name='accounttype', @datatypename='string', @entitytype='user'
go
insert userattributes (userid, attributeid, value, validfrom, validto)
select u.id, dbo.getattributeid('user', 'accounttype'), 'contribution', null, null
from users u join #contributions l on u.originalid=l.contributor_id 
go
drop table if exists #contributions
drop table if exists #usercreationlog
drop table if exists #usercreationuniquelog