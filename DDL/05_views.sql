create view actualuserview
as
select u.id, originalid, ua.value as username 
from users u join userattributes ua  on u.id=ua.userid join attributes a on ua.attributeid=a.id and a.entitytype='user' and a.name='username'
where validto is null



