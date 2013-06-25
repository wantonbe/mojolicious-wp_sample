CREATE TABLE service_requests (
  request_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id INT UNSIGNED NOT NULL,
  engineer_id INT UNSIGNED NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  request_summary VARCHAR(255) NOT NULL,
  status ENUM('Open', 'Waiting Customer', 'In Progress', 'Closed') NOT NULL,
  service_request_datetime TIMESTAMP NOT NULL,
PRIMARY KEY (request_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
