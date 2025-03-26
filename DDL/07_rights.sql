/*UserRelations1: Rights*/
/*A jogokat adminisztr�torok osztj�k ki a felhaszn�l�k sz�m�ra, ez egy adminisztat�v jelleg� m�velet, nem saj�t d�nt�s alapj�n j�rnak el.
A jogosults�gokat t�rol� napl� a logtitle mez�ben t�rolja az �rintett usert. A napl� legkor�bbi eleme 2005-�s, az els� n�h�ny sor outlier, adminok kinevez�se.
A tov�bbi sorokban a params t�mb t�rolja az elvett �s megadott jogosults�gokat, k�tf�le form�tumban: vagy egy sort�r�ssel hat�rolt string, vagy egy php t�mb ugyanezekkel az adatokkal.
Az el�feldolgoz� az elvett �s megadott jogokat a col1+col2, oldgroups+newgroups oszlopokba bontja ki (kiz�r�). A duration oszlopot hum�n k�zrem�k�d� nem t�lti (abusefilter).
- ha a col2 �res, akkor a col1 tartalmazza a megkapott jogot.
- Ha nem �res, akkor a col1-ben a r�gi jogosults�gk�szlet, a col2-ben az �j jogosults�gk�szlet van.
*/
select  * from imp_rights_log_df --4799 sor.
--Igazolni sz�ks�ges, hogy a logtitle mez�, hasonl�an a thanks loghoz, aktu�lis userneveket t�rol. Ehhez a k�sz�netloghoz hasonl�an megvizsg�ljuk, t�rt�nt-e jogosults�gkioszt�s
--olyan felhaszn�l�n�v sz�m�ra, amely aktu�lisan nem l�tezik
select * from userattributes ua1
where ua1.attributeid=7 and validto is not null and not exists(select 1 from userattributes ua2 where ua2.attributeid=7 and ua2.validto is null 
and ua1.cs_value=ua2.cs_value 
and convert(varbinary(max), ua1.value)=convert(varbinary(max), ua2.value))
and exists(select 1 from  imp_rights_log_df where concat('User:', ua1.value) = logtitle)
--> 7 sor az eredm�ny a k�zel 5000-b�l

--1. jogosults�g attrib�tumba
if not exists (select 1 from attributes where name='role' and entitytype='user')
	insert attributes  (name, datatypeid, entitytype) 
	select 'role', (select id from datatypes where name='string'), 'user'


--2. jogosults�gok attrib�tum�rt�kekbe:
drop table if exists #rightchanges1
go
select  imp_rights_log_df.id, timestamp,  userattributes.userid,
isnull(oldgroups, isnull(col1, '')) as oldstring, isnull(newgroups, isnull(col2, '')) as newstring
into #rightchanges1
from imp_rights_log_df join userattributes on convert(varbinary(max), 'User:'+value)=convert(varbinary(max), logtitle) and userattributes.attributeid=dbo.getattributeid('user', 'username')
where validto is null
go
drop table if exists #ua
go
select * into #ua from userattributes where 1<>1  --azonos szerkezet� t�bl�ba gy�jt�s
go
--ember�nknek 32 sora 
declare RCCursor Cursor  for select * from #rightchanges1 /*where userid= 14601320  and id < 74073*/ order by timestamp  
Open RCCursor
declare @aid int, @s varchar(100), @logid int, @timestamp datetime2, @userid int, @oldrights varchar(100), @newrights varchar(100)
Fetch next from RCCursor into  @logid, @timestamp, @userid, @oldrights, @newrights
truncate table #ua
While @@fetch_status=0 
begin
  drop table if exists #chunk
  select * into #chunk from dbo.getrightschanged(@oldrights, @newrights)
  insert #ua (userid, attributeid, value, validfrom)
  --Besz�r�s
  select @userid, (select id from attributes where entitytype='user' and name = 'role'), #chunk.name, @timestamp
  from #chunk where direction='+' 
  --m�r van ilyen ir�ny� nyitott role
  and not exists(select value from #ua ua2 where userid=@userid and validto is null and ua2.value=#chunk.name)
  --Elt�vol�t�s
  declare removerolecursor cursor for select name from #chunk where direction='-'
  open removerolecursor
  fetch next from removerolecursor into @s
  while @@fetch_status=0
  begin
    update #ua set validto=@timestamp where id=
    (select max(id) from #ua ua2 where ua2.validfrom<=@timestamp and ua2.userid=@userid and ua2.value=@s)
	fetch next from removerolecursor into @s
   end
   close removerolecursor
   deallocate removerolecursor
  /*az oldrightsnak meg k�ne egyeznie azzal a szettel, ami az attrib�tumokb�l kibonthat�, de a logban lehetnek hib�k.
  Ez�rt minden k�rt azzal kell befejezni, hogy a nyitott, de az �jonnan kiosztott jogokban nem szerepl� jogosults�gokat lez�rjuk, �s az �jonnan kiosztottatkat besz�rjuk*/
  update  #ua set validto=@timestamp where validto is null and validfrom <=@timestamp and userid=@userid and value not in (select trim(value) from string_split(@oldrights, ',')) and value not in (select name from #chunk where direction='+')  --(select name from #chunk where direction='+')
  
  insert  #ua (userid, attributeid, value, validfrom)
  select @userid, dbo.getattributeid('user', 'role'), trim(x.value), @timestamp 
  from string_split(@newrights, ',') x
  where not exists(select 1 from #ua  ua where ua.userid=@userid and ua.value = trim(x.value) and validto is null and attributeid=dbo.getattributeid('user', 'role'))
  and trim(x.value)<>''

  Fetch next from RCCursor into  @logid, @timestamp, @userid, @oldrights, @newrights
end
Close RCCursor
deallocate RCCursor
go

