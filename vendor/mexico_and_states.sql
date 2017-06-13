/*
 * $ cat file.sql | heroku pg:psql --app app_name
 * $ echo "select * from table;" | heroku pg:psql --app app_name
 * $ heroku pg:psql --app app_name < file.sql
 */
insert into countries (id, name) values('138', 'México');

/* states */
insert into states (id, country_id, name) values('2526','138','Aguascalientes');
insert into states (id, country_id, name) values('2527','138','Baja California');
insert into states (id, country_id, name) values('2528','138','Baja California Sur');
insert into states (id, country_id, name) values('2529','138','Campeche');
insert into states (id, country_id, name) values('2530','138','Chihuahua');
insert into states (id, country_id, name) values('2531','138','Chiapas');
insert into states (id, country_id, name) values('2532','138','Coahuila');
insert into states (id, country_id, name) values('2533','138','Colima');
insert into states (id, country_id, name) values('2534','138','Ciudad de México');
insert into states (id, country_id, name) values('2535','138','Durango');
insert into states (id, country_id, name) values('2536','138','Guerrero');
insert into states (id, country_id, name) values('2537','138','Guanajuato');
insert into states (id, country_id, name) values('2538','138','Hidalgo');
insert into states (id, country_id, name) values('2539','138','Jalisco');
insert into states (id, country_id, name) values('2540','138','Edo. México');
insert into states (id, country_id, name) values('2541','138','Michoacán');
insert into states (id, country_id, name) values('2542','138','Morelos');
insert into states (id, country_id, name) values('2543','138','Nayarit');
insert into states (id, country_id, name) values('2544','138','Nuevo León');
insert into states (id, country_id, name) values('2545','138','Oaxaca');
insert into states (id, country_id, name) values('2546','138','Puebla');
insert into states (id, country_id, name) values('2547','138','Querétaro');
insert into states (id, country_id, name) values('2548','138','Quintana Roo');
insert into states (id, country_id, name) values('2549','138','Sinaloa');
insert into states (id, country_id, name) values('2550','138','San Luis Potosí');
insert into states (id, country_id, name) values('2551','138','Sonora');
insert into states (id, country_id, name) values('2552','138','Tabasco');
insert into states (id, country_id, name) values('2553','138','Tamaulipas');
insert into states (id, country_id, name) values('2554','138','Tlaxcala');
insert into states (id, country_id, name) values('2555','138','Veracruz');
insert into states (id, country_id, name) values('2556','138','Yucatán');
insert into states (id, country_id, name) values('2557','138','Zacatecas');
