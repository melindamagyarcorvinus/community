if not exists (select * from userrelationtypes where name='block') insert userrelationtypes (name) values ('block')
if not exists (select * from userrelationtypes where name='unblock') insert userrelationtypes (name) values ('unblock')
go

select * from imp_block_log_df  -- 56366 sor

insert userrelations (fromuserid, touserid, validfrom, validto, userrelationtypeid)
select fu.id, tu.userid, timestamp, timestamp, ur.id
from userrelationtypes ur, 
imp_block_log_df join userattributes tu on tu.cs_value=checksum(substring(logtitle,6,1000 )) and  convert(varbinary(max), 'User:'+value)=convert(varbinary(max), logtitle)
and tu.attributeid=dbo.getattributeid('user', 'username')
join users fu on imp_block_log_df.contributor_id=fu.originalid
where validto is null  and action=ur.name


