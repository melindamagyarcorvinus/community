select id into #undo  from userattributes --visszavonáshoz
delete from userattributes where id not in (select id from #undo)
update userattributes set validfrom=null, validto=null where attributeid=7 

 --konszolidált log idõponttal, régi és új usernévvel.
drop table if exists #renameuser_log 
;
with userrenames as
(
/*azok a sorok, ahol a commentbõl kell kinyerni átnevezés forrás és cél nevét*/
 select id as log_id, cast(left(timestamp, 19)  as datetime) timestamp
,    substring(comment, charindex('[[User:', comment) + 7, charindex('|', comment) - charindex('[[User:', comment) - 7) as olduser
, substring(
    comment, 
    charindex('[[User:', comment, charindex(']]', comment) + 2) + 7, 
    charindex('|', comment, charindex('[[User:', comment, charindex(']]', comment) + 2)) - (charindex('[[User:', comment, charindex(']]', comment) + 2) + 7)
) newuser
from  imp_renameuser_log_df where timestamp<'2012-12-24 10:26:01.0000000'
and comment like '%[[]User:%|%]]%'
union
--azok a sorok, ahol logtitle tartalmazza a régi usernevet, a params az újat
select id, cast(left(timestamp, 19)  as datetime) timestamp, substring(logtitle, 6, 1000) olduername, col1 as newusername  from imp_renameuser_log_df where params is not null and olduser is null
union
--azok a sorok ahol az olduser-newuser oszlopok tartalmaznak adatot, azaz php tömb volt a params oszlopban
select id, cast(left(timestamp, 19)  as datetime) timestamp, olduser, newuser from imp_renameuser_log_df where olduser is not null
)
select *
into #renameuser_log  --34 sor kivételével minden kifejthetõ az eredeti logból
from userrenames
go;
drop table if  exists #lastrenames;
with lastrenames as
(
select log_id, timestamp, newuser, first_value(olduser) over ( partition by newuser order by timestamp desc) olduser,
row_number() over ( partition by newuser order by timestamp desc) as rn
from #renameuser_log
)
select lastrenames.*, vwuseractualnames.*, ureg.date as regdate
into #lastrenames
from  lastrenames join vwuseractualnames on checksum(lastrenames.newuser)=vwuseractualnames.cs_value 
and convert(varbinary(max), lastrenames.newuser)=convert(varbinary(max), vwuseractualnames.value)
left join vwuserregdates ureg on vwuseractualnames.userid=ureg.id
where rn=1
and (ureg.date is null or ureg.date<=lastrenames.timestamp )
go
update userattributes set validfrom = rn.timestamp
from  #lastrenames rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid, olduser, timestamp 
from #lastrenames 
go
drop table if exists #worklog
create table  #worklog (log_id int, phase int)
go
insert #worklog select log_id, 1 from #lastrenames
go
drop table if exists #p2
with p2 as
(
select row_number() over ( partition by newuser order by timestamp desc) as rn, rn.*, ua.userid, ua.id as userattributeid, ua.attributeid
from #renameuser_log rn join userattributes ua  on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(rn.newuser)=ua.cs_value 
and convert(varbinary(max), rn.newuser)=convert(varbinary(max), ua.value)
left join vwuserregdates ureg on ua.userid=ureg.id
where log_id not in (select log_id from #worklog) 
and (ureg.date is null or ureg.date<=rn.timestamp )
and timestamp<ua.validto
)
select * into #p2 from p2 where rn=1
go
update userattributes set validfrom = rn.timestamp
from  #p2 rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid , olduser, timestamp 
from #p2 
go
insert #worklog select log_id, 2 from #p2
go
drop table if exists #p3
with p3 as
(
select row_number() over ( partition by newuser order by timestamp desc) as rn, rn.*, ua.userid, ua.id as userattributeid, ua.attributeid
from #renameuser_log rn join userattributes ua  on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(rn.newuser)=ua.cs_value 
and convert(varbinary(max), rn.newuser)=convert(varbinary(max), ua.value)
left join vwuserregdates ureg on ua.userid=ureg.id
where log_id not in (select log_id from #worklog) 
and (ureg.date is null or ureg.date<=rn.timestamp )
and timestamp<ua.validto
)
select * into #p3 from p3 where rn=1
go
update userattributes set validfrom = rn.timestamp
from  #p3 rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid , olduser, timestamp 
from #p3
go
insert #worklog select log_id, 3 from #p3
go
drop table if exists #p4
go
;with p4 as
(
select row_number() over ( partition by newuser order by timestamp desc) as rn, rn.*, ua.userid, ua.id as userattributeid, ua.attributeid
from #renameuser_log rn join userattributes ua  on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(rn.newuser)=ua.cs_value 
and convert(varbinary(max), rn.newuser)=convert(varbinary(max), ua.value)
left join vwuserregdates ureg on ua.userid=ureg.id
where log_id not in (select log_id from #worklog) 
and (ureg.date is null or ureg.date<=rn.timestamp )
and timestamp<ua.validto
)
select * into #p4 from p4 where rn=1
go
update userattributes set validfrom = rn.timestamp
from  #p4 rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid , olduser, timestamp 
from #p4 
go
insert #worklog select log_id, 4 from #p4
go
drop table if exists #p5
go
;with p5 as
(
select row_number() over ( partition by newuser order by timestamp desc) as rn, rn.*, ua.userid, ua.id as userattributeid, ua.attributeid
from #renameuser_log rn join userattributes ua  on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(rn.newuser)=ua.cs_value 
and convert(varbinary(max), rn.newuser)=convert(varbinary(max), ua.value)
left join vwuserregdates ureg on ua.userid=ureg.id
where log_id not in (select log_id from #worklog) 
and (ureg.date is null or ureg.date<=rn.timestamp )
and timestamp<ua.validto
)
select * into #p5 from p5 where rn=1
go
update userattributes set validfrom = rn.timestamp
from  #p5 rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid , olduser, timestamp 
from #p5 
go
insert #worklog select log_id, 5 from #p5
go
drop table if exists #p6
go
;with p6 as
(
select row_number() over ( partition by newuser order by timestamp desc) as rn, rn.*, ua.userid, ua.id as userattributeid, ua.attributeid
from #renameuser_log rn join userattributes ua  on ua. attributeid=dbo.getattributeid('user', 'username') 
and checksum(rn.newuser)=ua.cs_value 
and convert(varbinary(max), rn.newuser)=convert(varbinary(max), ua.value)
left join vwuserregdates ureg on ua.userid=ureg.id
where log_id not in (select log_id from #worklog) 
and (ureg.date is null or ureg.date<=rn.timestamp )
and timestamp<ua.validto
)
select * into #p6 from p6 where rn=1
go
update userattributes set validfrom = rn.timestamp
from  #p6 rn join userattributes ua on ua.id=rn.userattributeid
go
insert userattributes (userid, attributeid, value, validto)
select userid, attributeid , olduser, timestamp 
from #p6 
go
insert #worklog select log_id, 6 from #p6

