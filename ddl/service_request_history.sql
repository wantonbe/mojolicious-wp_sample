CREATE TABLE service_request_history (
  service_request_id INT UNSIGNED NOT NULL,
  update_datetime TIMESTAMP NOT NULL,
  new_status ENUM('Open', 'Waiting Customer', 'In Progress', 'Closed') NOT NULL,
PRIMARY KEY (service_request_id, new_status, update_datetime),
INDEX(update_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
