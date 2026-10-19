-- Import into your hosted MySQL database (create the empty database first, then run this).
-- Running it again resets all data.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS reservations, menu_items, categories, users, admins;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  phone VARCHAR(15) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  token_version INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0
);
CREATE TABLE menu_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) DEFAULT '',
  price DECIMAL(8,2) NOT NULL,
  is_veg TINYINT(1) NOT NULL DEFAULT 1,
  available TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);
CREATE TABLE reservations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(80) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  res_date DATE NOT NULL,
  res_time TIME NOT NULL,
  guests INT NOT NULL,
  status ENUM('pending','confirmed','cancelled') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  token_version INT NOT NULL DEFAULT 0
);

-- admin login: admin / admin123 (change it after deploying)
INSERT INTO admins (username, password_hash) VALUES ('admin', '$2b$12$vQv0yrPTfF5DumZlhzYOmeoIkQkEK8e7gmCUEToqNo93OKDbRgTqi');
INSERT INTO categories (name, sort_order) VALUES ('Starters',1),('Mains',2),('Breads and rice',3),('Sweets and drinks',4);
INSERT INTO menu_items (category_id,name,description,price,is_veg) VALUES
(1,'Paneer tikka','Cottage cheese, hung-curd marinade, charred peppers.',320,1),
(1,'Seekh kebab','Minced lamb, green chilli, mint chutney.',380,0),
(1,'Hara bhara kebab','Spinach and peas, crisp outside, soft inside.',260,1),
(1,'Tandoori chicken','Half bird, 24-hour marinade, lemon.',420,0),
(2,'Butter chicken','Tandoor chicken in a tomato and butter gravy.',440,0),
(2,'Dal angeethi','Black lentils simmered overnight on coal.',300,1),
(2,'Lamb rogan josh','Slow-cooked with Kashmiri chilli and fennel.',520,0),
(2,'Palak paneer','Fresh spinach, paneer, a little cream.',340,1),
(3,'Butter naan','Baked on the tandoor wall.',70,1),
(3,'Missi roti','Gram flour and whole wheat.',60,1),
(3,'Chicken dum biryani','Sealed and steamed with saffron.',420,0),
(3,'Jeera rice','Basmati tempered with cumin.',180,1),
(4,'Gajar halwa','Carrot, khoya, cardamom, served warm.',180,1),
(4,'Kulfi falooda','House kulfi, rose syrup, vermicelli.',200,1),
(4,'Sweet lassi','Thick curd, sugar, a pinch of cardamom.',120,1),
(4,'Masala chai','Ginger, tea leaves, milk.',70,1);
