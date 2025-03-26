/*
use master
drop database community_final
create database community_final collate latin1_general_100_cs_as_sc_utf8;
use community_final
*/
drop table if exists contextrelationattribute
drop table if exists contextrelations
drop table if exists contextrelationtypes
drop table if exists usercontextrelationattribute
drop table if exists userrelationattribute
drop table if exists userattributes
drop table if exists contextattributes
drop table if exists contentattributes
drop table if exists userrelations
drop table if exists usercontextrelations
drop table if exists userrelationtypes
drop table if exists usercontextrelationtypes
drop table if exists usercontentrelationattribute
drop table if exists usercontentrelations
drop table if exists usercontentrelationtypes
drop table if exists contents
drop table if exists contexts
drop table if exists users
drop table if exists attributes
drop table if exists datatypes
go
/*Datatypes. Információ arról, hogy milyen típusú adatot hordoz a value*/
create table datatypes(id int not null identity primary key, name nvarchar(100) not null)
go
/*Attributes*/
create table attributes(id int not null identity primary key, name nvarchar(100), 
datatypeid int not null foreign key references datatypes(id),  
entitytype nvarchar(100),
constraint uq_entity_attributes unique (name, entitytype))
go
create table users(id int not null identity primary key, originalid nvarchar(100) not null, originaltype nvarchar(100) not null, 
constraint uq_users_original unique(originalid, originaltype)
)
go
create table userattributes(id int not null identity, userid int not null foreign key references users(id), 
attributeid int not null foreign key references attributes(id),
value nvarchar(max), 
validfrom datetime null, validto datetime null,
cs_value as checksum(value),
constraint pk_userattributes primary key(id),
)
go
create index idx_userattributes_cs_value ON userattributes (cs_value);  
go
create table userrelationtypes(id int not null identity primary key, name nvarchar(100) not null unique)
go
/*A Userrelations tábla az olyan kapcsolatok és interakciók tárolására szolgál, amelyek nem kötõdnek content jellegû üzenetváltásokhoz
A pontszerû események esetén validfrom=validto
*/
create table userrelations(id int not null identity primary key,
fromuserid int not null foreign key references users(id), 
touserid int not null foreign key references users(id), 
validfrom datetime not null, validto datetime null,
userrelationtypeid int not null foreign key references userrelationtypes(id),
constraint uq_userrelationck1 unique(fromuserid, touserid, userrelationtypeid, validto, validfrom)
)
go
create table userrelationattribute(userrelationid int not null foreign key references userrelations(id), attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_userrelationattribute primary key(userrelationid, attributeid, validfrom),
constraint uq_userelationattributes unique(userrelationid, attributeid, validfrom, validto)
)
go
create index idx_userrelationattribute_cs_value ON userrelationattribute(cs_value);  
go
create table contexts(id int not null identity primary key, originalid nvarchar(100) not null, originaltype nvarchar(100) not null, 
parentid int foreign key references contexts(id),
ownerid int foreign key references users(id),
createdon datetime null,
constraint uq_conainers_original unique(originalid, originaltype)
)

create table contextattributes(contextid int not null foreign key references contexts(id), attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_contextattributes primary key(contextid, attributeid, validfrom),
constraint uq_contextattributes unique(contextid, attributeid, validfrom, validto)
)
go
create index idx_contextattributes_cs_value ON contextattributes (cs_value);  
go

create table usercontextrelationtypes(id int not null identity primary key, name nvarchar(100) not null)
create table usercontextrelations(id int not null identity primary key, userid int not null foreign key references users(id),  
contextid int not null foreign key references contexts(id), validfrom date not null, validto date null, 
usercontextrelationtypeid int not null foreign key references usercontextrelationtypes(id))

create table usercontextrelationattribute(usercontextrelationid int not null foreign key references usercontextrelations(id), 
attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_usercontextrelationattribute primary key(usercontextrelationid, attributeid, validfrom),
constraint uq_usercontextrelationattributes unique(usercontextrelationid, attributeid, validfrom, validto)
)
go
create index idx_usercontextrelationattribute_cs_value ON usercontextrelationattribute(cs_value);  
go


create table contextrelationtypes(id int not null identity primary key, name nvarchar(100) not null)
create table contextrelations(id int not null identity primary key,
fromcontextid int not null foreign key references contexts(id), tocontextid int not null foreign key references contexts(id), 
validfrom datetime not null, validto datetime null,
contextrelationtypeid int not null foreign key references contextrelationtypes(id),
constraint uq_contextrelationck1 unique(fromcontextid, tocontextid, contextrelationtypeid, validto, validfrom)
)

create table contextrelationattribute(contextrelationid int not null foreign key references contextrelations(id), 
attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_contextrelationattribute primary key(contextrelationid, attributeid, validfrom),
constraint uq_contextrelationattributes unique(contextrelationid, attributeid, validfrom, validto)
)
go
create index idx_contextrelationattribute_cs_value ON contextrelationattribute (cs_value);  
go



create table contents(id int not null identity primary key, originalid nvarchar(100) not null, originaltype nvarchar(100) not null, createdon datetime null,
parentcontentid int null foreign key references contents(id),
contextid int not null foreign key references contexts(id),
creatoruserid int not null foreign key references users(id),
constraint uq_contents_original unique(originalid, originaltype)
)

create table contentattributes(contentid int not null foreign key references contents(id), attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_contentrattributes primary key(contentid, attributeid, validfrom),
constraint uq_contentrattributes unique(contentid, attributeid, validfrom, validto)
)
go
create index idx_contentattributes_cs_value ON contentattributes(cs_value);  
go

create table usercontentrelationtypes(id int not null identity primary key, name nvarchar(100) not null)

create table usercontentrelations(id int not null identity primary key, userid int not null foreign key references users(id),  
contentid int not null foreign key references contents(id), validfrom date not null, validto date null, 
usercontentrelationtypeid int not null foreign key references usercontentrelationtypes(id))

create table usercontentrelationattribute(usercontentrelationid int not null foreign key references usercontentrelations(id), 
attributeid int not null foreign key references attributes(id),
value nvarchar(max), validfrom date not null, validto date null, 
cs_value as checksum(value),
constraint pk_usercontentrelationattribute primary key(usercontentrelationid, attributeid, validfrom),
constraint uq_usercontentrelationattributes unique(usercontentrelationid, attributeid, validfrom, validto)
)
go
create index idx_usercontentrelationattribute_cs_value ON usercontentrelationattribute (cs_value);  

