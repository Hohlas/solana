## Grafana setup

Добавьте ключ GPG для репозитория 
```bash
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

```
Добавьте стабильный репозиторий Grafana в список источников 
```bash
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
```
После обновления списка пакетов установите Grafana 
```bash
sudo apt-get update
sudo apt-get install grafana
```


