create or alter function getattributeid(@entitytype varchar(100), @aname varchar(100))
returns int
as
begin
  declare @result int
  select @result =id from attributes where entitytype=@entitytype and lower(name)=lower(@aname)
  return @result
end
go
create or alter function getdatatypeid(@typename varchar(100))
returns int
as
begin
  declare @result int
  select @result =id from datatypes where name=@typename
  return isnull(@result, 0)
end
go
