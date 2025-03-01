# Khai báo provider cần thiết
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

# Cấu hình provider Docker
provider "docker" {
  host = "npipe:////./pipe/docker_engine"  # Kết nối đến Docker daemon trên Windows
  # Nếu dùng Linux, có thể dùng: host = "unix:///var/run/docker.sock"
}

# Pull image NGINX từ Docker Hub
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false  # Xóa image nếu không còn container nào sử dụng
}

# Pull image Apache từ Docker Hub
resource "docker_image" "apache" {
  name         = "httpd:latest"  # Sử dụng image Apache chính thức
  keep_locally = false  # Xóa image nếu không còn container nào sử dụng
}

# Tạo 4 container (2 NGINX và 2 Apache) với tên CON2_NHOM41_MAY_1-1 đến CON2_NHOM41_MAY_1-4
resource "docker_container" "web_containers" {
  count = 4
  name  = "CON2_NHOM3_MAY_1-${count.index + 1}"  # Tạo tên: CON2_NHOM41_MAY_1-1, CON2_NHOM41_MAY_1-2, ..., CON2_NHOM41_MAY_1-4
  
  # Sử dụng image khác nhau cho NGINX (index 0, 1) và Apache (index 2, 3)
  image = count.index < 2 ? docker_image.nginx.name : docker_image.apache.name
  
  # Cấu hình port mapping (ánh xạ port 80 trong container ra các port khác nhau trên host)
  ports {
    internal = 80
    external = 8000 + count.index  # Sử dụng port 8000, 8001, 8002, 8003
  }

  # Command để chạy webserver (NGINX hoặc Apache) trong foreground
  command = count.index < 2 ? ["nginx", "-g", "daemon off;"] : ["httpd-foreground"]
}

# Output thông tin các container
output "container_info" {
  value = [for i in range(4) : {
    name = docker_container.web_containers[i].name
    type = i < 2 ? "NGINX" : "Apache"
    ip   = docker_container.web_containers[i].network_data[0].ip_address
    port = docker_container.web_containers[i].ports[0].external
  }]
}