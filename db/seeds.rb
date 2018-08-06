# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#   rake db:seed RAILS_ENV=production --trace

warehouses = Warehouse.all
if !warehouses.any?
  Warehouse.create(name: "Almacén Guadalajara", address: "Some address",
                   telephone: "xx xx xx xx", city_id: 19597, hash_id: "A0001",
                   shipping_cost: 250, wholesale: 1999)
end

if SiteWorker.where(is_admin: true).take.blank?
  SiteWorker.create(city_id: 19597, warehouse_id: 1, hash_id: "T0001",
                   name: "Admin", lastname: "foo", mother_lastname: "bar",
                   password: "foobar", password_confirmation: "foobar",
                   email: "admin@example.com", rfc: "LA872ASD7783A",
                   nss: "11298478923", address: "foobar", telephone: "33 33 33 33",
                   is_admin: true, username: "admin", cellphone: "33 33 33 33 33")
end

info_names = [
  "PRIVACY_POLICY",
  "TERMS_OF_SERVICE",
  "ECART_NOTICE",
  "WELCOME_MESSAGE",
  "HIGH_QUALITY",
  "DISCOUNTS",
  "EASY_SHOPPING",
  "DISTRIBUTORS"]

info_names.each do |info_name|
  if WebInfo.where(name: info_name).take.blank?
    WebInfo.create(name: info_name, description_render_path:"/shared/web/init_file.html.erb")
  end
end

# methods used to populate clients and products FOR TESTING ONLY #
def generateAlphKey(letter, number)
  if number <= 9
    new_key = "000"+(number).to_s
  elsif number >= 10 and number < 100
    new_key = "00"+(number).to_s
  elsif number >= 100 and number < 1000
    new_key = "0"+(number).to_s
  else
    new_key = (number).to_s
  end

  return letter + new_key
end

def sample_names
  # 0..36
  ['Silvia','Sara','Raquel','Paula','Marta','María','Lucía','Laura','Eva',
  'Elena','Sergio','Pablo','José','Jorge','Javier','Diego','David',
  'Carlos','Alejandro','Pánfilo','Paloma','Pascual','Patricia','Paulino',
  'Paz','Penélope','Perla','Pilar','Daniel','Piedad','Prudencia',
  'Erick','Jonatan','Petra','Omar','Priscila','Andy']
end

def sample_last_names
  ['SMITH','JOHNSON','WILLIAMS','JONES','BROWN','DAVIS','MILLER',
  'MOORE','TAYLOR','ANDERSON','THOMAS','JACKSON','WHITE','HARRIS',
  'THOMPSON','GARCIA','MARTINEZ','ROBINSON','CLARK','RODRIGUEZ','LEWIS',
  'WALKER','HALL','ALLEN','YOUNG','HERNANDEZ','KING','WRIGHT','LOPEZ',
  'SCOTT','GREEN','ADAMS','BAKER','GONZALEZ','NELSON','CARTER','LEE',
  'PEREZ','ROBERTS','TURNER','PHILLIPS','CAMPBELL','PARKER',
  'EVANS','EDWARDS','COLLINS','HILL','MITCHELL','WILSON','MARTIN']
end

