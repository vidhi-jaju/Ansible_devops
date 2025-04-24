# AnsibleDemo
Ansible demo with docker container as servers

# The Need for Ansible in Server Management

Ansible is a powerful automation tool that addresses several critical challenges in server management:

1. **Scalability**: Managing multiple servers manually becomes impractical as infrastructure grows.
2. **Consistency**: Ensures identical configurations across all servers, reducing "works on my machine" issues.
3. **Efficiency**: Automates repetitive tasks, saving time and reducing human error.
4. **Idempotency**: Operations can be run multiple times without causing unintended changes.
5. **Infrastructure as Code**: Configuration is version-controlled and documented.

---

# Simplified Ansible with Docker Exercise

## Step 1: Create SSH Key Pair
```bash
mkdir -p .ssh
ssh-keygen -t rsa -b 4096 -f ./.ssh/ansible_key -N ""
chmod 600 ./.ssh/ansible_key
```
![img1](img/Screenshot%202025-04-24%20112114.png)


## Step 2: Create Dockerfile
```dockerfile
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y openssh-server python3 && \
    mkdir /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

```

## Step 3: Build and Run Containers
```bash
# Build image
docker build -t ubuntu-server .

# Create 4 containers
for i in {1..4}; do
  docker run -d --name server${i} \
    -v $(pwd)/.ssh/ansible_key.pub:/root/.ssh/authorized_keys \
    ubuntu-server
done
```
![img2](img/Screenshot%202025-04-24%20113142.png)

![img3](img/Screenshot%202025-04-24%20113153.png)
## Step 4: Create Ansible Inventory
```bash
echo "[servers]" > inventory.ini
for i in {1..4}; do
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' server${i} >> inventory.ini
done

cat << EOF >> inventory.ini

[servers:vars]
ansible_user=root
ansible_ssh_private_key_file=./.ssh/ansible_key
ansible_python_interpreter=/usr/bin/python3
EOF

```

## Step 5: Test Connectivity
```bash

# Ansible ping test
ansible all -i inventory.ini -m ping 
```

## Step 6: Create Playbook (update.yml)
```yaml
---
---
- name: Update and configure servers
  hosts: all
  become: yes

  tasks:
    - name: Update apt packages
      apt:
        update_cache: yes
        upgrade: dist

    - name: Install required packages
      apt:
        name: ["vim", "htop", "wget"]
        state: present

    - name: Create test file
      copy:
        dest: /root/ansible_test.txt
        content: "Configured by Ansible on {{ inventory_hostname }}"

```

## Step 7: Run Playbook
```bash
 ansible-playbook -i inventory.ini update.yml
```

## Step 8: Verify Changes
```bash

# Manually via Docker
 for i in {1..4}; do
  docker exec server${i} cat /root/ansible_test.txt
done
```

## Cleanup
```bash
# Stop and remove containers
for i in {1..4}; do
  docker rm -f server${i}
done
```
![img4](img/Screenshot%202025-04-24%20114106.png)

6. Removed unnecessary port mapping since we're using container IPs
7. Fixed SSH key permissions
8. Added proper cleanup command

The workflow is now:
1. Setup SSH keys → 2. Build image → 3. Launch containers → 4. Create inventory → 5. Test → 6. Run playbook → 7. Verify → 8. Cleanup

