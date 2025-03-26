/*UserRelations1: Rights*/
/*A jogokat adminisztrátorok osztják ki a felhasználók számára, ez egy adminisztatív jellegû mûvelet, nem saját döntés alapján járnak el.
A jogosultságokat tároló napló a logtitle mezõben tárolja az érintett usert. A napló legkorábbi eleme 2005-ös, az elsõ néhány sor outlier, adminok kinevezése.
A további sorokban a params tömb tárolja az elvett és megadott jogosultságokat, kétféle formátumban: vagy egy sortöréssel határolt string, vagy egy php tömb ugyanezekkel az adatokkal.
Az elõfeldolgozó az elvett és megadott jogokat a col1+col2, oldgroups+newgroups oszlopokba bontja ki (kizáró). A duration oszlopot humán közremûködõ nem tölti (abusefilter).
- ha a col2 üres, akkor a col1 tartalmazza a megkapott jogot.
- Ha nem üres, akkor a col1-ben a régi jogosultságkészlet, a col2-ben az új jogosultságkészlet van.
*/
select  * from imp_rights_log_df --4799 sor.
--Igazolni szükséges, hogy a logtitle mezõ, hasonlóan a thanks loghoz, aktuális userneveket tárol. Ehhez a köszönetloghoz hasonlóan megvizsgáljuk, történt-e jogosultságkiosztás
--olyan felhasználónév számára, amely aktuálisan nem létezik
select * from userattributes ua1
where ua1.attributeid=7 and validto is not null and not exists(select 1 from userattributes ua2 where ua2.attributeid=7 and ua2.validto is null 
and ua1.cs_value=ua2.cs_value 
and convert(varbinary(max), ua1.value)=convert(varbinary(max), ua2.value))
and exists(select 1 from  imp_rights_log_df where concat('User:', ua1.value) = logtitle)
--> 7 sor az eredmény a közel 5000-bõl

--1. jogosultság attribútumba
if not exists (select 1 from attributes where name='role' and entitytype='user')
	insert attributes  (name, datatypeid, entitytype) 
	select 'role', (select id from datatypes where name='string'), 'user'


--2. jogosultságok attribútumértékekbe:
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
select * into #ua from userattributes where 1<>1  --azonos szerkezetû táblába gyûjtés
go
--emberünknek 32 sora 
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
  --Beszúrás
  select @userid, (select id from attributes where entitytype='user' and name = 'role'), #chunk.name, @timestamp
  from #chunk where direction='+' 
  --már van ilyen irányú nyitott role
  and not exists(select value from #ua ua2 where userid=@userid and validto is null and ua2.value=#chunk.name)
  --Eltávolítás
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
  /*az oldrightsnak meg kéne egyeznie azzal a szettel, ami az attribútumokból kibontható, de a logban lehetnek hibák.
  Ezért minden kört azzal kell befejezni, hogy a nyitott, de az újonnan kiosztott jogokban nem szereplõ jogosultságokat lezárjuk, és az újonnan kiosztottatkat beszúrjuk*/
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

