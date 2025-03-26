insert contents(originalid, originaltype, createdon, parentcontentid, containerid, creatoruserid)
select  revision_id as originalid, 'Revision', timestamp as createdod, null as parentcontentid, c.id as containerid, u.id as creatoruserid
from imp_revisions_df  join users u on user_id=u.originalid
join containers c on c.originaltype='Page' and page_id=c.originalid  -->203278

/*PATROL*/
if not exists(select 1 from usercontentrelationtypes where name='patrol')
  insert usercontentrelationtypes (name) values ('patrol')

insert usercontentrelations (userid, contentid, validfrom, validto, usercontentrelationtypeid)
select creatoruserid, contents.id, timestamp, timestamp, (select id from usercontentrelationtypes where name='patrol')
from imp_patrol_log_df join contents on revision_id=originalid