def sample_street_names
  ['Abelardo Rodriguez','Abel Salazar','Abraham Gonzalez','Abrantes',
  'Abundancia','Abundio Martinez','Acantilado','Acatempan','Acatic',
  'Aceituna','15 De Septiembre','18 De Agosto','18 De Marzo',
  'B. Godoy','B. Gutierrez','Bilbao','Bis 2','Bismark','Bizet',
  'Blas Alcarce','Blas Galindo','Bocana','Bogota','Bolitario','Bolivia',
  'Boliviano','Caballete','Caballo Arete','Cabañas','Cabildo','Cabo',
  'Cacao','Caceres','Cadiz','Café','Cairo','Calabaza','Gabriel Ruiz',
  'Daniel Rodriguez','Dario Rubio','Dátil','David Alberto Cosio',
  'David Alfaro Siqueiros','David Esparza','David G. Bernaga',
  'Edmundo Gamez Orozco','Eduardo Correa','Eduardo Del Valle',
  'Eduardo Reynoso','Eduardo Ruiz','Eduardo Zapeda','Fabian Carrillo',
  'Facundo','Faisán','Faja De Oro','Faraones','Faro','Fauna','Comercio',
  'Comercio Exterior','Cometa','Comonfort','Compositores','Compostela',
  'Compresor','Gabaon','Gabino Barreda','Gabino Duran','Gabriela Mistral',
  'Gabriel Castaños','Gabriel Ferrer','Gabriel Ramos Millan',
  'Cabotto','Daniel Larios Cardenas']
end

def sample_colony_names
  ['18 de Marzo','1 de Mayo','2001','5 de Mayo','5 de Mayo 2a Secc',
  '8 de Julio','Alcalde Barranquitas','Aldama Tetlán','Aldrete',
  'Altavista de Guadalajara','Americana','Ampliación Provincia',
  'Ampliación Talpita','Analco','Antigua Penal de Oblatos',
  'Balcones de Huentitán','Balcones Del 4','Balcones de La Joya',
  'Balcones de Oblatos','Barajas Villaseñor San Pablo','Barragán y Hernández',
  'Barrera','Barrio Mezquitan','Batallón de San Patricio','Capilla de Jesús',
  'Casa Hogar CTM','Chapalita','Chapultepec Country','Circunvalación Américas',
  'Circunvalación Belisario','Circunvalación Guevara',
  'Circunvalación Metro Carballo','Circunvalación Oblatos',
  'Circunvalación Sarcófago','Deitz','Del Fresno 1a. Sección',
  'Del Fresno 2a. sección','Del Sur','Del Sur','Del Trabajo CTM',
  'Dioses Del Nilo','División del Norte','Dólar','Echeverría 1a. Sección',
  'Echeverría 2a. Sección','Echeverría 3a. Sección','El Barro','El Carmen',
  'El Dean','Electricistas','El Jaguey','El Manantial','El Mirador',
  'El Mirador Álamo','El Periodista','El Porvenir Oriente',
  'El Porvenir Unidad Hogar','Fabrica de Atemajac','Ferrocarril',
  'Fidel Velázquez','Florencia','FOVISSSTE Independencia','Francisco Villa',
  'Fray Antonio Alcalde','González Gallo','Gral. Real','Guadalajara Centro',
  'Guadalajara Oriente','Guadalupana Norte','Guadalupana Sur']
end

def sample_coffe_names
  ['Corto','Expreso doble','Solo largo','Carajillo','Americano',
  'Café árabe','Caffè Macchiatto','Café Crème','Café Vienés',
  'Café asiático','Capuchino','Café moca','Café Irlandés','Lágrima',
  'Café Hawaiano','Caffè breve','Azteca','Escocés','Expreso',
  'Instantáneo','Café caribeño','Café jamaicano',
  'Café brule','Café bombón','Café Turco','Café caramel macchiato']
end

# Generate arbitraty clients in the database for testing purposes
sample_names.each do |name|
  email = name+'@client.com'

  client = Client.new({
      birthday: '1999-06-12', name: name, city_id: 19597,
      username: name,
      email: email, email_confirmation: email,
      password: 'foobar', password_confirmation: 'foobar',
      lastname: sample_last_names.shuffle[0],
      mother_lastname: sample_last_names.shuffle[0],
      telephone: '33-80-25-63',
      cellphone: '33-14-52-12-56',
      street: sample_street_names.shuffle[0],
      col: sample_colony_names.shuffle[0],
      extnumber: (0..9).to_a.shuffle[0..3].join.to_s,
      cp: (0..9).to_a.shuffle[0..3].join.to_s,
      street_ref1: sample_street_names.shuffle[0],
      street_ref2: sample_street_names.shuffle[0]
    })

  if client.save
    client.update_attribute(:hash_id, generateAlphKey("C", client.id))
  else
    puts "--- error ---"
    client.errors.each do |field, msg|
      puts "--- #{field}: #{msg} ---"
    end
  end
