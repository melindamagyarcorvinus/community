create or alter procedure addattribute @name varchar(100), @datatypename varchar(100), @entitytype varchar(100)
as
begin
  declare @dtype int
  select @dtype=dbo.getdatatypeid(@datatypename)
  if @dtype=0 throw 51000, 'invalid datatype', 1;
  else if not exists(select 1 from attributes where name=@name and entitytype=@entitytype)
    insert attributes(name, datatypeid, entitytype) values (@name, @dtype, @entitytype)
end