end

sample_coffe_names.each do |coffe_name|
  product = Product.new({
      name: coffe_name, show: true, iva: '16', ieps: '8',
      price: '350.00', recommended_price: '280.000', lowest_price: '250.00',
      presentation: 'Bolsa de 500grs.', hot: true, cold: true
    })

  if product.save
    product.update_attribute(:hash_id, generateAlphKey("P", product.id))

    render_file_path = "/shared/products/" + "product_" + product.hash_id + "_description.html.erb"
        file_path = "app/views" + render_file_path.sub("/shared/products/", "/shared/products/" + "_")

        file = File.open(file_path, "w")
        file.puts('Lorem ipsum dolor sit amet, consectetur adipiscing elit. In id gravida libero. Donec imperdiet dui vitae turpis egestas tristique. Maecenas varius, ex quis ultrices rutrum, diam lacus ornare magna, nec molestie mauris nibh vel orci. In convallis nulla nisl, vel aliquam dolor fermentum et. In euismod, velit ut laoreet sodales, ipsum purus ultrices enim, a luctus nulla neque sit amet purus. Curabitur posuere vulputate interdum. Donec lacinia et ligula vitae auctor. Nunc ultrices placerat quam quis auctor. Sed quis dui non felis consectetur dictum ut ut massa. Vivamus velit ipsum, porta at quam eget, fermentum porttitor purus. Duis nec egestas leo, nec sodales lacus. Fusce vulputate mi tempus nisi congue tincidunt. Integer lacus nibh, fermentum porttitor lobortis ut, venenatis in erat. Donec metus dolor, tempus in dolor vitae, mattis interdum lacus. Pellentesque eu finibus felis. Etiam id odio leo.')
        file.flush

        product.update_attributes(:description_render_path => render_file_path)

    render_file_path = "/shared/products/" + "product_" + product.hash_id + "_preparation.html.erb"
        file_path = "app/views" + render_file_path.sub("/shared/products/", "/shared/products/" + "_")

        file = File.open(file_path, "w")
        file.puts('Lorem ipsum dolor sit amet, consectetur adipiscing elit. In id gravida libero. Donec imperdiet dui vitae turpis egestas tristique. Maecenas varius, ex quis ultrices rutrum, diam lacus ornare magna, nec molestie mauris nibh vel orci. In convallis nulla nisl, vel aliquam dolor fermentum et. In euismod, velit ut laoreet sodales, ipsum purus ultrices enim, a luctus nulla neque sit amet purus. Curabitur posuere vulputate interdum. Donec lacinia et ligula vitae auctor. Nunc ultrices placerat quam quis auctor. Sed quis dui non felis consectetur dictum ut ut massa. Vivamus velit ipsum, porta at quam eget, fermentum porttitor purus. Duis nec egestas leo, nec sodales lacus. Fusce vulputate mi tempus nisi congue tincidunt. Integer lacus nibh, fermentum porttitor lobortis ut, venenatis in erat. Donec metus dolor, tempus in dolor vitae, mattis interdum lacus. Pellentesque eu finibus felis. Etiam id odio leo.')
        file.flush

        product.update_attributes(:preparation_render_path => render_file_path)
  else
    puts "--- cant save product, error(s): ---"
    product.errors.each do |field, msg|
      puts "--- #{field}: #{msg} ---"
    end
  end
end

Product.all.each do |product|
  Warehouse.all.each do |w|
    WarehouseProduct.create(warehouse_id: w.id, describes_total_stock: true,
            product_id: product.id, existence: 0, min_stock: 50)
  end
end
